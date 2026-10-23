# 推荐系统实现

![推荐系统实现示意：devops terraform workflow](images/devops_terraform_workflow.webp)

## 本章摘要

推荐系统是现代互联网产品的核心引擎，就像一位了解你口味的私人导购员。协同过滤通过"物以类聚、人以群分"的原理，找到与你品味相似的用户或相似的商品进行推荐；深度学习推荐则通过挖掘用户行为序列中的复杂模式，捕捉更细微的偏好信号。本章从经典的矩阵分解讲起，带你理解隐语义空间的概念，然后学习基于神经网络的推荐模型，最后实现一个完整的电商推荐系统。我们将用餐厅点菜、音乐品味等生活化比喻解释抽象概念，让你轻松掌握这个直接影响用户体验的关键技术。

## 学习目标

完成本章后，你将能够：

1. 理解推荐系统的三大范式：基于内容、协同过滤、混合推荐的优缺点及适用场景
2. 掌握矩阵分解（Matrix Factorization）的数学原理和ALS、SGD优化算法
3. 实现基于用户的协同过滤（UserCF）和基于物品的协同过滤（ItemCF）
4. 使用深度学习模型（NeuMF、Wide&Deep、DeepFM）提升推荐效果
5. 学会评估推荐系统的指标：准确率、召回率、NDCG、覆盖率、多样性
6. 处理冷启动问题和数据稀疏性挑战，设计合理的推荐策略

## 核心概念与生活类比

### 1. 协同过滤：朋友圈的智慧

想象你去一个新城市想找好吃的餐厅。方法一：问问当地朋友他们喜欢哪家（基于用户的协同过滤）——如果你们口味相似，他们的推荐很可能适合你。方法二：看看你喜欢的那家餐厅附近还有什么其他好评餐厅（基于物品的协同过滤）——好的餐厅往往聚集在美食街区。这两种方法都不需要了解餐厅的具体菜品（不需要内容特征），纯粹依靠群体的集体智慧。这就是协同过滤的核心思想：利用群体行为数据发现隐藏的模式。

### 2. 矩阵分解：降维的魔法

用户-物品评分矩阵就像一个巨大的表格，行是用户，列是电影，单元格是评分。但这个表格非常稀疏（大多数人只看过少数电影）。矩阵分解把这个大表格拆成两个小表格：用户隐因子矩阵和物品隐因子矩阵。每个用户和物品都被映射到一个低维的"品味空间"中。比如某个维度代表"科幻偏好度"，另一个维度代表"喜剧偏好度"。虽然这些维度没有明确的标签，但它们捕捉了用户和物品的本质特征。预测评分就是计算用户向量和物品向量的点积。

### 3. 冷启动问题：新人的困境

冷启动就像新开张的餐厅没有顾客评价，或者新用户刚注册没有任何行为记录。基于协同过滤的方法完全失效，因为没有历史数据可参考。解决策略包括：基于内容的推荐（利用物品本身的属性）、热门推荐（大家都喜欢的安全选择）、探索与利用平衡（偶尔推荐一些不确定的物品来收集反馈）、以及要求用户填写兴趣问卷。实际系统中通常采用混合策略，随着数据积累逐渐过渡到个性化推荐。

### 4. 隐语义空间：看不见的品味维度

隐语义空间就像是一个多维的"品味坐标系"。在这个空间中，每个用户和物品都有一个位置坐标。虽然我们无法直接解释每个维度的含义（不像"价格"、"颜色"那样直观），但距离相近的用户意味着品味相似，距离相近的物品意味着风格类似。这个空间是通过分析大量用户行为数据自动学习出来的，它捕捉的是统计相关性而非因果关系。深度学习模型可以学习到更高阶、更复杂的隐语义表示。

### 5. 探索与利用平衡：冒险与保守的权衡

推荐系统面临一个经典困境：是推荐已知用户会喜欢的物品（利用，Exploitation），还是尝试推荐一些新的可能感兴趣的物品（探索，Exploration）？这就像去餐厅点菜：总是点熟悉的招牌菜很安全但可能错过新美味，尝试新菜有风险但可能发现新宠。多臂老虎机（Multi-Armed Bandit）算法提供了数学框架来平衡这两者：初期多探索收集信息，后期多利用已获得的最佳策略。epsilon-greedy和Thompson Sampling是两种常用策略。

### 6. 评估指标的多样性：不止是准确率

推荐系统的评估比分类任务复杂得多。准确率（Precision）衡量推荐列表中有多少是用户真正喜欢的；召回率（Recall）衡量用户喜欢的物品中有多少被推荐出来了；NDCG（归一化折损累计增益）考虑了排名位置的重要性（排第一的推荐比排第十的更有价值）；覆盖率衡量系统能推荐多少比例的物品（避免只推荐热门物品）；多样性衡量推荐列表中文物的差异程度（避免全部推荐同一类型）。一个好的推荐系统需要在这些指标之间取得平衡。

## 渐进式代码示例

### 最小化示例：基础协同过滤

让我们从最简单的基于用户的协同过滤开始，直观感受推荐的工作原理。

