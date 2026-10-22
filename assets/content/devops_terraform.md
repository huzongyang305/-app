# DevOps 课程：基础设施即代码（Terraform 实战）

> 版本：v2.0 | 难度：初学者友好 | 预计学时：8-10 小时

![Terraform 工作流程](images/devops_terraform_workflow.webp)

---

## 第 1 章：课程介绍与 IaC 理念

### 什么是基础设施即代码？

想象你要装修一套房子。传统方式是每次需要改动——刷墙、铺地板、装灯——都要亲自跑一趟建材市场，手动搬运材料，凭记忆记录上次用了什么颜色、什么型号。如果下次要装修另一套房子，你还得从头来过。

**基础设施即代码（Infrastructure as Code，IaC）** 就像是把装修方案写成了一份"万能施工图纸"。你只需要在图纸上描述"客厅铺木地板、墙面刷白色乳胶漆、安装三盏吸顶灯"，然后让机器自动按照图纸施工。下次需要复制同样的布局？直接复用图纸就行。

### IaC 的核心优势

| 优势 | 说明 |
|------|------|
| 可重复性 | 同一份代码可以反复执行，结果一致 |
| 版本控制 | 代码可以提交到 Git，追踪每次变更 |
| 自动化 | 无需手动点击控制台，减少人为失误 |
| 协作 | 团队成员可以审查和讨论基础设施变更 |
| 成本节约 | 快速创建和销毁环境，按需使用云资源 |

### 为什么选择 Terraform？

如果把 IaC 工具比作乐高积木，Terraform 就是那套"万能积木套装"——它不绑定某一家云厂商，支持 AWS、Azure、GCP、阿里云等数百种 Provider。你用同一套语法，就能搭建不同云平台上的基础设施。

---

## 第 2 章：Terraform 安装与环境配置

### 安装 Terraform

**Windows 用户**（使用 Chocolatey）：

```powershell
choco install terraform -y
```

**macOS 用户**（使用 Homebrew）：

```bash
brew install terraform
```

**Linux 用户**（Ubuntu/Debian）：

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 验证安装

```bash
terraform version
# 输出示例：Terraform v1.7.0
```

### 配置云厂商凭证

以 AWS 为例，配置 CLI 凭证：

```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

---

## 第 3 章：HCL 语法基础

### HCL 是什么？

HCL（HashiCorp Configuration Language）是 Terraform 使用的"语言"。你可以把它想象成一种"装修合同模板"——它用人类可读的格式描述你想要的基础设施。

### 基本语法结构

HCL 的核心结构是"块（Block）"，就像一个个带标签的盒子：

```hcl
# 这是一个块（Block）
# "类型" "名称" { 内容 }
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "MyWebServer"
  }
}
```

### 常见语法元素

```hcl
# 字符串
name = "hello-world"

# 数字
count = 3

# 布尔值
enabled = true

# 列表
ports = [80, 443, 8080]

# 对象/映射
tags = {
  Environment = "production"
  Team        = "devops"
}

# 插值表达式（引用变量）
greeting = "Hello, ${var.username}!"

# 条件表达式
size = var.is_production ? "large" : "small"
```

---

## 第 4 章：Provider 与 Resource 核心概念

### Provider：云厂商的"翻译官"

Provider 就像 Terraform 和云厂商之间的"翻译官"。你说中文（HCL），翻译官帮你翻译成 AWS 能听懂的 API 调用。

```hcl
# 声明使用 AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 配置 Provider
provider "aws" {
  region = "us-east-1"
}
```

### Resource：基础设施的"积木块"

Resource 是你实际要创建的基础设施组件，就像乐高积木中的每一块——一块是服务器，一块是数据库，一块是网络。

```hcl
# 创建一个 EC2 实例
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "AppServer"
  }
}

# 创建一个 S3 存储桶
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-unique-data-bucket-2024"

  tags = {
    Purpose = "data-storage"
  }
}

# 创建安全组
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow HTTP and HTTPS"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Terraform 工作流

```bash
# 1. 初始化（下载 Provider 插件）
terraform init

# 2. 计划（预览将要创建的资源）
terraform plan

# 3. 应用（实际创建资源）
terraform apply

# 4. 销毁（清理所有资源）
terraform destroy
```

---

## 第 5 章：变量与输出（Variable & Output）

### 输入变量：让配置更灵活

变量就像"填空题"——你不需要每次修改配置都去改代码，只需要改变量的值。

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 实例类型"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "环境必须是 dev、staging 或 prod 之一。"
  }
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "是否启用监控"
  type        = bool
  default     = true
}
```

### 变量赋值方式

```bash
# 方式 1：命令行参数
terraform apply -var="instance_type=t3.medium"

# 方式 2：变量文件（terraform.tfvars）
# instance_type   = "t3.medium"
# environment     = "prod"
# instance_count  = 3

