# 状态管理深入 / State Management Deep Dive

## 章节摘要

状态管理是前端开发中最具挑战性的主题之一。本章将带你深入理解Redux Toolkit、Pinia、NgRx等主流状态管理库的核心概念，掌握actions、reducers、selectors、effects的使用模式。通过对比Context API与专业状态管理方案的适用场景，你将学会判断何时真正需要全局状态，何时应该保持组件本地状态。结合生活化的类比和实战案例，你将建立起清晰的状态管理思维模型，避免过度设计或状态混乱的陷阱。

## 学习目标

完成本章后，你将能够：

- 理解单向数据流和不可变更新的核心原则
- 熟练使用Redux Toolkit创建slice、actions和reducers
- 掌握Pinia模块的定义方法和组合式API集成
- 使用NgRx的effects处理副作用和selectors派生数据
- 对比Context API与专业状态管理方案的性能和适用场景
- 根据应用复杂度判断是否需要引入全局状态管理
- 设计可扩展的状态架构并避免常见反模式

## 核心概念解析

### 为什么状态管理如此重要？

想象你在管理一个大型图书馆。如果每本书都随意摆放，读者找书就像大海捞针。但如果建立了完善的分类系统、索引目录和借阅记录，整个图书馆就能高效运转。

在前端应用中，"状态"就是那些会变化的数据：用户信息、购物车内容、主题设置、表单输入等。随着应用规模增长，状态之间的关系变得复杂，如果没有良好的管理策略，就会出现：
- 数据不同步（购物车显示有商品，结算时却为空）
- 难以追踪bug（不知道哪个组件修改了状态）
- 性能问题（不必要的重新渲染）
- 代码难以维护（状态逻辑分散在各处）

### 单向数据流：状态的单行道

单向数据流是现代状态管理的基石。它的核心理念是：数据只能沿一个方向流动，从状态源到视图，从视图触发动作，动作更新状态，状态再驱动视图。

这就像城市的交通系统——所有车辆都遵循相同的行驶方向，不会逆行造成混乱。在React中，这个流程是：
1. **State**：当前应用状态
2. **View**：根据状态渲染UI
3. **Actions**：用户交互触发事件
4. **Reducer**：根据action计算新状态
5. 回到步骤1

这种循环确保了状态变化的可预测性和可追踪性。

### Redux Toolkit：现代化的Redux体验

Redux曾经是状态管理的代名词，但早期的Redux样板代码过多，学习曲线陡峭。Redux Toolkit（RTK）是官方推荐的现代Redux写法，它简化了配置，内置了最佳实践。

核心概念：
- **Store**：全局状态容器，整个应用只有一个
- **Slice**：状态的一个片段，包含初始状态、reducers和actions
- **Action**：描述"发生了什么"的普通对象
- **Reducer**：纯函数，根据action和当前状态计算新状态
- **Selector**：从store中提取特定数据的函数

可以把Redux Toolkit想象成快递系统：
- Store是中央仓库
- Action是订单请求
- Reducer是分拣员，根据订单更新库存
- Selector是查询接口，告诉你仓库里有什么

关键优势：
- 内置Immer支持，可以直接"修改"状态（实际是不可变更新）
- 自动生成action creators
- 集成了Redux DevTools调试工具
- 减少了90%的样板代码

### Pinia：Vue 3的官方状态管理

Pinia是Vue团队推荐的状态管理方案，取代了Vuex。它的设计更简洁，与Composition API完美集成。

核心概念：
- **Store**：定义状态的模块，可以创建多个
- **State**：响应式数据
- **Getters**：类似computed属性，派生状态
- **Actions**：异步操作和业务逻辑

Pinia的优势：
- 无需mutation，直接修改state（基于Vue的响应式系统）
- TypeScript支持优秀
- 模块化设计，每个store独立
- 体积小巧（~1KB）

### NgRx：Angular的企业级方案

NgRx是Angular生态中的Redux实现，严格遵循函数式编程原则。它引入了更多概念，但也提供了更强的类型安全和可测试性。

核心概念：
- **Store**：不可变状态树
- **Action**：类型安全的action定义
- **Reducer**：纯函数处理状态转换
- **Selector**：记忆化选择器，优化性能
- **Effect**：处理副作用（API调用、日志等）
- **Entity**：规范化数据结构的管理工具

NgRx适合大型Angular应用，特别是需要严格架构规范的团队。

### Context API vs 专业状态管理

React的Context API常被误认为是状态管理方案，但它本质上只是props钻取的替代方案。