```python
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from collections import defaultdict

# ==================== 基于用户的协同过滤 ====================

# 示例用户-物品评分矩阵（行：用户，列：物品）
ratings_matrix = np.array([
    # 物品1  物品2  物品3  物品4  物品5
    [5, 3, 0, 1, 4],   # 用户1
    [4, 0, 0, 1, 5],   # 用户2
    [1, 1, 0, 5, 3],   # 用户3
    [0, 0, 5, 4, 0],   # 用户4
    [5, 4, 4, 0, 0],   # 用户5
    [0, 0, 0, 5, 2]    # 用户6
])

user_ids = ['用户1', '用户2', '用户3', '用户4', '用户5', '用户6']
item_ids = ['物品1', '物品2', '物品3', '物品4', '物品5']

print("用户-物品评分矩阵:")
df_ratings = pd.DataFrame(ratings_matrix, index=user_ids, columns=item_ids)
print(df_ratings)
print(f"\n矩阵稀疏度: {1 - np.count_nonzero(ratings_matrix) / ratings_matrix.size:.2%}")

# 计算用户相似度（余弦相似度）
user_similarity = cosine_similarity(ratings_matrix)
sim_df = pd.DataFrame(user_similarity, index=user_ids, columns=user_ids)
print("\n用户相似度矩阵:")
print(sim_df.round(3))

# 为用户4推荐物品
target_user_idx = 3  # 用户4
target_user_ratings = ratings_matrix[target_user_idx]

# 找出目标用户未评分的物品
unrated_items = np.where(target_user_ratings == 0)[0]
print(f"\n用户4未评分的物品索引: {unrated_items}")

# 预测评分：加权平均相似用户的评分
predicted_scores = {}
for item_idx in unrated_items:
    # 找出对该物品评过分的用户
    rated_users = np.where(ratings_matrix[:, item_idx] > 0)[0]
    rated_users = rated_users[rated_users != target_user_idx]
    
    if len(rated_users) > 0:
        # 获取相似度权重
        similarities = user_similarity[target_user_idx, rated_users]
        ratings = ratings_matrix[rated_users, item_idx]
        
        # 加权平均
        predicted_score = np.dot(similarities, ratings) / np.sum(np.abs(similarities))
        predicted_scores[item_idx] = predicted_score

print("\n用户4的预测评分:")
for item_idx, score in sorted(predicted_scores.items(), key=lambda x: x[1], reverse=True):
    print(f"  {item_ids[item_idx]}: {score:.2f}")

# ==================== 基于物品的协同过滤 ====================

# 计算物品相似度
item_similarity = cosine_similarity(ratings_matrix.T)
item_sim_df = pd.DataFrame(item_similarity, index=item_ids, columns=item_ids)
print("\n物品相似度矩阵:")
print(item_sim_df.round(3))

# 为用户4推荐（基于物品相似度）
def predict_score_item_based(user_idx, item_idx, ratings_mat, item_sim_mat):
    """基于物品的协同过滤预测评分"""
    rated_items = np.where(ratings_mat[user_idx] > 0)[0]
    
    if len(rated_items) == 0:
        return 0
    
    similarities = item_sim_mat[item_idx, rated_items]
    ratings = ratings_mat[user_idx, rated_items]
    
    # 只考虑正相似度
    positive_mask = similarities > 0
    if not np.any(positive_mask):
        return 0
    
    similarities = similarities[positive_mask]
    ratings = ratings[positive_mask]
    
    predicted = np.dot(similarities, ratings) / np.sum(similarities)
    return predicted

print("\n基于物品CF - 用户4的预测评分:")
for item_idx in unrated_items:
    score = predict_score_item_based(target_user_idx, item_idx, ratings_matrix, item_similarity)
    print(f"  {item_ids[item_idx]}: {score:.2f}")
```

这个例子展示了协同过滤的基本原理：通过计算用户或物品之间的相似度，利用邻居的评分来预测目标用户对未接触物品的喜好。基于用户的方法找"相似的人"，基于物品的方法找"相似的物品"。注意这里使用的是余弦相似度，也可以使用皮尔逊相关系数或调整余弦相似度来处理用户评分偏差。

### 完整示例：矩阵分解推荐系统

现在我们来实现一个完整的矩阵分解推荐系统，使用随机梯度下降（SGD）进行优化。