# 方式 3：环境变量
# export TF_VAR_instance_type="t3.medium"
```

### 输出值：获取资源信息

输出就像"收据"——资源创建完成后，你通过输出获取关键信息（如 IP 地址、ARN 等）。

```hcl
# outputs.tf
output "instance_ip" {
  description = "EC2 实例的公网 IP"
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "EC2 实例 ID"
  value       = aws_instance.app_server.id
}

output "s3_bucket_arn" {
  description = "S3 存储桶的 ARN"
  value       = aws_s3_bucket.data_bucket.arn
}
```

---

## 第 6 章：数据源（Data Source）

### 什么是数据源？

数据源就像"查字典"——你不需要创建新资源，而是查询已经存在的资源信息。比如你想知道某个 AMI 的最新 ID，或者某个 VPC 的 ID。

```hcl
# 查询最新的 Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 查询默认 VPC
data "aws_vpc" "default" {
  default = true
}

# 查询可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 使用数据源创建资源
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_vpc.default.main_route_table_id
}

# 输出 AMI ID
output "ami_id" {
  value = data.aws_ami.amazon_linux.id
}
```

---

## 第 7 章：状态管理（State Management）

### 什么是状态文件？

状态文件（terraform.tfstate）就像 Terraform 的"记忆"——它记录了当前基础设施的真实状态。每次执行 `terraform apply`，Terraform 都会对比"代码中描述的状态"和"状态文件中记录的实际状态"，然后决定需要做什么改动。

### 本地状态（适合个人学习）

```hcl
# 默认情况下，状态保存在当前目录的 terraform.tfstate 文件中
# 不建议在生产环境中使用本地状态！
```

### 远程状态（团队协作必备）

```hcl
# 使用 S3 存储桶保存远程状态
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # 状态锁定
    encrypt        = true
  }
}
```

### 状态锁定（防止并发冲突）

```hcl
# 创建 DynamoDB 表用于状态锁定
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 常用状态操作命令

```bash
# 查看当前状态
terraform show

# 列出所有资源
terraform state list

# 查看某个资源的详细信息
terraform state show aws_instance.app_server

# 从状态中移除资源（不删除实际资源）
terraform state rm aws_instance.app_server

# 导入已存在的资源到状态
terraform import aws_instance.app_server i-1234567890abcdef0
```

---

## 第 8 章：模块设计（Module Design）

### 什么是模块？

模块就像"预制件"——你把一组相关的资源打包成一个可复用的组件。就像乐高套装中的"车轮组件"，你可以把它用在不同的模型上。

### 目录结构

```text
terraform-project/
├── modules/                    # 模块目录
│   ├── vpc/                    # VPC 模块
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/                    # EC2 模块
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rds/                    # RDS 模块
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/               # 环境目录
│   ├── dev/
│   │   └── main.tf
│   ├── staging/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
└── main.tf                     # 根模块
```

### 创建 VPC 模块

```hcl
# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "环境名称"
  type        = string
}

# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# modules/vpc/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "公有子网 ID 列表"
  value       = aws_subnet.public[*].id
}
```

### 在根模块中使用模块

```hcl
# main.tf（根模块）
module "vpc" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = "prod"
}

module "ec2" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  instance_type = "t3.medium"
  environment   = "prod"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

### 模块注册表（Terraform Registry）

```hcl
# 使用官方 VPC 模块
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
```

---

## 第 9 章：工作区与环境管理（dev/staging/prod）

### 什么是工作区？

工作区就像"平行宇宙"——同一份代码可以在不同的工作区中运行，每个工作区有自己独立的状态文件。这样你就可以用同一套代码管理 dev、staging、prod 三个环境。

### 使用工作区

```bash
# 创建工作区
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 切换工作区
terraform workspace select dev

# 查看当前工作区
terraform workspace show

# 列出所有工作区
terraform workspace list
```

### 在工作区中使用变量

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 实例类型"
  type        = string
}

# 根据工作区自动选择实例类型
locals {
  instance_type_map = {
    dev     = "t2.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type_map[terraform.workspace]

  tags = {
    Name        = "app-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

### 使用 tfvars 文件管理多环境

```bash
# dev.tfvars
instance_type = "t2.micro"
environment   = "dev"
db_size       = "db.t3.micro"

# prod.tfvars
instance_type = "t3.large"
environment   = "prod"
db_size       = "db.r5.xlarge"
```

```bash
# 应用不同环境
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"
```

---

## 第 10 章：Terraform Cloud 与团队协作

### Terraform Cloud 是什么？

Terraform Cloud 就像"团队协作工作台"——它提供了一个中央平台，让团队成员可以共同管理 Terraform 配置、状态文件和执行计划。

### 配置 Terraform Cloud

```hcl
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      name = "my-app-prod"
    }
  }
}
```

### 团队协作最佳实践

```hcl
# 使用远程执行模式
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      name = "production"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 版本控制集成