**Context API的特点：**
- 内置于React，无需额外依赖
- 适合低频更新的全局数据（主题、语言、用户信息）
- 任何context值变化都会导致所有消费者重新渲染
- 没有内置的状态更新逻辑

**专业状态管理的特点：**
- 精细的订阅机制，只更新需要的组件
- 内置中间件支持（日志、持久化、撤销重做）
- 强大的调试工具
- 更好的TypeScript支持

**何时使用Context API：**
- 简单的全局配置（主题、语言）
- 低频更新的数据
- 小型应用或原型开发

**何时使用专业状态管理：**
- 频繁更新的全局状态
- 复杂的状态转换逻辑
- 需要时间旅行调试
- 大型团队协作

### 你真的需要全局状态吗？

这是最重要的问题。很多开发者过早引入Redux/Pinia，导致不必要的复杂性。

**不需要全局状态的信号：**
- 状态只在单个组件中使用
- 父子组件通过props传递即可
- 应用规模小（<10个页面）
- 没有跨页面的共享数据

**需要全局状态的信号：**
- 多个不相关组件需要访问同一数据
- 用户会话信息（登录状态、权限）
- 购物车、收藏夹等业务数据
- 需要持久化到服务器或localStorage
- 复杂的状态转换逻辑

记住：优先使用组件本地状态，只有在确实需要时才提升到全局。

## 渐进式代码示例

### 最小示例：Redux Toolkit基础

让我们从一个简单的计数器开始，展示Redux Toolkit的基本用法。

```javascript
// features/counter/counterSlice.js
import { createSlice } from '@reduxjs/toolkit';

const counterSlice = createSlice({
  name: 'counter',
  initialState: {
    value: 0
  },
  reducers: {
    increment: (state) => {
      // Redux Toolkit使用Immer，可以直接"修改"状态
      state.value += 1;
    },
    decrement: (state) => {
      state.value -= 1;
    },
    incrementByAmount: (state, action) => {
      state.value += action.payload;
    }
  }
});

// 自动生成的action creators
export const { increment, decrement, incrementByAmount } = counterSlice.actions;

// selector用于从state中提取数据
export const selectCount = (state) => state.counter.value;

export default counterSlice.reducer;
```

配置store：

```javascript
// app/store.js
import { configureStore } from '@reduxjs/toolkit';
import counterReducer from '../features/counter/counterSlice';

export const store = configureStore({
  reducer: {
    counter: counterReducer
  }
});
```

在React组件中使用：

```jsx
// Counter.jsx
import { useSelector, useDispatch } from 'react-redux';
import { increment, decrement, incrementByAmount, selectCount } from './counterSlice';

function Counter() {
  const count = useSelector(selectCount);
  const dispatch = useDispatch();
  
  return (
    <div>
      <h2>计数器：{count}</h2>
      <button onClick={() => dispatch(increment())}>+1</button>
      <button onClick={() => dispatch(decrement())}>-1</button>
      <button onClick={() => dispatch(incrementByAmount(5))}>+5</button>
    </div>
  );
}

export default Counter;
```

在主应用中包裹Provider：

```jsx
// App.jsx
import { Provider } from 'react-redux';
import { store } from './app/store';
import Counter from './features/counter/Counter';

function App() {
  return (
    <Provider store={store}>
      <Counter />
    </Provider>
  );
}

export default App;
```

这个示例展示了Redux Toolkit的核心流程：定义slice → 配置store → 在组件中dispatch actions和select state。

### 完整示例：电商购物车系统

现在让我们构建一个真实的购物车系统，展示Redux Toolkit处理复杂状态的能力。

```javascript
// features/cart/cartSlice.js
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

// 异步thunk：从API获取购物车
export const fetchCart = createAsyncThunk(
  'cart/fetchCart',
  async (userId, { rejectWithValue }) => {
    try {
      const response = await fetch(`/api/cart/${userId}`);
      if (!response.ok) throw new Error('Failed to fetch cart');
      return await response.json();
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

// 异步thunk：添加商品到购物车
export const addToCart = createAsyncThunk(
  'cart/addToCart',
  async ({ userId, productId, quantity = 1 }, { rejectWithValue }) => {
    try {
      const response = await fetch('/api/cart/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, productId, quantity })
      });
      
      if (!response.ok) throw new Error('Failed to add item');
      return await response.json();
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

// 异步thunk：更新商品数量
export const updateQuantity = createAsyncThunk(
  'cart/updateQuantity',
  async ({ userId, itemId, quantity }, { rejectWithValue }) => {
    try {
      const response = await fetch(`/api/cart/items/${itemId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, quantity })
      });
      
      if (!response.ok) throw new Error('Failed to update quantity');
      return await response.json();
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

