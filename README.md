# 🚀 Terraform을 이용한 AWS VPC 네트워크 환경 구축

## 🎯 프로젝트 개요

이 프로젝트는 Infrastructure as Code(IaC) 도구인 **Terraform**을 사용하여 AWS 클라우드에 안정적이고 안전한 **VPC(Virtual Private Cloud)** 네트워크 환경을 자동으로 구축하는 것을 목표로 합니다.

**구축된 주요 리소스:**

* **VPC:** 기본 네트워크 격리 환경
* **Public Subnet:** 인터넷 게이트웨이(IGW)를 통해 외부 인터넷에 직접 접근 가능한 서브넷
* **Private Subnet:** 외부 인터넷 접근이 차단된 보안 서브넷
* **NAT Gateway & EIP (탄력적 IP):** Private Subnet의 리소스가 안전하게 외부 인터넷으로 나갈 수 있도록 하는 통로 제공
* **S3 VPC Endpoint (Gateway Type):** Private Subnet의 리소스가 인터넷을 거치지 않고 AWS 내부망을 통해 S3 서비스에 안전하게 접근하도록 구성하여 보안 및 비용 효율성 확보

***

## 🏗️ 네트워크 아키텍처 (VPC 구성 요약)

| **리소스** | **역할** | **특징** |
| :--- | :--- | :--- |
| **VPC (`aws_vpc`)** | 기본 네트워크 | CIDR: `10.0.0.0/16` |
| **인터넷 게이트웨이 (`aws_igw`)** | VPC와 인터넷 연결 | Public Subnet의 아웃바운드 허용 |
| **Public Subnet** | 외부 연결 서브넷 | CIDR: `10.0.0.0/24` |
| **Private Subnet** | 격리된 서브넷 | CIDR: `10.0.10.0/24` |
| **NAT Gateway** | Private Subnet의 아웃바운드 역할 | Public Subnet에 위치하며 EIP 사용 |
| **S3 Endpoint** | AWS 서비스 내부 연결 | S3 접속 시 NAT GW 우회 및 비용 절감 |

***

## 📁 파일 구조

프로젝트의 핵심 인프라 정의 파일 구조입니다.

```bash
.
├── provider.tf      # AWS 프로바이더 및 리전 설정 코드
└── vpc.tf           # VPC, Subnet, Gateway, Route Table, Endpoint 정의 코드
```

⚙️ 사용 명령어
Terraform을 실행하고 관리하는 주요 명령어입니다.

1. 초기화 (Initialization)
프로바이더 플러그인을 다운로드하고 작업 디렉토리를 초기화합니다.

terraform init
2. 실행 계획 확인 (Planning)
실제 리소스를 생성하기 전에, 코드가 AWS에 어떤 변경 사항을 적용할지 미리 확인합니다. (IDE의 컴파일 과정과 유사)

terraform plan
3. 인프라 적용 (Applying)
계획된 변경 사항을 AWS에 실제 적용하여 리소스를 생성합니다.

terraform apply
4. 리소스 삭제 (Destroying)
테스트 및 비용 관리를 위해 Terraform이 생성한 **모든 클라우드 리소스(인프라)**를 안전하게 삭제합니다. (로컬의 .tf 파일은 유지됨)

terraform destroy
⚠️ 중요: 비용 관리
NAT Gateway는 시간당 사용료가 부과되는 AWS 리소스이므로, 테스트를 마친 후에는 반드시 **terraform destroy**를 실행하여 불필요한 비용 발생을 방지해야 합니다.