```python
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split

# ==================== 生成模拟数据 ====================

np.random.seed(42)
num_users = 100
num_items = 50
num_ratings = 500

# 生成用户ID、物品ID和评分
user_ids_sim = np.random.randint(0, num_users, num_ratings)
item_ids_sim = np.random.randint(0, num_items, num_ratings)
ratings_sim = np.random.uniform(1, 5, num_ratings).round(1)

# 构建稀疏矩阵
sparse_matrix = np.zeros((num_users, num_items))
for u, i, r in zip(user_ids_sim, item_ids_sim, ratings_sim):
    sparse_matrix[u, i] = r

print(f"数据规模: {num_users}用户, {num_items}物品, {num_ratings}评分")
print(f"稀疏度: {1 - np.count_nonzero(sparse_matrix) / sparse_matrix.size:.2%}")

# ==================== TensorFlow矩阵分解 ====================

class MatrixFactorizationTF(tf.keras.Model):
    """TensorFlow矩阵分解模型"""
    def __init__(self, num_users, num_items, latent_dim=32):
        super(MatrixFactorizationTF, self).__init__()
        
        # 用户和物品的隐因子向量
        self.user_embedding = layers.Embedding(
            num_users, latent_dim, 
            embeddings_initializer='random_normal'
        )
        self.item_embedding = layers.Embedding(
            num_items, latent_dim,
            embeddings_initializer='random_normal'
        )
        
        # 偏置项
        self.user_bias = layers.Embedding(num_users, 1)
        self.item_bias = layers.Embedding(num_items, 1)
        self.global_bias = self.add_weight(
            name='global_bias', 
            shape=(1,), 
            initializer='zeros'
        )
    
    def call(self, inputs):
        user_ids, item_ids = inputs
        
        # 获取嵌入向量
        user_vec = self.user_embedding(user_ids)      # [batch, latent_dim]
        item_vec = self.item_embedding(item_ids)      # [batch, latent_dim]
        
        # 获取偏置
        user_b = self.user_bias(user_ids)             # [batch, 1]
        item_b = self.item_bias(item_ids)             # [batch, 1]
        
        # 预测评分 = 全局偏置 + 用户偏置 + 物品偏置 + 隐因子点积
        prediction = (
            self.global_bias + 
            user_b + 
            item_b + 
            tf.reduce_sum(user_vec * item_vec, axis=1, keepdims=True)
        )
        
        return tf.squeeze(prediction, axis=1)

# 准备数据
users_tf = tf.constant(user_ids_sim, dtype=tf.int32)
items_tf = tf.constant(item_ids_sim, dtype=tf.int32)
ratings_tf = tf.constant(ratings_sim, dtype=tf.float32)

# 划分训练集和测试集
indices = np.arange(num_ratings)
train_idx, test_idx = train_test_split(indices, test_size=0.2, random_state=42)

train_users = tf.gather(users_tf, train_idx)
train_items = tf.gather(items_tf, train_idx)
train_ratings = tf.gather(ratings_tf, train_idx)

test_users = tf.gather(users_tf, test_idx)
test_items = tf.gather(items_tf, test_idx)
test_ratings = tf.gather(ratings_tf, test_idx)

# 构建数据集
train_dataset = tf.data.Dataset.from_tensor_slices((
    (train_users, train_items), train_ratings
)).shuffle(1000).batch(64)

test_dataset = tf.data.Dataset.from_tensor_slices((
    (test_users, test_items), test_ratings
)).batch(64)

# 初始化模型
latent_dim = 32
tf_mf_model = MatrixFactorizationTF(num_users, num_items, latent_dim)

optimizer = tf.keras.optimizers.Adam(learning_rate=0.01)
loss_fn = tf.keras.losses.MeanSquaredError()

# 训练循环
@tf.function
def train_step(users, items, ratings):
    with tf.GradientTape() as tape:
        predictions = tf_mf_model((users, items), training=True)
        loss = loss_fn(ratings, predictions)
        # 添加L2正则化
        reg_loss = 0.001 * (
            tf.reduce_sum(tf.square(tf_mf_model.user_embedding.embeddings)) +
            tf.reduce_sum(tf.square(tf_mf_model.item_embedding.embeddings))
        )
        total_loss = loss + reg_loss
    
    gradients = tape.gradient(total_loss, tf_mf_model.trainable_variables)
    optimizer.apply_gradients(zip(gradients, tf_mf_model.trainable_variables))
    return loss

num_epochs = 20
train_losses = []

for epoch in range(num_epochs):
    epoch_loss = 0.0
    num_batches = 0
    
    for (users_batch, items_batch), ratings_batch in train_dataset:
        loss = train_step(users_batch, items_batch, ratings_batch)
        epoch_loss += loss.numpy()
        num_batches += 1
    
    avg_loss = epoch_loss / num_batches
    train_losses.append(avg_loss)
    
    if (epoch + 1) % 5 == 0:
        # 评估测试集
        test_preds = tf_mf_model((test_users, test_items), training=False)
        test_mse = tf.reduce_mean(tf.square(test_ratings - test_preds)).numpy()
        test_rmse = np.sqrt(test_mse)
        print(f'Epoch [{epoch+1}/{num_epochs}], Train Loss: {avg_loss:.4f}, Test RMSE: {test_rmse:.4f}')

# 可视化训练损失
plt.figure(figsize=(10, 5))
plt.plot(train_losses, marker='o')
plt.xlabel('Epoch')
plt.ylabel('Training Loss (MSE)')
plt.title('Matrix Factorization Training Loss')
plt.grid(True)
plt.savefig('mf_training_loss.png', dpi=150, bbox_inches='tight')
plt.show()

# 为用户生成推荐
def recommend_items_tf(model, user_id, num_items_total, top_k=5, exclude_rated=None):
    """为指定用户推荐Top-K物品"""
    user_tensor = tf.constant([user_id] * num_items_total, dtype=tf.int32)
    item_tensor = tf.constant(list(range(num_items_total)), dtype=tf.int32)
    
    predictions = model((user_tensor, item_tensor), training=False).numpy()
    
    # 排除已评分物品
    if exclude_rated is not None:
        for idx in exclude_rated:
            predictions[idx] = -np.inf
    
    # 获取Top-K
    top_indices = np.argsort(predictions)[::-1][:top_k]
    recommended = [(idx, predictions[idx]) for idx in top_indices]
    
    return recommended

# 示例：为用户0推荐
user_0_rated = np.where(sparse_matrix[0] > 0)[0]
recommendations = recommend_items_tf(
    tf_mf_model, 0, num_items, top_k=5, exclude_rated=user_0_rated
)
print(f"\n用户0的Top-5推荐:")
for item_idx, score in recommendations:
    print(f"  物品{item_idx}: 预测评分 {score:.2f}")

# ==================== PyTorch矩阵分解 ====================

class MatrixFactorizationPT(nn.Module):
    """PyTorch矩阵分解模型"""
    def __init__(self, num_users, num_items, latent_dim=32):
        super(MatrixFactorizationPT, self).__init__()
        
        self.user_embedding = nn.Embedding(num_users, latent_dim)
        self.item_embedding = nn.Embedding(num_items, latent_dim)
        self.user_bias = nn.Embedding(num_users, 1)
        self.item_bias = nn.Embedding(num_items, 1)
        self.global_bias = nn.Parameter(torch.zeros(1))
        
        # 初始化
        nn.init.normal_(self.user_embedding.weight, std=0.01)
        nn.init.normal_(self.item_embedding.weight, std=0.01)
        nn.init.zeros_(self.user_bias.weight)
        nn.init.zeros_(self.item_bias.weight)
    
    def forward(self, user_ids, item_ids):
        user_vec = self.user_embedding(user_ids)
        item_vec = self.item_embedding(item_ids)
        user_b = self.user_bias(user_ids)
        item_b = self.item_bias(item_ids)
        
        prediction = (
            self.global_bias + 
            user_b.squeeze() + 
            item_b.squeeze() + 
            (user_vec * item_vec).sum(dim=1)
        )
        
        return prediction

# 自定义数据集
class RatingDataset(Dataset):
    def __init__(self, users, items, ratings):
        self.users = torch.LongTensor(users)
        self.items = torch.LongTensor(items)
        self.ratings = torch.FloatTensor(ratings)
    
    def __len__(self):
        return len(self.ratings)
    
    def __getitem__(self, idx):
        return self.users[idx], self.items[idx], self.ratings[idx]

# 准备数据
train_dataset_pt = RatingDataset(
    user_ids_sim[train_idx], 
    item_ids_sim[train_idx], 
    ratings_sim[train_idx]
)
test_dataset_pt = RatingDataset(
    user_ids_sim[test_idx], 
    item_ids_sim[test_idx], 
    ratings_sim[test_idx]
)

train_loader_pt = DataLoader(train_dataset_pt, batch_size=64, shuffle=True)
test_loader_pt = DataLoader(test_dataset_pt, batch_size=256, shuffle=False)

# 初始化模型
pt_mf_model = MatrixFactorizationPT(num_users, num_items, latent_dim)
criterion = nn.MSELoss()
optimizer_pt = torch.optim.Adam(pt_mf_model.parameters(), lr=0.01, weight_decay=1e-4)

# 训练循环
num_epochs_pt = 20
for epoch in range(num_epochs_pt):
    pt_mf_model.train()
    epoch_loss = 0.0
    num_batches = 0
    
    for users_batch, items_batch, ratings_batch in train_loader_pt:
        optimizer_pt.zero_grad()
        predictions = pt_mf_model(users_batch, items_batch)
        loss = criterion(predictions, ratings_batch)
        loss.backward()
        optimizer_pt.step()
        
        epoch_loss += loss.item()
        num_batches += 1
    
    avg_loss = epoch_loss / num_batches
    
    if (epoch + 1) % 5 == 0:
        # 评估
        pt_mf_model.eval()
        test_preds_list = []
        test_targets_list = []
        
        with torch.no_grad():
            for users_batch, items_batch, ratings_batch in test_loader_pt:
                predictions = pt_mf_model(users_batch, items_batch)
                test_preds_list.extend(predictions.numpy())
                test_targets_list.extend(ratings_batch.numpy())
        
        test_preds_array = np.array(test_preds_list)
        test_targets_array = np.array(test_targets_list)
        test_rmse = np.sqrt(np.mean((test_preds_array - test_targets_array) ** 2))
        
        print(f'Epoch [{epoch+1}/{num_epochs_pt}], Train Loss: {avg_loss:.4f}, Test RMSE: {test_rmse:.4f}')

# 推荐函数
def recommend_items_pt(model, user_id, num_items_total, top_k=5, exclude_rated=None):
    model.eval()
    user_tensor = torch.LongTensor([user_id] * num_items_total)
    item_tensor = torch.LongTensor(list(range(num_items_total)))
    
    with torch.no_grad():
        predictions = model(user_tensor, item_tensor).numpy()
    
    if exclude_rated is not None:
        for idx in exclude_rated:
            predictions[idx] = -np.inf
    
    top_indices = np.argsort(predictions)[::-1][:top_k]
    recommended = [(idx, predictions[idx]) for idx in top_indices]
    
    return recommended

user_0_rated_pt = np.where(sparse_matrix[0] > 0)[0]
recommendations_pt = recommend_items_pt(
    pt_mf_model, 0, num_items, top_k=5, exclude_rated=user_0_rated_pt
)
print(f"\nPyTorch - 用户0的Top-5推荐:")
for item_idx, score in recommendations_pt:
    print(f"  物品{item_idx}: 预测评分 {score:.2f}")
```

