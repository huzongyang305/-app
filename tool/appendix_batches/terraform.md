## 工作流速查

| 命令 | 作用 | 注意 |
| --- | --- | --- |
| `terraform init` | 初始化后端与插件 | 首次或换后端时执行 |
| `terraform fmt` | 格式化代码 | 提交前执行 |
| `terraform validate` | 语法与引用校验 | 不访问远端 |
| `terraform plan` | 预览变更 | 保存计划文件供 apply 使用 |
| `terraform apply` | 应用变更 | 生产需评审与二次确认 |
| `terraform destroy` | 销毁资源 | 极度危险，需明确目标 |
| `terraform state list` | 查看已管理资源 | 排查漂移 |
| `terraform import` | 导入已存在资源 | 导入后需校对配置 |
| `terraform output` | 读取输出值 | 供其他模块或脚本使用 |

## 状态与模块速查

| 主题 | 建议 |
| --- | --- |
| 远端状态 | 用对象存储 + 锁（DynamoDB 或等价机制） |
| 状态隔离 | 按环境与业务拆分独立状态 |
| 敏感数据 | 状态含明文，务必加密并限制访问 |
| 模块化 | 输入变量清晰、输出明确、版本固定 |
| 环境差异 | 用变量与 tfvars 区分，避免复制粘贴 |
| 漂移检测 | 定期 `plan` 或专用工具检测 |

```hcl
# 远端状态 + 锁定，保证团队协作安全
terraform {
  required_version = ">= 1.6"
  backend "s3" {
    bucket         = "company-tfstate"
    key            = "prod/network/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# 模块调用：固定版本，变量显式传入
module "network" {
  source  = "git::https://example.com/infra/modules/network.git?ref=v1.4.2"
  name    = "prod-vpc"
  cidr    = "10.20.0.0/16"
  azs     = ["ap-southeast-1a", "ap-southeast-1b"]
  tags    = local.common_tags
}

# 变量校验：把非法输入挡在 plan 之前
variable "instance_count" {
  type        = number
  description = "实例数量"
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 50
    error_message = "实例数量必须在 1 到 50 之间。"
  }
}

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "子网 ID 列表"
}
```

```python
import json
import subprocess

def plan_summary(plan_file: str = "plan.tfplan") -> dict:
    """把 plan 转为可审阅的摘要：新增、修改、销毁各多少。"""
    proc = subprocess.run(
        ["terraform", "show", "-json", plan_file],
        capture_output=True, text=True, check=True,
    )
    data = json.loads(proc.stdout)
    actions = {"create": 0, "update": 0, "delete": 0, "replace": 0}
    for change in data.get("resource_changes", []):
        for action in change["change"]["actions"]:
            if action == "create":
                actions["create"] += 1
            elif action == "update":
                actions["update"] += 1
            elif action == "delete":
                actions["delete"] += 1
            elif action == "delete" and "create" in change["change"]["actions"]:
                actions["replace"] += 1
    risky = actions["delete"] > 0 or actions["replace"] > 0
    return {"actions": actions, "needs_review": risky}

def guard_production(workspace: str, actions: dict, allow_delete: bool = False) -> str:
    """生产保护：存在销毁或替换时要求显式授权。"""
    if workspace == "prod" and (actions.get("delete") or actions.get("replace")) and not allow_delete:
        return "阻止：生产环境存在销毁或替换，需人工批准"
    return "允许执行"

print(guard_production("prod", {"delete": 1}, allow_delete=False))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 状态存本地 | 协作冲突、状态丢失 | 用远端状态 + 锁 |
| 所有环境共用一个状态 | 一处变更影响全部 | 按环境隔离状态 |
| 手动改云上资源 | 漂移、下次 apply 被覆盖 | 变更走代码，紧急修改后回填 |
| `apply` 不看 `plan` | 误删资源 | 保存计划文件并评审 |
| 模块不锁版本 | 上游变更导致意外 | 固定 `ref` 或版本号 |
| 密钥写进 tfvars 提交 | 泄漏 | 用密钥管理或环境注入 |
| 认为状态文件不敏感 | 明文含密码与密钥 | 加密存储 + 严格权限 |
| 无护栏直接 destroy | 误删生产 | 生产保护与二次确认 |
| 变量无校验 | 非法值进入 plan | 用 `validation` 约束 |
| 不检测漂移 | 实际与代码不一致 | 定期 plan 巡检 |

## 自测清单

- [ ] 状态远端化并启用锁与加密。
- [ ] 环境状态隔离，模块版本固定。
- [ ] 生产 apply 前评审 plan 摘要。
- [ ] 密钥不入库，靠密钥管理注入。
- [ ] 有漂移检测与生产销毁保护。