Terraform Cloud 支持与 GitHub、GitLab、Bitbucket 集成，当代码推送到主分支时自动触发 `terraform plan`，审批后执行 `terraform apply`。

---

## 第 11 章：与 CI/CD 集成（自动化 plan/apply）

### GitHub Actions 示例

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
```

### GitLab CI 示例

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - apply

variables:
  TF_STATE_BUCKET: "my-terraform-state"
  TF_STATE_KEY: "prod/terraform.tfstate"

validate:
  stage: validate
  image:
    name: hashicorp/terraform:1.7.0
    entrypoint: [""]
  script:
    - terraform init
    - terraform fmt -check
    - terraform validate

plan:
  stage: plan
  image:
    name: hashicorp/terraform:1.7.0
    entrypoint: [""]
  script:
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan

apply:
  stage: apply
  image:
    name: hashicorp/terraform:1.7.0
    entrypoint: [""]
  script:
    - terraform init
    - terraform apply -auto-approve tfplan
  when: manual
  only:
    - main
```

---

## 第 12 章：实战——使用 Terraform 部署 AWS EKS 集群

### 项目结构

```text
eks-deployment/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 版本配置

```hcl
# versions.tf
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state-eks"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 变量定义

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS 集群名称"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes 版本"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "节点组实例类型"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "节点组期望节点数"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "节点组最小节点数"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "节点组最大节点数"
  type        = number
  default     = 4
}
```

### VPC 模块

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
}

resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"
}

resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.eks_igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

### EKS 模块

```hcl
# modules/eks/main.tf
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}
```

### 根模块组装

```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnet_ids

  instance_types = var.node_group_instance_types
  desired_size   = var.node_group_desired_size
  min_size       = var.node_group_min_size
  max_size       = var.node_group_max_size
}
```

### 输出配置

```hcl
# outputs.tf
output "cluster_endpoint" {
  description = "EKS 集群 API 端点"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS 集群名称"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority" {
  description = "集群证书颁发机构数据"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "kubeconfig_command" {
  description = "获取 kubeconfig 的命令"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
```

### 部署步骤

```bash
# 1. 初始化 Terraform
terraform init

# 2. 检查代码格式
terraform fmt -recursive

# 3. 验证配置
terraform validate

# 4. 预览变更
terraform plan

# 5. 创建 EKS 集群
terraform apply

# 6. 配置 kubectl
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# 7. 验证集群
kubectl get nodes
kubectl get namespaces
```

---

## 第 13 章：课程总结与复习清单

### 核心概念回顾

本课程中，我们从零开始学习了 Terraform 的核心概念和实战应用。Terraform 就像"基础设施的乐高积木"——通过 HCL 语法描述你想要的资源，Terraform 帮你自动创建、管理和维护这些资源。

### 关键知识点

| 概念 | 类比 | 说明 |
|------|------|------|
| Provider | 翻译官 | 连接 Terraform 和云厂商 |
| Resource | 积木块 | 实际创建的基础设施组件 |
| Variable | 填空题 | 让配置更灵活，无需硬编码 |
| Output | 收据 | 获取资源的关键信息 |
| Data Source | 查字典 | 查询已存在的资源信息 |
| State | 记忆 | 记录基础设施的当前状态 |
| Module | 预制件 | 可复用的资源组合 |
| Workspace | 平行宇宙 | 同一代码管理多个环境 |

### 复习清单

- [ ] 能否独立编写一个创建 EC2 实例的 Terraform 配置？
- [ ] 是否理解了变量（variable）、输出（output）和数据源（data source）的区别？
- [ ] 能否解释本地状态和远程状态的区别，以及为什么生产环境需要远程状态？
- [ ] 是否掌握了模块的创建和使用方法？
- [ ] 能否配置 Terraform 与 GitHub Actions 的 CI/CD 集成？
- [ ] 是否理解了工作区（workspace）的作用和使用场景？
- [ ] 能否独立完成 EKS 集群的 Terraform 部署？

### 下一步学习建议

1. **深入学习**：阅读 [Terraform 官方文档](https://developer.hashicorp.com/terraform/docs)
2. **动手实践**：在 AWS 免费层中练习创建和销毁资源
3. **探索模块**：浏览 [Terraform Registry](https://registry.terraform.io/) 学习社区模块
4. **团队协作**：尝试使用 Terraform Cloud 进行团队协作
5. **高级主题**：学习 Terraform 的 `for_each`、`dynamic` 块和自定义验证规则

### 参考资源

- [Terraform 官方文档](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider 文档](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform 最佳实践](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [HashiCorp Learn](https://developer.hashicorp.com/terraform/tutorials)

---

> 恭喜你完成了 Terraform 实战课程！现在你已经掌握了基础设施即代码的核心技能，可以开始在实际项目中应用 Terraform 了。记住，实践是最好的老师——多动手，多尝试，你会越来越熟练！