这个完整示例展示了如何使用矩阵分解构建推荐系统。模型学习了用户和物品的隐因子表示，通过点积预测评分。我们添加了偏置项来捕捉用户和物品的整体倾向性（有些用户打分普遍偏高，有些物品普遍受欢迎）。L2正则化防止过拟合。TensorFlow和PyTorch的实现逻辑相同，只是API风格不同。

### 实践示例：神经协同过滤（NeuMF）

传统的矩阵分解只能捕捉线性关系，神经网络可以学习更复杂的交互模式。NeuMF结合了矩阵分解和多层感知机的优势。

```python
import tensorflow as tf
from tensorflow.keras import layers, models
import torch
import torch.nn as nn
import numpy as np

# ==================== TensorFlow NeuMF ====================

class NeuMFTF(tf.keras.Model):
    """神经矩阵分解模型"""
    def __init__(self, num_users, num_items, latent_dim=32, mlp_layers=[64, 32, 16]):
        super(NeuMFTF, self).__init__()
        
        # MF部分
        self.mf_user_embedding = layers.Embedding(num_users, latent_dim)
        self.mf_item_embedding = layers.Embedding(num_items, latent_dim)
        
        # MLP部分
        self.mlp_user_embedding = layers.Embedding(num_users, mlp_layers[0] // 2)
        self.mlp_item_embedding = layers.Embedding(num_items, mlp_layers[0] // 2)
        
        # MLP层
        mlp_modules = []
        input_dim = mlp_layers[0]
        for units in mlp_layers[1:]:
            mlp_modules.append(layers.Dense(units, activation='relu'))
            mlp_modules.append(layers.Dropout(0.2))
        self.mlp_network = tf.keras.Sequential(mlp_modules)
        
        # 输出层
        self.output_layer = layers.Dense(1, activation='sigmoid')
    
    def call(self, inputs):
        user_ids, item_ids = inputs
        
        # MF部分
        mf_user_vec = self.mf_user_embedding(user_ids)
        mf_item_vec = self.mf_item_embedding(item_ids)
        mf_vector = tf.multiply(mf_user_vec, mf_item_vec)  # 逐元素相乘
        
        # MLP部分
        mlp_user_vec = self.mlp_user_embedding(user_ids)
        mlp_item_vec = self.mlp_item_embedding(item_ids)
        mlp_vector = tf.concat([mlp_user_vec, mlp_item_vec], axis=1)
        mlp_vector = self.mlp_network(mlp_vector)
        
        # 融合MF和MLP
        combined = tf.concat([mf_vector, mlp_vector], axis=1)
        prediction = self.output_layer(combined)
        
        return tf.squeeze(prediction, axis=1)

# 构建模型
neumf_tf = NeuMFTF(num_users, num_items, latent_dim=32, mlp_layers=[64, 32, 16])
neumf_tf.build(input_shape=[(None,), (None,)])
neumf_tf.summary()

# 编译
neumf_tf.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='binary_crossentropy',  # 假设评分>=4为正样本
    metrics=['accuracy']
)

# 准备二分类数据（评分>=4为正，<4为负）
binary_labels = (ratings_sim >= 4).astype(np.float32)

train_labels_tf = tf.gather(binary_labels, train_idx)
test_labels_tf = tf.gather(binary_labels, test_idx)

train_dataset_neumf = tf.data.Dataset.from_tensor_slices((
    (tf.gather(users_tf, train_idx), tf.gather(items_tf, train_idx)),
    train_labels_tf
)).shuffle(1000).batch(64)

# 训练
history_neumf = neumf_tf.fit(
    train_dataset_neumf,
    epochs=10,
    validation_data=(
        (tf.gather(users_tf, test_idx), tf.gather(items_tf, test_idx)),
        test_labels_tf
    )
)

# ==================== PyTorch NeuMF ====================

class NeuMFPT(nn.Module):
    """PyTorch神经矩阵分解模型"""
    def __init__(self, num_users, num_items, latent_dim=32, mlp_layers=[64, 32, 16]):
        super(NeuMFPT, self).__init__()
        
        # MF部分
        self.mf_user_emb = nn.Embedding(num_users, latent_dim)
        self.mf_item_emb = nn.Embedding(num_items, latent_dim)
        
        # MLP部分
        self.mlp_user_emb = nn.Embedding(num_users, mlp_layers[0] // 2)
        self.mlp_item_emb = nn.Embedding(num_items, mlp_layers[0] // 2)
        
        # MLP网络
        mlp_modules = []
        input_dim = mlp_layers[0]
        for i, units in enumerate(mlp_layers[1:]):
            mlp_modules.append(nn.Linear(input_dim, units))
            mlp_modules.append(nn.ReLU())
            mlp_modules.append(nn.Dropout(0.2))
            input_dim = units
        self.mlp_network = nn.Sequential(*mlp_modules)
        
        # 输出层
        self.output_layer = nn.Linear(mlp_layers[-1] + latent_dim, 1)
        self.sigmoid = nn.Sigmoid()
        
        # 初始化
        nn.init.normal_(self.mf_user_emb.weight, std=0.01)
        nn.init.normal_(self.mf_item_emb.weight, std=0.01)
        nn.init.normal_(self.mlp_user_emb.weight, std=0.01)
        nn.init.normal_(self.mlp_item_emb.weight, std=0.01)
    
    def forward(self, user_ids, item_ids):
        # MF部分
        mf_user = self.mf_user_emb(user_ids)
        mf_item = self.mf_item_emb(item_ids)
        mf_vector = mf_user * mf_item
        
        # MLP部分
        mlp_user = self.mlp_user_emb(user_ids)
        mlp_item = self.mlp_item_emb(item_ids)
        mlp_vector = torch.cat([mlp_user, mlp_item], dim=1)
        mlp_vector = self.mlp_network(mlp_vector)
        
        # 融合
        combined = torch.cat([mf_vector, mlp_vector], dim=1)
        output = self.output_layer(combined)
        output = self.sigmoid(output.squeeze())
        
        return output

# 初始化
neumf_pt = NeuMFPT(num_users, num_items, latent_dim=32, mlp_layers=[64, 32, 16])
criterion_pt = nn.BCELoss()
optimizer_pt = torch.optim.Adam(neumf_pt.parameters(), lr=0.001)

# 准备数据
train_binary_labels = binary_labels[train_idx]
test_binary_labels = binary_labels[test_idx]

train_dataset_pt_neumf = RatingDataset(
    user_ids_sim[train_idx],
    item_ids_sim[train_idx],
    train_binary_labels
)
train_loader_neumf = DataLoader(train_dataset_pt_neumf, batch_size=64, shuffle=True)

# 训练
num_epochs_neumf = 10
for epoch in range(num_epochs_neumf):
    neumf_pt.train()
    epoch_loss = 0.0
    correct = 0
    total = 0
    
    for users_batch, items_batch, labels_batch in train_loader_neumf:
        optimizer_pt.zero_grad()
        outputs = neumf_pt(users_batch, items_batch)
        loss = criterion_pt(outputs, labels_batch)
        loss.backward()
        optimizer_pt.step()
        
        epoch_loss += loss.item()
        predicted = (outputs >= 0.5).float()
        correct += (predicted == labels_batch).sum().item()
        total += labels_batch.size(0)
    
    avg_loss = epoch_loss / len(train_loader_neumf)
    accuracy = correct / total
    print(f'Epoch [{epoch+1}/{num_epochs_neumf}], Loss: {avg_loss:.4f}, Acc: {accuracy:.4f}')
```

