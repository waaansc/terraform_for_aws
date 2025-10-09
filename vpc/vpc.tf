# 리소스: aws_vpc (가상 사설 클라우드)
resource "aws_vpc" "main"{
  # VPC 전체의 IP 주소 범위. /16은 65,536개의 IP 주소를 포함합니다.
  cidr_block = "10.0.0.0/16" 
  
  tags = {
    Name = "terraform-inflearn" # VPC 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_subnet (퍼블릭 서브넷)
resource "aws_subnet" "public_subnet"{
  # 서브넷이 속할 VPC 지정 (main VPC)
  vpc_id = aws_vpc.main.id
  # 서브넷의 IP 주소 범위. /24는 256개의 IP 주소를 포함합니다.
  cidr_block = "10.0.0.0/24" 
  
  # 서브넷이 위치할 가용 영역(AZ) 지정 (서울 리전의 첫 번째 AZ)
  availability_zone = "ap-northeast-2a" 
   tags = {
   Name = "terraform-inflearn-public-subnet" # 퍼블릭 서브넷 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_subnet (프라이빗 서브넷)
resource "aws_subnet" "private_subnet"{
  # 서브넷이 속할 VPC 지정 (main VPC)
  vpc_id = aws_vpc.main.id
  # 서브넷의 IP 주소 범위. 퍼블릭 서브넷과 겹치지 않도록 설정
  cidr_block = "10.0.10.0/24"

   tags = {
   Name = "terraform-inflearn-private-subnet" # 프라이빗 서브넷 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_internet_gateway (인터넷 게이트웨이)
resource "aws_internet_gateway" "igw"{
  # IGW를 VPC에 연결
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-inflearn-igw" # IGW 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_eip (Elastic IP - 고정 공인 IP)
# NAT 게이트웨이는 고정 IP가 필요하므로 EIP를 먼저 생성합니다.
resource "aws_eip" "nat"{
  # EIP가 NAT 게이트웨이보다 먼저 생성되도록 명시적으로 지정
  lifecycle{
    create_before_destroy = true
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_nat_gateway (NAT 게이트웨이)
resource "aws_nat_gateway" "nat_gateway"{
  # 생성된 EIP를 NAT 게이트웨이에 연결
  allocation_id = aws_eip.nat.id

  # NAT GW는 외부와 통신해야 하므로 **반드시 퍼블릭 서브넷**에 배치해야 합니다.
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "terraform-NATGW" # NAT 게이트웨이 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_route_table (퍼블릭 라우팅 테이블)
resource "aws_route_table" "public"{
  vpc_id = aws_vpc.main.id

  # 라우트 규칙: 모든 외부 트래픽(0.0.0.0/0)을 IGW로 보냄
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {
    Name = "terraform-rt-public" # 퍼블릭 라우팅 테이블 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_route_table_association (퍼블릭 서브넷 연결)
resource "aws_route_table_association" "route_table_association_public" {
  # 퍼블릭 서브넷에 퍼블릭 라우팅 테이블을 연결
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}
#--------------------------------------------------------------------------------
# 리소스: aws_route_table (프라이빗 라우팅 테이블)
resource "aws_route_table" "private"{
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-rt-private" # 프라이빗 라우팅 테이블 이름 태그
  }
}
#--------------------------------------------------------------------------------
# 리소스: aws_route_table_association (프라이빗 서브넷 연결)
resource "aws_route_table_association" "route_table_association_private" {
  # 프라이빗 서브넷에 프라이빗 라우팅 테이블을 연결
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}
#--------------------------------------------------------------------------------
# 리소스: aws_route (프라이빗 라우팅 테이블에 NAT 경로 추가)
resource "aws_route" "private_nat" {
  # 경로를 추가할 라우팅 테이블 지정 (프라이빗 RT)
  route_table_id              = aws_route_table.private.id
  # 모든 외부 트래픽(0.0.0.0/0)에 대해
  destination_cidr_block      = "0.0.0.0/0"
  # NAT 게이트웨이를 다음 홉(Next Hop)으로 지정
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}
#--------------------------------------------------------------------------------
# 리소스: aws_vpc_endpoint (S3 게이트웨이 엔드포인트)
resource "aws_vpc_endpoint" "s3_endpoint" {
  # (1) 엔드포인트를 연결할 VPC ID 지정
  vpc_id       = aws_vpc.main.id

  # (2) 접속할 AWS 서비스 지정 (S3 서비스의 ARN 프리픽스)
  service_name = "com.amazonaws.ap-northeast-2.s3"

  # (3) 엔드포인트의 유형을 Gateway로 지정 (S3의 경우 이 타입이 데이터 요금이 무료)
  vpc_endpoint_type = "Gateway"

  # (4) S3 접근 경로를 추가할 라우팅 테이블 지정. 
  # 이 지정으로 인해 S3로 가는 트래픽은 NAT GW나 IGW를 우회하고 내부망을 사용하게 됩니다.
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  tags = {
    Name = "terraform-s3-endpoint" # VPC 엔드포인트 이름 태그
  }
}
