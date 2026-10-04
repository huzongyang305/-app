# Terraform 与基础设施即代码

![Terraform 与基础设施即代码](images/category_terraform.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「Terraform 与基础设施即代码」解决了什么问题，而不是只背术语。
- 能说清 「Terraform」、「IaC」、「State」、「plan」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Provider/State/Module、工作流与最佳实践。

## 前置知识

- 先完成上一课《可观测性：日志、指标与链路》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：Terraform、IaC、State。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 为什么需要 IaC

手动在控制台点出来的资源无法复现、无法评审、容易产生「雪花服务器」。基础设施即代码（IaC）把资源写成配置文件，纳入版本控制，用流程化的方式创建与变更。

## 核心概念

| 概念 | 说明 |
| --- | --- |
| Provider | 与云厂商 API 对接（AWS、Azure、阿里云、K8s） |
| Resource | 要创建的资源，如虚拟机、数据库、网络 |
| Variable | 输入参数，区分环境 |
| Output | 暴露结果，供其他模块或脚本使用 |
| State | 记录已创建资源的映射，是 Terraform 的核心 |
| Module | 可复用的资源组合 |

## 工作流

标准流程是 `init → fmt → validate → plan → apply → destroy`。其中 **plan 是安全闸门**：它展示将要新增、修改、销毁的资源，必须人工确认后再 apply。销毁类变更（replace/destroy）要在评审时重点标注。

## 状态管理

State 默认存在本地文件，团队协作必须改为**远程后端**（如 S3 + DynamoDB 锁、Terraform Cloud、OSS），否则多人同时 apply 会互相覆盖。State 中还可能包含敏感信息，需加密并限制访问。

## 环境隔离

常见做法有三种：目录隔离（envs/dev、envs/prod 各自一份配置）、工作区（workspace）、以及同一份模块 + 不同变量文件。生产与测试必须使用不同的 State，避免误操作。

## 最佳实践

1. 所有变更走代码评审与 CI，禁止本地直接 apply 生产。
2. 用 `plan` 输出作为 PR 评论，让变更可见。
3. 给资源打统一标签（项目、环境、负责人），便于成本归集。
4. 敏感变量用密钥管理服务注入，不要写进仓库。
5. 定期 `terraform plan` 检测漂移（有人手工改过资源）。
6. 版本固定 Provider 与模块版本，避免不兼容升级。

## 常见坑

1. 手工在控制台改资源，导致 State 与实际不一致（漂移）。
2. 直接删 State 文件「重来」，造成资源失控。
3. 用 `-auto-approve` 跑生产，跳过人工确认。
4. 把密钥、证书写进 tf 文件并提交。
5. 把所有资源塞进一个巨型 State，变更风险与耗时都极高。

## 模块化与协作要点

| 主题 | 实践 |
| --- | --- |
| 模块划分 | 按职责拆（网络/数据库/应用），模块只暴露必要变量与输出 |
| 变量校验 | 用 validation 块限制取值范围，例如环境只能是 dev/staging/prod |
| 版本固定 | Provider 与模块都写死版本号，避免上游变更导致意外差异 |
| 命名规范 | 资源名带项目-环境-用途前缀，便于检索与计费归集 |
| 敏感值 | 用 sensitive = true 标记变量与输出，避免打印到日志 |

**团队协作流程**：功能分支修改 → CI 执行 `terraform fmt -check`、`validate`、`plan` 并把 plan 结果贴到 PR → 人工评审（重点看 destroy/replace）→ 合并后由受控流水线 apply → 记录 apply 输出与版本标签。禁止开发者本地直接对生产 apply。

**漂移处理**：定期跑 `terraform plan`，若出现非本次变更的差异说明有人手工改过资源；处理方式是把改动同步回代码（import 或补配置），而不是忽略差异——否则下次 apply 可能覆盖掉手工改动。

## 本课小结
Terraform 的价值在于**可复现、可评审、可回滚**。记住两件事：State 要远程托管并加锁，生产变更必须先看 plan。

<!-- appendix:v1 -->

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

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Terraform、IaC、State」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Terraform 与基础设施即代码」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「IaC」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Terraform」和「IaC」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Terraform & IaC

**Summary:** Providers, state, modules and workflows.

**Category:** Toolchain  
**Level:** 高级  
**Key terms:** Terraform, IaC, State, plan, 模块

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Terraform、IaC、State、plan、模块
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：Provider/State/Module、工作流与最佳实践。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