这个实践示例展示了NeuMF架构：同时使用MF分支捕捉线性交互和MLP分支捕捉非线性交互，最后将两者融合。这种混合架构在实践中通常比纯MF或纯MLP表现更好。注意我们将回归问题转换为二分类问题（高评分vs低评分），这在实际推荐场景中更常见，因为用户真正关心的是"会不会喜欢"而不是精确评分。

## 常见陷阱对照表

| 陷阱类型 | 具体问题描述 | 影响后果 | 解决方案 |
|---------|------------|---------|---------|
| **数据泄露** | 测试集中包含训练时见过的用户-物品对 | 评估指标虚高，实际部署失败 | 严格按时间划分训练/测试集，确保测试集是未来数据 |
| **流行度偏见** | 模型过度推荐热门物品，忽视长尾物品 | 推荐结果单一，马太效应加剧 | 引入多样性惩罚、重新排序、曝光采样修正 |
| **冷启动用户** | 新用户无任何行为记录 | 无法生成个性化推荐 | 使用人口统计信息、问卷调查、热门推荐过渡 |
| **冷启动物品** | 新物品无评分记录 | 永远无法被推荐给任何人 | 基于内容推荐、主动探索策略、给予初始曝光 |
| **评分尺度不一致** | 不同用户评分标准差异大（有人习惯打高分） | 相似度计算失真 | 使用中心化评分、皮尔逊相关系数、隐式反馈 |
| **稀疏矩阵问题** | 用户-物品矩阵过于稀疏（<1%填充率） | 难以找到可靠邻居，MF收敛困难 | 增加隐式反馈数据、使用图神经网络、知识图谱增强 |
| **实时性不足** | 离线训练模型无法反映用户最新兴趣 | 推荐滞后于用户当前需求 | 在线学习、增量更新、会话-based推荐 |
| **评估指标误导** | 仅使用RMSE忽略推荐列表质量 | RMSE低但推荐效果差 | 综合使用Precision@K、Recall@K、NDCG、覆盖率 |
| **反馈循环** | 推荐系统只展示模型认为用户喜欢的内容 | 用户视野变窄，数据偏差加剧 | 引入探索机制、多样化推荐、反事实评估 |
| **隐私合规** | 未经同意收集和使用用户行为数据 | 法律风险和用户信任危机 | 遵守GDPR等法规、匿名化处理、提供退出选项 |

