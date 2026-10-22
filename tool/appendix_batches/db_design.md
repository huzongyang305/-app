## 范式速查

| 范式 | 要求 | 解决的问题 |
| --- | --- | --- |
| 1NF | 字段原子、不可再分 | 一个字段存多个值 |
| 2NF | 消除非主属性对主键的部分依赖 | 复合主键下的冗余 |
| 3NF | 消除传递依赖 | 非主属性依赖非主属性 |
| BCNF | 每个决定因素都是候选键 | 主属性间的依赖异常 |

## 建模速查

| 关系 | 实现方式 |
| --- | --- |
| 一对多 | 多的一方加外键 |
| 多对多 | 中间关联表（联合唯一索引） |
| 一对一 | 共享主键或唯一外键 |
| 树形结构 | 父节点 ID / 路径枚举 / 闭包表 |

| 字段类型 | 建议 |
| --- | --- |
| 主键 | 无业务含义的自增或雪花 ID |
| 金额 | `DECIMAL(12,2)` 或整数分 |
| 时间 | `DATETIME(3)`，存 UTC |
| 布尔 | `TINYINT(1)` 或枚举字符串 |
| 枚举状态 | `VARCHAR` + 约束，或字典表 |
| 大文本 | 单独表或对象存储 + 引用 |
| JSON | 仅用于结构多变的扩展字段 |

```sql
-- 多对多：中间表必须有联合唯一索引，避免重复关联
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    granted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (user_id, role_id),
    KEY idx_role (role_id, user_id)
);

-- 适度反范式：订单表冗余商品快照，避免历史订单随商品改价而变
CREATE TABLE order_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_name VARCHAR(128) NOT NULL,      -- 快照
    unit_price DECIMAL(12,2) NOT NULL,       -- 快照
    quantity INT NOT NULL,
    KEY idx_order (order_id)
);

-- 逻辑删除：把删除标记纳入唯一索引，保留唯一性约束
CREATE TABLE coupons (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    deleted_at DATETIME(3) NULL,
    UNIQUE KEY uk_code (code, deleted_at)
);
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用业务字段（手机号、身份证）作主键 | 变更困难、索引膨胀 | 用无业务含义的代理主键 |
| 金额用 `FLOAT` / `DOUBLE` | 精度丢失 | 用 `DECIMAL` 或整数分 |
| 时间字段不做时区约定 | 跨时区数据错乱 | 统一存 UTC，展示时转换 |
| 无脑反范式 | 一致性维护成本高 | 先规范化，再按读性能冗余 |
| 中间表不加联合唯一索引 | 出现重复关联 | 用联合主键或唯一索引 |
| 大字段与热字段同表 | 查询变慢、页利用率低 | 拆表或存对象存储 |
| 用 `ENUM` 表示会变的状态 | 加值要改表结构 | 用字典表或字符串 + 约束 |
| 逻辑删除后唯一索引冲突 | 无法再次创建同名校验 | 把删除时间纳入唯一索引 |
| 忘记外键或约束 | 脏数据进入 | 关键关系加约束或应用层校验 |
| 表设计不考虑查询模式 | 后期频繁加索引与改表 | 先梳理核心查询再定字段 |

## 自测清单

- [ ] 能说出 1NF 到 3NF 的核心要求。
- [ ] 多对多关系用中间表 + 联合唯一索引。
- [ ] 金额、时间、布尔字段选对类型。
- [ ] 需要冗余时说明一致性的维护方案。
- [ ] 表设计前先列出核心查询与访问模式。