// 异步thunk：移除商品
export const removeFromCart = createAsyncThunk(
  'cart/removeFromCart',
  async ({ userId, itemId }, { rejectWithValue }) => {
    try {
      const response = await fetch(`/api/cart/items/${itemId}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId })
      });
      
      if (!response.ok) throw new Error('Failed to remove item');
      return itemId;
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

const cartSlice = createSlice({
  name: 'cart',
  initialState: {
    items: [],
    status: 'idle', // 'idle' | 'loading' | 'succeeded' | 'failed'
    error: null,
    lastUpdated: null
  },
  reducers: {
    clearCart: (state) => {
      state.items = [];
      state.lastUpdated = new Date().toISOString();
    }
  },
  extraReducers: (builder) => {
    builder
      // Fetch cart
      .addCase(fetchCart.pending, (state) => {
        state.status = 'loading';
      })
      .addCase(fetchCart.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.items = action.payload.items;
        state.lastUpdated = new Date().toISOString();
      })
      .addCase(fetchCart.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.payload;
      })
      
      // Add to cart
      .addCase(addToCart.fulfilled, (state, action) => {
        const existingItem = state.items.find(
          item => item.productId === action.payload.productId
        );
        
        if (existingItem) {
          existingItem.quantity += action.payload.quantity;
        } else {
          state.items.push(action.payload);
        }
        
        state.lastUpdated = new Date().toISOString();
      })
      
      // Update quantity
      .addCase(updateQuantity.fulfilled, (state, action) => {
        const item = state.items.find(item => item.id === action.payload.id);
        if (item) {
          item.quantity = action.payload.quantity;
        }
        state.lastUpdated = new Date().toISOString();
      })
      
      // Remove from cart
      .addCase(removeFromCart.fulfilled, (state, action) => {
        state.items = state.items.filter(item => item.id !== action.payload);
        state.lastUpdated = new Date().toISOString();
      });
  }
});

export const { clearCart } = cartSlice.actions;

// Selectors
export const selectCartItems = (state) => state.cart.items;
export const selectCartStatus = (state) => state.cart.status;
export const selectCartError = (state) => state.cart.error;

// 派生selector：计算总价
export const selectCartTotal = (state) => {
  return state.cart.items.reduce((total, item) => {
    return total + item.price * item.quantity;
  }, 0);
};

// 派生selector：计算商品总数
export const selectCartItemCount = (state) => {
  return state.cart.items.reduce((count, item) => {
    return count + item.quantity;
  }, 0);
};

export default cartSlice.reducer;
```

配置store并添加多个slice：

```javascript
// app/store.js
import { configureStore } from '@reduxjs/toolkit';
import cartReducer from '../features/cart/cartSlice';
import userReducer from '../features/user/userSlice';
import productsReducer from '../features/products/productsSlice';

export const store = configureStore({
  reducer: {
    cart: cartReducer,
    user: userReducer,
    products: productsReducer
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        // 忽略某些不可序列化的字段（如Date对象）
        ignoredActions: ['cart/fetchCart/fulfilled'],
        ignoredPaths: ['cart.lastUpdated']
      }
    })
});
```

购物车组件：

```jsx
// Cart.jsx
import { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import {
  fetchCart,
  updateQuantity,
  removeFromCart,
  clearCart,
  selectCartItems,
  selectCartStatus,
  selectCartError,
  selectCartTotal,
  selectCartItemCount
} from './cartSlice';

function Cart({ userId }) {
  const dispatch = useDispatch();
  const items = useSelector(selectCartItems);
  const status = useSelector(selectCartStatus);
  const error = useSelector(selectCartError);
  const total = useSelector(selectCartTotal);
  const itemCount = useSelector(selectCartItemCount);
  
  // 组件挂载时获取购物车数据
  useEffect(() => {
    if (userId) {
      dispatch(fetchCart(userId));
    }
  }, [dispatch, userId]);
  
  const handleQuantityChange = (itemId, newQuantity) => {
    if (newQuantity < 1) {
      dispatch(removeFromCart({ userId, itemId }));
    } else {
      dispatch(updateQuantity({ userId, itemId, quantity: newQuantity }));
    }
  };
  
  const handleRemove = (itemId) => {
    dispatch(removeFromCart({ userId, itemId }));
  };
  
  const handleClear = () => {
    if (window.confirm('确定要清空购物车吗？')) {
      dispatch(clearCart());
    }
  };
  
  if (status === 'loading') {
    return <div className="cart-loading">加载中...</div>;
  }
  
  if (status === 'failed') {
    return (
      <div className="cart-error">
        <p>加载失败：{error}</p>
        <button onClick={() => dispatch(fetchCart(userId))}>重试</button>
      </div>
    );
  }
  
  if (items.length === 0) {
    return (
      <div className="cart-empty">
        <p>购物车是空的</p>
        <a href="/products">去购物</a>
      </div>
    );
  }
  
  return (
    <div className="cart">
      <h2>购物车 ({itemCount}件商品)</h2>
      
      <div className="cart-items">
        {items.map(item => (
          <div key={item.id} className="cart-item">
            <img src={item.image} alt={item.name} />
            
            <div className="item-details">
              <h3>{item.name}</h3>
              <p className="price">¥{item.price.toFixed(2)}</p>
            </div>
            
            <div className="quantity-controls">
              <button
                onClick={() => handleQuantityChange(item.id, item.quantity - 1)}
              >
                -
              </button>
              <span>{item.quantity}</span>
              <button
                onClick={() => handleQuantityChange(item.id, item.quantity + 1)}
              >
                +
              </button>
            </div>
            
            <p className="subtotal">
              ¥{(item.price * item.quantity).toFixed(2)}
            </p>
            
            <button
              className="remove-btn"
              onClick={() => handleRemove(item.id)}
            >
              删除
            </button>
          </div>
        ))}
      </div>
      
      <div className="cart-summary">
        <div className="total">
          <span>总计：</span>
          <span className="amount">¥{total.toFixed(2)}</span>
        </div>
        
        <div className="actions">
          <button className="clear-btn" onClick={handleClear}>
            清空购物车
          </button>
          <button className="checkout-btn">
            去结算
          </button>
        </div>
      </div>
    </div>
  );
}

export default Cart;
```

这个示例展示了：
- 异步thunk处理API调用
- extraReducers处理异步action的不同状态
- 派生selectors计算总价和数量
- 完整的CRUD操作
- 错误处理和加载状态

### 进阶示例：Pinia模块化状态管理

让我们用Pinia重构上述购物车系统，展示Vue 3的状态管理模式。

```javascript
// stores/cart.js
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

export const useCartStore = defineStore('cart', () => {
  // State
  const items = ref([]);
  const status = ref('idle');
  const error = ref(null);
  const lastUpdated = ref(null);
  
  // Getters（派生状态）
  const total = computed(() => {
    return items.value.reduce((sum, item) => {
      return sum + item.price * item.quantity;
    }, 0);
  });
  
  const itemCount = computed(() => {
    return items.value.reduce((count, item) => {
      return count + item.quantity;
    }, 0);
  });
  
  const isEmpty = computed(() => items.value.length === 0);
  
  // Actions
  async function fetchCart(userId) {
    status.value = 'loading';
    error.value = null;
    
    try {
      const response = await fetch(`/api/cart/${userId}`);
      if (!response.ok) throw new Error('Failed to fetch cart');
      
      const data = await response.json();
      items.value = data.items;
      lastUpdated.value = new Date().toISOString();
      status.value = 'succeeded';
    } catch (err) {
      error.value = err.message;
      status.value = 'failed';
    }
  }
  
  async function addToCart({ userId, productId, quantity = 1 }) {
    try {
      const response = await fetch('/api/cart/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, productId, quantity })
      });
      
      if (!response.ok) throw new Error('Failed to add item');
      
      const newItem = await response.json();
      
      const existingItem = items.value.find(
        item => item.productId === productId
      );
      
      if (existingItem) {
        existingItem.quantity += quantity;
      } else {
        items.value.push(newItem);
      }
      
      lastUpdated.value = new Date().toISOString();
    } catch (err) {
      throw new Error(err.message);
    }
  }
  
  async function updateQuantity({ userId, itemId, quantity }) {
    try {
      const response = await fetch(`/api/cart/items/${itemId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, quantity })
      });
      
      if (!response.ok) throw new Error('Failed to update quantity');
      
      const item = items.value.find(item => item.id === itemId);
      if (item) {
        item.quantity = quantity;
      }
      
      lastUpdated.value = new Date().toISOString();
    } catch (err) {
      throw new Error(err.message);
    }
  }
  
  async function removeFromCart({ userId, itemId }) {
    try {
      const response = await fetch(`/api/cart/items/${itemId}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId })
      });
      
      if (!response.ok) throw new Error('Failed to remove item');
      
      const index = items.value.findIndex(item => item.id === itemId);
      if (index !== -1) {
        items.value.splice(index, 1);
      }
      
      lastUpdated.value = new Date().toISOString();
    } catch (err) {
      throw new Error(err.message);
    }
  }
  
  function clearCart() {
    items.value = [];
    lastUpdated.value = new Date().toISOString();
  }
  
  return {
    items,
    status,
    error,
    lastUpdated,
    total,
    itemCount,
    isEmpty,
    fetchCart,
    addToCart,
    updateQuantity,
    removeFromCart,
    clearCart
  };
});
```

在Vue组件中使用：

```vue
<!-- Cart.vue -->
<template>
  <div class="cart">
    <h2>购物车 ({{ cartStore.itemCount }}件商品)</h2>
    
    <div v-if="cartStore.status === 'loading'" class="cart-loading">
      加载中...
    </div>
    
    <div v-else-if="cartStore.status === 'failed'" class="cart-error">
      <p>加载失败：{{ cartStore.error }}</p>
      <button @click="cartStore.fetchCart(userId)">重试</button>
    </div>
    
    <div v-else-if="cartStore.isEmpty" class="cart-empty">
      <p>购物车是空的</p>
      <router-link to="/products">去购物</router-link>
    </div>
    
    <template v-else>
      <div class="cart-items">
        <div
          v-for="item in cartStore.items"
          :key="item.id"
          class="cart-item"
        >
          <img :src="item.image" :alt="item.name" />
          
          <div class="item-details">
            <h3>{{ item.name }}</h3>
            <p class="price">¥{{ item.price.toFixed(2) }}</p>
          </div>
          
          <div class="quantity-controls">
            <button @click="updateQuantity(item.id, item.quantity - 1)">-</button>
            <span>{{ item.quantity }}</span>
            <button @click="updateQuantity(item.id, item.quantity + 1)">+</button>
          </div>
          
          <p class="subtotal">
            ¥{{ (item.price * item.quantity).toFixed(2) }}
          </p>
          
          <button
            class="remove-btn"
            @click="cartStore.removeFromCart({ userId, itemId: item.id })"
          >
            删除
          </button>
        </div>
      </div>
      
      <div class="cart-summary">
        <div class="total">
          <span>总计：</span>
          <span class="amount">¥{{ cartStore.total.toFixed(2) }}</span>
        </div>
        
        <div class="actions">
          <button class="clear-btn" @click="handleClear">
            清空购物车
          </button>
          <button class="checkout-btn">
            去结算
          </button>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useCartStore } from '@/stores/cart';

const props = defineProps({
  userId: {
    type: String,
    required: true
  }
});

const cartStore = useCartStore();

onMounted(() => {
  cartStore.fetchCart(props.userId);
});

async function updateQuantity(itemId, newQuantity) {
  if (newQuantity < 1) {
    await cartStore.removeFromCart({
      userId: props.userId,
      itemId
    });
  } else {
    await cartStore.updateQuantity({
      userId: props.userId,
      itemId,
      quantity: newQuantity
    });
  }
}

function handleClear() {
  if (confirm('确定要清空购物车吗？')) {
    cartStore.clearCart();
  }
}
</script>
```

Pinia的优势在这个示例中体现得很明显：
- 更简洁的语法，无需区分actions和mutations
- 直接使用ref和computed，符合Vue开发习惯
- TypeScript推断更准确
- 可以直接解构store（虽然这里为了保持响应式没有这样做）

### 实战示例：NgRx企业级状态管理

最后，让我们看看Angular中如何使用NgRx构建相同的功能。

```typescript
// cart.actions.ts
import { createAction, props } from '@ngrx/store';
import { CartItem } from './cart.models';

export const fetchCart = createAction(
  '[Cart] Fetch Cart',
  props<{ userId: string }>()
);

export const fetchCartSuccess = createAction(
  '[Cart] Fetch Cart Success',
  props<{ items: CartItem[] }>()
);

export const fetchCartFailure = createAction(
  '[Cart] Fetch Cart Failure',
  props<{ error: string }>()
);

export const addToCart = createAction(
  '[Cart] Add To Cart',
  props<{ userId: string; productId: string; quantity?: number }>()
);

export const addToCartSuccess = createAction(
  '[Cart] Add To Cart Success',
  props<{ item: CartItem }>()
);

export const updateQuantity = createAction(
  '[Cart] Update Quantity',
  props<{ userId: string; itemId: string; quantity: number }>()
);

export const removeFromCart = createAction(
  '[Cart] Remove From Cart',
  props<{ userId: string; itemId: string }>()
);

export const clearCart = createAction('[Cart] Clear Cart');
```

```typescript
// cart.reducer.ts
import { createReducer, on } from '@ngrx/store';
import * as CartActions from './cart.actions';
import { CartState } from './cart.models';

export const initialState: CartState = {
  items: [],
  status: 'idle',
  error: null,
  lastUpdated: null
};

export const cartReducer = createReducer(
  initialState,
  on(CartActions.fetchCart, (state) => ({
    ...state,
    status: 'loading' as const
  })),
  on(CartActions.fetchCartSuccess, (state, { items }) => ({
    ...state,
    items,
    status: 'succeeded' as const,
    lastUpdated: new Date().toISOString()
  })),
  on(CartActions.fetchCartFailure, (state, { error }) => ({
    ...state,
    status: 'failed' as const,
    error
  })),
  on(CartActions.addToCartSuccess, (state, { item }) => {
    const existingItem = state.items.find(
      i => i.productId === item.productId
    );
    
    let updatedItems;
    if (existingItem) {
      updatedItems = state.items.map(i =>
        i.productId === item.productId
          ? { ...i, quantity: i.quantity + item.quantity }
          : i
      );
    } else {
      updatedItems = [...state.items, item];
    }
    
    return {
      ...state,
      items: updatedItems,
      lastUpdated: new Date().toISOString()
    };
  }),
  on(CartActions.removeFromCart, (state, { itemId }) => ({
    ...state,
    items: state.items.filter(item => item.id !== itemId),
    lastUpdated: new Date().toISOString()
  })),
  on(CartActions.clearCart, (state) => ({
    ...state,
    items: [],
    lastUpdated: new Date().toISOString()
  }))
);
```

```typescript
// cart.effects.ts
import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { catchError, map, mergeMap, switchMap } from 'rxjs/operators';
import { of } from 'rxjs';
import { CartService } from './cart.service';
import * as CartActions from './cart.actions';

@Injectable()
export class CartEffects {
  fetchCart$ = createEffect(() =>
    this.actions$.pipe(
      ofType(CartActions.fetchCart),
      mergeMap(({ userId }) =>
        this.cartService.getCart(userId).pipe(
          map(items => CartActions.fetchCartSuccess({ items })),
          catchError(error =>
            of(CartActions.fetchCartFailure({ error: error.message }))
          )
        )
      )
    )
  );
  
  addToCart$ = createEffect(() =>
    this.actions$.pipe(
      ofType(CartActions.addToCart),
      mergeMap(({ userId, productId, quantity }) =>
        this.cartService.addToCart({ userId, productId, quantity }).pipe(
          map(item => CartActions.addToCartSuccess({ item })),
          catchError(error =>
            of(CartActions.fetchCartFailure({ error: error.message }))
          )
        )
      )
    )
  );
  
  constructor(
    private actions$: Actions,
    private cartService: CartService
  ) {}
}
```

```typescript
// cart.selectors.ts
import { createFeatureSelector, createSelector } from '@ngrx/store';
import { CartState } from './cart.models';

export const selectCartState = createFeatureSelector<CartState>('cart');

export const selectCartItems = createSelector(
  selectCartState,
  (state: CartState) => state.items
);

export const selectCartStatus = createSelector(
  selectCartState,
  (state: CartState) => state.status
);

export const selectCartError = createSelector(
  selectCartState,
  (state: CartState) => state.error
);

export const selectCartTotal = createSelector(
  selectCartItems,
  (items) => items.reduce((total, item) => total + item.price * item.quantity, 0)
);

export const selectCartItemCount = createSelector(
  selectCartItems,
  (items) => items.reduce((count, item) => count + item.quantity, 0)
);
```

在Angular组件中使用：

```typescript
// cart.component.ts
import { Component, OnInit, Input } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable } from 'rxjs';
import * as CartActions from './cart.actions';
import * as CartSelectors from './cart.selectors';
import { CartItem } from './cart.models';

@Component({
  selector: 'app-cart',
  template: `
    <div class="cart">
      <h2>购物车 ({{ itemCount$ | async }}件商品)</h2>
      
      <ng-container *ngIf="status$ | async as status">
        <div *ngIf="status === 'loading'" class="cart-loading">
          加载中...
        </div>
        
        <div *ngIf="status === 'failed'" class="cart-error">
          <p>加载失败：{{ error$ | async }}</p>
          <button (click)="loadCart()">重试</button>
        </div>
        
        <div *ngIf="status === 'succeeded' && (items$ | async)?.length === 0" 
             class="cart-empty">
          <p>购物车是空的</p>
          <a routerLink="/products">去购物</a>
        </div>
        
        <ng-container *ngIf="status === 'succeeded' && (items$ | async)?.length > 0">
          <div class="cart-items">
            <div *ngFor="let item of items$ | async" class="cart-item">
              <img [src]="item.image" [alt]="item.name" />
              
              <div class="item-details">
                <h3>{{ item.name }}</h3>
                <p class="price">¥{{ item.price | number:'1.2-2' }}</p>
              </div>
              
              <div class="quantity-controls">
                <button (click)="updateQuantity(item.id, item.quantity - 1)">-</button>
                <span>{{ item.quantity }}</span>
                <button (click)="updateQuantity(item.id, item.quantity + 1)">+</button>
              </div>
              
              <p class="subtotal">
                ¥{{ (item.price * item.quantity) | number:'1.2-2' }}
              </p>
              
              <button
                class="remove-btn"
                (click)="removeItem(item.id)"
              >
                删除
              </button>
            </div>
          </div>
          
          <div class="cart-summary">
            <div class="total">
              <span>总计：</span>
              <span class="amount">¥{{ total$ | async | number:'1.2-2' }}</span>
            </div>
            
            <div class="actions">
              <button class="clear-btn" (click)="clearCart()">
                清空购物车
              </button>
              <button class="checkout-btn">
                去结算
              </button>
            </div>
          </div>
        </ng-container>
      </ng-container>
    </div>
  `
})
export class CartComponent implements OnInit {
  @Input() userId!: string;
  
  items$: Observable<CartItem[]>;
  status$: Observable<string>;
  error$: Observable<string | null>;
  total$: Observable<number>;
  itemCount$: Observable<number>;
  
  constructor(private store: Store) {
    this.items$ = this.store.select(CartSelectors.selectCartItems);
    this.status$ = this.store.select(CartSelectors.selectCartStatus);
    this.error$ = this.store.select(CartSelectors.selectCartError);
    this.total$ = this.store.select(CartSelectors.selectCartTotal);
    this.itemCount$ = this.store.select(CartSelectors.selectCartItemCount);
  }
  
  ngOnInit(): void {
    this.loadCart();
  }
  
  loadCart(): void {
    this.store.dispatch(CartActions.fetchCart({ userId: this.userId }));
  }
  
  updateQuantity(itemId: string, quantity: number): void {
    if (quantity < 1) {
      this.removeItem(itemId);
    } else {
      this.store.dispatch(CartActions.updateQuantity({
        userId: this.userId,
        itemId,
        quantity
      }));
    }
  }
  
  removeItem(itemId: string): void {
    this.store.dispatch(CartActions.removeFromCart({
      userId: this.userId,
      itemId
    }));
  }
  
  clearCart(): void {
    if (confirm('确定要清空购物车吗？')) {
      this.store.dispatch(CartActions.clearCart());
    }
  }
}
```

NgRx的特点在这个示例中很明显：
- 严格的类型安全
- Action、Reducer、Effect、Selector分离，职责清晰
- Effects专门处理副作用，保持reducer纯净
- Selectors提供记忆化，优化性能
- 适合大型团队和长期维护的项目

### 综合示例：何时不使用全局状态

最后，让我们看一个反例——展示如何正确地使用局部状态而非全局状态。

```jsx
// GoodExample.jsx - 正确的局部状态使用
import { useState } from 'react';

function SearchBar({ onSearch }) {
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  
  const handleSubmit = (e) => {
    e.preventDefault();
    onSearch(query);
    setIsOpen(false);
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onFocus={() => setIsOpen(true)}
        onBlur={() => setTimeout(() => setIsOpen(false), 200)}
        placeholder="搜索..."
      />
      {isOpen && query && (
        <div className="search-suggestions">
          {/* 建议列表 */}
        </div>
      )}
    </form>
  );
}

function ProductList({ products }) {
  const [sortBy, setSortBy] = useState('name');
  const [filterCategory, setFilterCategory] = useState('all');
  
  // 这些状态只在当前组件使用，不需要全局化
  const filteredProducts = products
    .filter(p => filterCategory === 'all' || p.category === filterCategory)
    .sort((a, b) => {
      if (sortBy === 'name') return a.name.localeCompare(b.name);
      if (sortBy === 'price') return a.price - b.price;
      return 0;
    });
  
  return (
    <div>
      <div className="filters">
        <select value={filterCategory} onChange={(e) => setFilterCategory(e.target.value)}>
          <option value="all">全部</option>
          <option value="electronics">电子产品</option>
        </select>
        
        <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
          <option value="name">按名称</option>
          <option value="price">按价格</option>
        </select>
      </div>
      
      <div className="product-grid">
        {filteredProducts.map(product => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </div>
  );
}

// 只有真正需要共享的数据才放到全局状态
// 比如：用户登录状态、购物车、主题设置
```

这个示例展示了良好的状态管理实践：
- 搜索框的状态（query、isOpen）只在组件内部使用
- 排序和过滤状态也保持在局部
- 只有跨组件共享的数据（如用户信息、购物车）才应该放入全局store

## 常见陷阱对照表

| 陷阱 | 表现 | 解决方案 |
|------|------|----------|
| 过早引入全局状态 | 简单应用变得复杂 | 先用局部状态，确有需要再提升 |
| 将所有状态放入Redux | store臃肿，难以维护 | 只放真正需要全局访问的状态 |
| 在reducer中执行副作用 | 违反纯函数原则 | 使用thunk/saga/effect处理异步 |
| 直接修改state对象 | 状态更新不触发渲染 | 使用不可变更新或Immer |
| 忘记清理selector订阅 | 内存泄漏 | 使用useSelector自动清理 |
| 过度嵌套的state结构 | selector复杂，性能差 | 扁平化state，使用normalize |
| Context API高频更新 | 所有消费者都重新渲染 | 拆分context或使用专业状态管理 |

## 自测题目

### 问题1

关于Redux Toolkit的createSlice，以下说法正确的是？

A. 必须手动编写action types字符串  
B. reducers中可以安全地直接修改state  
C. 不支持异步action  
D. 必须单独定义action creators  

**正确答案：B**

**详细解释：** Redux Toolkit内置了Immer库，允许在reducers中直接"修改"state（如`state.value += 1`），Immer会在底层生成不可变更新。这是RTK相比传统Redux的最大改进之一。选项A错误，RTK自动生成action types。选项C错误，可以通过extraReducers配合createAsyncThunk处理异步。选项D错误，RTK自动生成action creators。

---

### 问题2

关于Pinia和Vuex的主要区别，以下说法错误的是？

A. Pinia移除了mutations，直接在actions中修改state  
B. Pinia对TypeScript的支持更好  
C. Pinia必须使用Composition API  
D. Pinia的包体积更小  

**正确答案：C**

**详细解释：** Pinia既支持Composition API（defineStore返回函数），也支持Options API（defineStore传入对象）。它并不强制使用Composition API。选项A正确，这是Pinia相比Vuex的主要简化。选项B正确，Pinia的TS推断更准确。选项D正确，Pinia约1KB，比Vuex小。

---

### 问题3

在什么情况下应该使用Context API而非Redux/Pinia？

A. 购物车数据需要在多个页面间共享  
B. 用户登录状态需要持久化  
C. 主题切换（深色/浅色模式）  
D. 复杂的表单状态管理  

**正确答案：C**

**详细解释：** 主题切换是低频更新的全局配置，非常适合使用Context API。它不需要复杂的更新逻辑，变化频率低，不会造成性能问题。选项A和B涉及频繁更新和业务逻辑，应该使用专业状态管理。选项D的表单状态通常应该保持在局部组件或使用专门的表单库（如Formik、React Hook Form），而非全局状态。

---

### 问题4

关于NgRx的Effects，以下说法正确的是？

A. Effects用于处理纯状态转换逻辑  
B. Effects可以直接修改store  
C. Effects用于处理副作用，如API调用  
D. 每个action都必须有对应的Effect  

**正确答案：C**

**详细解释：** Effects是NgRx中专门处理副作用的机制，如HTTP请求、路由导航、日志记录等。它们监听actions，执行副作用，然后dispatch新的actions。选项A错误，纯状态转换应该在reducer中处理。选项B错误，只有reducer可以修改state。选项D错误，只有需要处理副作用的action才需要Effect，纯同步action不需要。

---

### 问题5

以下哪种做法违反了Redux的最佳实践？

A. 在component中dispatch action  
B. 在reducer中调用API获取数据  
C. 使用selector从store提取数据  
D. 将related状态组织在一个slice中  

**正确答案：B**

**详细解释：** Reducer必须是纯函数——给定相同的输入，总是返回相同的输出，且不能有副作用。在reducer中调用API违反了这一原则，会导致不可预测的行为和测试困难。正确的做法是使用thunk（Redux）、action（Pinia）或effect（NgRx）来处理异步操作。选项A、C、D都是Redux推荐的最佳实践。