## 自测题目

### 问题1

关于协同过滤，以下哪项描述是正确的？

A. 基于用户的协同过滤需要知道物品的具体属性（如类别、价格）  
B. 基于物品的协同过滤在物品数量远大于用户数量时计算效率更高  
C. 协同过滤可以很好地解决冷启动问题  
D. 协同过滤只能用于显式反馈（评分），不能用于隐式反馈（点击、浏览）  

**正确答案：B**

**详细解释：** 基于物品的协同过滤需要计算物品之间的相似度矩阵，其大小为物品数×物品数。当物品数量远小于用户数量时，这个矩阵相对较小，计算和存储更高效。相反，如果用户数量少而物品数量巨大，基于用户的方法会更高效。选项A错误，协同过滤的优势恰恰是不需要物品属性；选项C错误，冷启动是协同过滤的主要弱点；选项D错误，协同过滤可以适配隐式反馈，只需将二元交互（点击/未点击）视为特殊评分。

### 问题2

矩阵分解中，隐因子维度（latent dimension）的选择对模型性能有何影响？

A. 维度越高越好，可以捕捉更多细节  
B. 维度越低越好，计算更快且不易过拟合  
C. 需要根据数据规模和稀疏度权衡，通常通过交叉验证选择  
D. 隐因子维度对模型性能几乎没有影响  

**正确答案：C**

**详细解释：** 隐因子维度是一个需要仔细调优的超参数。维度太低无法充分表达用户和物品的复杂特征，导致欠拟合；维度太高则会记住训练数据中的噪声，导致过拟合。一般经验法则是：数据量大且稠密时使用较高维度（64-128），数据量小或稀疏时使用较低维度（8-32）。最佳值通常通过交叉验证在验证集上确定。选项A和B都过于绝对，选项D明显错误。

### 问题3

在推荐系统评估中，NDCG（Normalized Discounted Cumulative Gain）相比简单准确率的优势是什么？

A. NDCG计算速度更快  
B. NDCG考虑了推荐物品的排名位置，排在前列的正确推荐贡献更大  
C. NDCG不需要真实标签即可计算  
D. NDCG只适用于二分类问题  

**正确答案：B**

**详细解释：** NDCG的核心思想是：正确推荐的价值取决于它在列表中的位置。排名第一的正确推荐比排名第十的更有价值，因为用户更可能看到和点击靠前的结果。NDCG通过对排名位置进行折损（discount）来体现这一点，公式中包含log(rank+1)作为分母。这使得NDCG成为评估排序质量的黄金标准。选项A错误，NDCG计算更复杂；选项C错误，NDCG需要真实相关性标签；选项D错误，NDCG可以处理多级相关性。

### 问题4

关于神经协同过滤（NeuMF），以下说法错误的是？

A. NeuMF结合了矩阵分解的线性建模能力和MLP的非线性建模能力  
B. MF分支和MLP分支共享相同的嵌入向量  
C. NeuMF通常比传统矩阵分解表现更好，但训练时间更长  
D. MF分支使用逐元素乘法（Hadamard product）融合用户和物品向量  

**正确答案：B**

**详细解释：** 在标准NeuMF架构中，MF分支和MLP分支使用独立的嵌入向量，而不是共享的。这是因为两个分支学习的是不同类型的特征表示：MF分支学习用于点积的低维向量，MLP分支学习用于拼接和深层网络的高维向量。实验表明，独立嵌入比共享嵌入效果更好。选项A正确，这是NeuMF的设计动机；选项C正确，神经网络需要更多训练时间；选项D正确，MF部分确实使用逐元素乘法。

### 问题5

解决推荐系统冷启动问题的最有效策略组合是？

A. 仅使用热门推荐直到收集足够数据  
B. 结合基于内容的推荐、用户兴趣问卷、探索与利用平衡策略  
C. 等待用户产生足够多的行为数据后再启用推荐  
D. 对所有新用户推荐完全随机的物品  

