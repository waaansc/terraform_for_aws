resource "aws_vpc" "main"{
 cidr_block = "10.0.0.0/16"
 
 tags = {
  Name = "terraform-inflearn"
 }
}

resource "aws_subnet" "public_subnet"{
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.0.0/24"
 
 availability_zone = "ap-northeast-2a"
  tags = {
  Name = "terraform-inflearn-public-subnet"
 }
}

resource "aws_subnet" "private_subnet"{
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.10.0/24"

  tags = {
  Name = "terraform-inflearn-private-subnet"
 }
}

resource "aws_internet_gateway" "igw"{

 vpc_id = aws_vpc.main.id

 tags = {
   Name = "terraform-inflearn-igw"
 }

}

resource "aws_eip" "nat"{

  lifecycle{
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway"{
  allocation_id = aws_eip.nat.id

  # Private subnet이 아닌 public subnet 연결해야함
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "terraform-NATGW"
  }
}

resource "aws_route_table" "public"{
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {
    Name = "terraform-rt-public"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private"{
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-rt-private"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private_nat" {
  route_table_id              = aws_route_table.private.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}

# aws_vpc_endpoint 리소스 정의 (S3 서비스에 대한 게이트웨이 엔드포인트)
resource "aws_vpc_endpoint" "s3_endpoint" {
  # (1) 엔드포인트를 연결할 VPC ID 지정
  vpc_id       = aws_vpc.main.id

  # (2) 게이트웨이 엔드포인트 유형 지정 (S3/DynamoDB에 사용)
  service_name = "com.amazonaws.ap-northeast-2.s3"

  # (3) 유형: "Gateway" 또는 "Interface"
  vpc_endpoint_type = "Gateway"

  # (4) S3에 접근할 수 있는 라우팅 테이블 ID 지정 (여기서 라우팅 테이블에 연결됨)
  # Public과 Private 서브넷 모두 S3에 접근해야 하므로 두 라우팅 테이블 모두 지정합니다.
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  tags = {
    Name = "terraform-s3-endpoint"
  }
}