**正确答案：B**

**详细解释：** 冷启动问题没有单一的完美解决方案，通常需要组合多种策略：基于内容的推荐利用物品属性而非用户行为，可以在零行为数据下工作；用户兴趣问卷快速获取显式偏好；探索与利用平衡（如Bandit算法）在推荐过程中主动收集信息。随着数据积累，系统可以逐渐过渡到更精准的协同过滤或深度学习推荐。选项A过于被动，选项C会导致糟糕的用户体验，选项D完全没有利用任何可用信息。

---

**章节小结**

通过本章学习，你已经掌握了推荐系统的核心技术：从经典的协同过滤和矩阵分解，到现代的神经协同过滤。推荐系统是一个持续演进的领域，最新的趋势包括图神经网络推荐、序列推荐、多任务学习和强化学习推荐。记住，好的推荐系统不仅追求算法精度，更要考虑多样性、新颖性、可解释性和商业目标的平衡。下一章我们将进入时间序列预测领域，学习如何预测未来的趋势和模式。

## 本节知识框架

**课程定位**：分类「ml_practice」· 学习阶段 基础 · 建议用时 50 分钟。

本课主线：实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 推荐系统 | 实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。相关：正文给出可操作定义与适用边界。 |
| 协同过滤 | 实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。相关：正文给出可操作定义与适用边界。 |
| 矩阵分解 | 实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。相关：正文给出可操作定义与适用边界。 |
| NeuMF | 实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。相关：正文给出可操作定义与适用边界。 |
| 冷启动 | 实现协同过滤、矩阵分解和深度学习推荐模型NeuMF。相关：正文给出可操作定义与适用边界。 |

## 原理与运行机制

正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。

## 典型应用场景

- 结合「推荐系统实现」的常见落地场景与选型边界，详见正文各章节的对比讨论。
- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。

## 代码/协议/SQL 示例

正文首个完整示例如下，先运行确认环境，再按正文步骤改一个输入观察输出变化。

```python
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from collections import defaultdict

# ==================== 基于用户的协同过滤 ====================

# 示例用户-物品评分矩阵（行：用户，列：物品）
ratings_matrix = np.array([
    # 物品1  物品2  物品3  物品4  物品5
    [5, 3, 0, 1, 4],   # 用户1
    [4, 0, 0, 1, 5],   # 用户2
    [1, 1, 0, 5, 3],   # 用户3
    [0, 0, 5, 4, 0],   # 用户4
    [5, 4, 4, 0, 0],   # 用户5
    [0, 0, 0, 5, 2]    # 用户6
])

user_ids = ['用户1', '用户2', '用户3', '用户4', '用户5', '用户6']
item_ids = ['物品1', '物品2', '物品3', '物品4', '物品5']

print("用户-物品评分矩阵:")
df_ratings = pd.DataFrame(ratings_matrix, index=user_ids, columns=item_ids)
print(df_ratings)
print(f"\n矩阵稀疏度: {1 - np.count_nonzero(ratings_matrix) / ratings_matrix.size:.2%}")

# 计算用户相似度（余弦相似度）
user_similarity = cosine_similarity(ratings_matrix)
sim_df = pd.DataFrame(user_similarity, index=user_ids, columns=user_ids)
print("\n用户相似度矩阵:")
print(sim_df.round(3))

# 为用户4推荐物品
target_user_idx = 3  # 用户4
target_user_ratings = ratings_matrix[target_user_idx]

# 找出目标用户未评分的物品
unrated_items = np.where(target_user_ratings == 0)[0]
print(f"\n用户4未评分的物品索引: {unrated_items}")

# 预测评分：加权平均相似用户的评分
predicted_scores = {}
for item_idx in unrated_items:
    # 找出对该物品评过分的用户
    rated_users = np.where(ratings_matrix[:, item_idx] > 0)[0]
    rated_users = rated_users[rated_users != target_user_idx]
    
    if len(rated_users) > 0:
        # 获取相似度权重
        similarities = user_similarity[target_user_idx, rated_users]
        ratings = ratings_matrix[rated_users, item_idx]
        
        # 加权平均
        predicted_score = np.dot(similarities, ratings) / np.sum(np.abs(similarities))
        predicted_scores[item_idx] = predicted_score

print("\n用户4的预测评分:")
for item_idx, score in sorted(predicted_scores.items(), key=lambda x: x[1], reverse=True):
    print(f"  {item_ids[item_idx]}: {score:.2f}")

# ==================== 基于物品的协同过滤 ====================

# 计算物品相似度
item_similarity = cosine_similarity(ratings_matrix.T)
item_sim_df = pd.DataFrame(item_similarity, index=item_ids, columns=item_ids)
print("\n物品相似度矩阵:")
print(item_sim_df.round(3))

# 为用户4推荐（基于物品相似度）
def predict_score_item_based(user_idx, item_idx, ratings_mat, item_sim_mat):
    """基于物品的协同过滤预测评分"""
    rated_items = np.where(ratings_mat[user_idx] > 0)[0]
    
    if len(rated_items) == 0:
        return 0
    
    similarities = item_sim_mat[item_idx, rated_items]
    ratings = ratings_mat[user_idx, rated_items]
    
    # 只考虑正相似度
    positive_mask = similarities > 0
    if not np.any(positive_mask):
        return 0
    
    similarities = similarities[positive_mask]
    ratings = ratings[positive_mask]
    
    predicted = np.dot(similarities, ratings) / np.sum(similarities)
    return predicted

print("\n基于物品CF - 用户4的预测评分:")
for item_idx in unrated_items:
    score = predict_score_item_based(target_user_idx, item_idx, ratings_matrix, item_similarity)
    print(f"  {item_ids[item_idx]}: {score:.2f}")
```

## 时间/空间复杂度或性能分析

- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。
- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。

## 常见误区与易错点

| 错误做法 | 典型现象 | 修复方向 |
| --- | --- | --- |
| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |
| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |
| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |

## 与其他知识点的关系

本课与分类「ml_practice」内相邻课程互为补充，建议按清单顺序学完再做综合练习。

## 自测题与参考答案

以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。

## 考点精讲

### 考点 1

关于协同过滤，以下哪项描述是正确的？

A. 基于用户的协同过滤需要知道物品的具体属性（如类别、价格）  
B. 基于物品的协同过滤在物品数量远大于用户数量时计算效率更高 ✅  
C. 协同过滤可以很好地解决冷启动问题  
D. 协同过滤只能用于显式反馈（评分），不能用于隐式反馈（点击、浏览）  

**正确答案：** B

**解析：** 基于物品的协同过滤需要计算物品之间的相似度矩阵，其大小为物品数×物品数。当物品数量远小于用户数量时，这个矩阵相对较小，计算和存储更高效。相反，如果用户数量少而物品数量巨大，基于用户的方法会更高效。选项A错误，协同过滤的优势恰恰是不需要物品属性；选项C错误，冷启动是协同过滤的主要弱点；选项D错误，协同过滤可以适配隐式反馈，只需将二元交互（点击/未点击）视为特殊评分。

### 考点 2

矩阵分解中，隐因子维度（latent dimension）的选择对模型性能有何影响？

A. 维度越高越好，可以捕捉更多细节  
B. 维度越低越好，计算更快且不易过拟合  
C. 需要根据数据规模和稀疏度权衡，通常通过交叉验证选择 ✅  
D. 隐因子维度对模型性能几乎没有影响  

**正确答案：** C

**解析：** 隐因子维度是一个需要仔细调优的超参数。维度太低无法充分表达用户和物品的复杂特征，导致欠拟合；维度太高则会记住训练数据中的噪声，导致过拟合。一般经验法则是：数据量大且稠密时使用较高维度（64-128），数据量小或稀疏时使用较低维度（8-32）。最佳值通常通过交叉验证在验证集上确定。选项A和B都过于绝对，选项D明显错误。

### 考点 3

在推荐系统评估中，NDCG（Normalized Discounted Cumulative Gain）相比简单准确率的优势是什么？

A. NDCG计算速度更快  
B. NDCG考虑了推荐物品的排名位置，排在前列的正确推荐贡献更大 ✅  
C. NDCG不需要真实标签即可计算  
D. NDCG只适用于二分类问题  

**正确答案：** B

**解析：** NDCG的核心思想是：正确推荐的价值取决于它在列表中的位置。排名第一的正确推荐比排名第十的更有价值，因为用户更可能看到和点击靠前的结果。NDCG通过对排名位置进行折损（discount）来体现这一点，公式中包含log(rank+1)作为分母。这使得NDCG成为评估排序质量的黄金标准。选项A错误，NDCG计算更复杂；选项C错误，NDCG需要真实相关性标签；选项D错误，NDCG可以处理多级相关性。

### 考点 4

关于神经协同过滤（NeuMF），以下说法错误的是？

A. NeuMF结合了矩阵分解的线性建模能力和MLP的非线性建模能力  
B. MF分支和MLP分支共享相同的嵌入向量 ✅  
C. NeuMF通常比传统矩阵分解表现更好，但训练时间更长  
D. MF分支使用逐元素乘法（Hadamard product）融合用户和物品向量  

**正确答案：** B

**解析：** 在标准NeuMF架构中，MF分支和MLP分支使用独立的嵌入向量，而不是共享的。这是因为两个分支学习的是不同类型的特征表示：MF分支学习用于点积的低维向量，MLP分支学习用于拼接和深层网络的高维向量。实验表明，独立嵌入比共享嵌入效果更好。选项A正确，这是NeuMF的设计动机；选项C正确，神经网络需要更多训练时间；选项D正确，MF部分确实使用逐元素乘法。

### 考点 5

解决推荐系统冷启动问题的最有效策略组合是？

A. 仅使用热门推荐直到收集足够数据  
B. 结合基于内容的推荐、用户兴趣问卷、探索与利用平衡策略 ✅  
C. 等待用户产生足够多的行为数据后再启用推荐  
D. 对所有新用户推荐完全随机的物品  

**正确答案：** B

**解析：** 冷启动问题没有单一的完美解决方案，通常需要组合多种策略：基于内容的推荐利用物品属性而非用户行为，可以在零行为数据下工作；用户兴趣问卷快速获取显式偏好；探索与利用平衡（如Bandit算法）在推荐过程中主动收集信息。随着数据积累，系统可以逐渐过渡到更精准的协同过滤或深度学习推荐。选项A过于被动，选项C会导致糟糕的用户体验，选项D完全没有利用任何可用信息。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 推荐系统 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 协同过滤 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 矩阵分解 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| NeuMF | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 冷启动 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |

## 参考资料与复核

- [本课资料锚点 ml_recommendation_systems](https://zh.wikipedia.org/w/index.php?search=ml_recommendation_systems)

- 官方/权威资料：[scikit-learn 用户手册](https://scikit-learn.org/stable/user_guide.html)
- 主题延伸：[关于「协同过滤」的检索页](https://zh.wikipedia.org/w/index.php?search=%E5%8D%8F%E5%90%8C%E8%BF%87%E6%BB%A4)
- 本课索引词：[锚点 ml_recommendation_systems](https://scikit-learn.org/stable/user_guide.html#%E6%8E%A8%E8%8D%90%E7%B3%BB%E7%BB%9F)
- 最后复核：2026-10-04
- 下次复核：2026-12-09

## 内容元数据

- 内容更新时间：2026-10-06

- 内容版本：v2.0
- 课程标识：ml_recommendation_systems
- 所属分类：ml_practice
- 学习阶段：基础
- 建议用时：50 分钟
