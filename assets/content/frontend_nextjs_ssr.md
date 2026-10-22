# Next.js服务端渲染 / Next.js Server-Side Rendering

## 章节摘要

Next.js是React生态中最流行的全栈框架，它让服务端渲染变得简单而强大。本章将带你深入理解SSR、CSR和SSG的区别，掌握getServerSideProps和getStaticProps的核心用法，探索现代化的App Router架构，学习如何构建API路由以及优化图片加载。通过实际案例和生活类比，你将学会如何选择最适合的渲染策略，构建高性能的Next.js应用。

## 学习目标

完成本章后，你将能够：

- 理解SSR、CSR和SSG三种渲染模式的工作原理和适用场景
- 熟练使用getServerSideProps和getStaticProps进行数据预取
- 掌握App Router的路由布局和嵌套路由机制
- 创建RESTful API路由处理后端逻辑
- 使用Next.js Image组件优化图片加载性能
- 根据业务需求选择合适的渲染策略

## 核心概念解析

### 渲染模式大比拼：SSR vs CSR vs SSG

想象你在餐厅点餐，有三种不同的服务模式：

**CSR（客户端渲染）**就像自助餐厅。你拿到菜单后，需要自己去各个窗口取食材、自己烹饪、最后组装成完整的菜品。在Web开发中，浏览器先下载一个空的HTML骨架，然后用JavaScript动态生成内容。优点是交互流畅，缺点是首屏加载慢，SEO不友好。

**SSR（服务端渲染）**就像传统餐厅。厨师在后厨做好整道菜再端给你。服务器预先渲染好完整的HTML发送给浏览器，用户能立即看到内容。优点是首屏快、SEO友好，缺点是每次请求都要重新渲染，服务器压力大。

**SSG（静态站点生成）**就像预制菜。提前把菜做好冷藏起来，顾客来了直接加热就能吃。构建时生成所有HTML文件，部署到CDN。优点是速度极快、成本低，缺点是数据更新不及时，不适合频繁变化的内容。

Next.js的强大之处在于，你可以在同一个应用中混合使用这三种策略，为不同页面选择最优方案。

### getServerSideProps：实时数据的守护者

`getServerSideProps`是Next.js提供的服务端数据获取方法。它在每次请求时在服务器上执行，确保你拿到的是最新数据。

可以把这想象成新闻网站——每条新闻都需要展示最新的内容，不能缓存。当用户访问页面时，Next.js会在服务器上调用这个函数，获取数据后再渲染HTML。

关键特点：
- 每次请求都执行，保证数据新鲜度
- 运行在服务端，可以安全地访问数据库和API密钥
- 会略微增加响应时间，因为要等待数据获取完成

### getStaticProps：预生成的加速器

`getStaticProps`在构建时执行一次，生成静态HTML文件。适合内容不经常变化的页面，比如博客文章、产品文档。

这就像印刷杂志——编辑排版完成后批量印刷，读者拿到的是固定版本。如果需要更新内容，就得重新印刷下一期。

关键特点：
- 构建时执行，运行时直接使用生成的HTML
- 速度极快，可以直接从CDN分发
- 配合ISR（增量静态再生）可以实现定时更新

### App Router：现代化的路由系统

Next.js 13引入的App Router是基于React Server Components的新架构。它用文件夹结构定义路由，提供了更强大的布局系统和流式渲染能力。

传统Pages Router像是一栋平层建筑，每个房间独立存在。App Router则像是一座多层别墅，有公共区域（layout）、独立房间（page）和连接通道（loading/error）。

核心概念：
- **Layout**：共享的UI结构，导航切换时保持状态
- **Page**：具体的页面内容
- **Loading**：加载状态的占位符
- **Error**：错误处理的边界

### API Routes：内置的后端服务

Next.js允许你在项目中直接创建API端点，无需单独搭建后端服务器。这就像在餐厅里增设了外卖窗口，顾客可以直接从这里下单。

API路由文件放在`pages/api`或`app/api`目录下，自动映射到`/api/*`路径。你可以用它处理表单提交、数据库操作、第三方API代理等任务。

### Image Optimization：智能的图片管家

Next.js的Image组件会自动优化图片：调整尺寸、转换格式、懒加载。就像有个专业的图片管理员，根据用户的设备和网络状况，提供最适合的图片版本。

工作原理：
- 自动检测视口大小，提供合适分辨率的图片
- 转换为现代格式（WebP/AVIF），减小文件体积
- 懒加载非首屏图片，节省带宽
- 防止布局偏移，保持页面稳定

## 渐进式代码示例

### 最小示例：Hello World页面

让我们从最简单的Next.js页面开始：

```jsx
// app/page.jsx
export default function Home() {
  return (
    <main>
      <h1>Welcome to Next.js!</h1>
      <p>This is my first Next.js page.</p>
    </main>
  );
}
```

这个文件位于`app/page.jsx`，对应网站的根路径`/`。Next.js会自动将其渲染为HTML。

### 完整示例：使用getServerSideProps获取实时数据

现在让我们创建一个显示实时股票价格的页面：

```jsx
// pages/stocks.jsx
import Head from 'next/head';

export default function StockPrices({ stocks }) {
  return (
    <>
      <Head>
        <title>实时股票价格</title>
        <meta name="description" content="查看最新股票行情" />
      </Head>
      
      <main className="container">
        <h1>股票市场实时行情</h1>
        <p>最后更新：{new Date().toLocaleTimeString()}</p>
        
        <div className="stock-grid">
          {stocks.map(stock => (
            <div key={stock.symbol} className="stock-card">
              <h2>{stock.name}</h2>
              <p className="symbol">{stock.symbol}</p>
              <p className={`price ${stock.change >= 0 ? 'up' : 'down'}`}>
                ¥{stock.price.toFixed(2)}
                <span className="change">
                  {stock.change >= 0 ? '+' : ''}{stock.changePercent.toFixed(2)}%
                </span>
              </p>
            </div>
          ))}
        </div>
      </main>
    </>
  );
}

// 这个函数在每次请求时在服务器上执行
export async function getServerSideProps() {
  try {
    // 模拟从股票API获取数据
    const response = await fetch('https://api.example.com/stocks', {
      headers: {
        'Authorization': `Bearer ${process.env.STOCK_API_KEY}`
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch stock data');
    }
    
    const stocks = await response.json();
    
    return {
      props: {
        stocks: stocks.slice(0, 10) // 只返回前10支股票
      }
    };
  } catch (error) {
    console.error('Error fetching stocks:', error);
    
    // 出错时返回空数组，页面仍能正常渲染
    return {
      props: {
        stocks: []
      }
    };
  }
}
```

这个例子展示了：
- 使用`getServerSideProps`在服务端获取数据
- 数据安全地传递给组件作为props
- 错误处理确保页面不会崩溃
- SEO友好的meta标签

### 进阶示例：使用getStaticProps生成静态博客

接下来创建一个博客列表页，使用静态生成提高性能：

```jsx
// pages/blog/index.jsx
import Link from 'next/link';
import Head from 'next/head';

export default function BlogIndex({ posts }) {
  return (
    <>
      <Head>
        <title>技术博客</title>
        <meta name="description" content="分享前端开发经验和技巧" />
      </Head>
      
      <main className="blog-container">
        <h1>最新文章</h1>
        
        <div className="post-list">
          {posts.map(post => (
            <article key={post.id} className="post-card">
              <Link href={`/blog/${post.slug}`}>
                <h2>{post.title}</h2>
              </Link>
              
              <p className="excerpt">{post.excerpt}</p>
              
              <div className="post-meta">
                <span className="author">作者：{post.author}</span>
                <time dateTime={post.date}>
                  {new Date(post.date).toLocaleDateString('zh-CN')}
                </time>
              </div>
            </article>
          ))}
        </div>
      </main>
    </>
  );
}

// 在构建时执行，生成静态HTML
export async function getStaticProps() {
  // 从CMS或数据库获取文章列表
  const response = await fetch('https://cms.example.com/api/posts');
  const posts = await response.json();
  
  return {
    props: {
      posts: posts
    },
    // 每60秒重新生成页面（增量静态再生）
    revalidate: 60
  };
}

// 预生成所有博客文章的路径
export async function getStaticPaths() {
  const response = await fetch('https://cms.example.com/api/posts');
  const posts = await response.json();
  
  const paths = posts.map(post => ({
    params: { slug: post.slug }
  }));
  
  return {
    paths,
    // 未预生成的路径在首次访问时动态生成
    fallback: 'blocking'
  };
}
```

单个博客文章页面：

```jsx
// pages/blog/[slug].jsx
import Head from 'next/head';
import ReactMarkdown from 'react-markdown';

export default function BlogPost({ post }) {
  if (!post) {
    return <div>文章不存在</div>;
  }
  
  return (
    <>
      <Head>
        <title>{post.title} | 技术博客</title>
        <meta name="description" content={post.excerpt} />
      </Head>
      
      <article className="blog-post">
        <header>
          <h1>{post.title}</h1>
          <div className="post-meta">
            <span>作者：{post.author}</span>
            <time>{new Date(post.date).toLocaleDateString('zh-CN')}</time>
          </div>
        </header>
        
        <div className="post-content">
          <ReactMarkdown>{post.content}</ReactMarkdown>
        </div>
      </article>
    </>
  );
}

export async function getStaticProps({ params }) {
  const response = await fetch(
    `https://cms.example.com/api/posts/${params.slug}`
  );
  
  if (!response.ok) {
    return {
      notFound: true
    };
  }
  
  const post = await response.json();
  
  return {
    props: {
      post
    },
    revalidate: 60
  };
}

export async function getStaticPaths() {
  const response = await fetch('https://cms.example.com/api/posts');
  const posts = await response.json();
  
  return {
    paths: posts.map(post => ({
      params: { slug: post.slug }
    })),
    fallback: 'blocking'
  };
}
```

这里展示了：
- `getStaticProps`在构建时生成静态页面
- `revalidate`实现增量静态再生
- `getStaticPaths`预生成动态路由
- `fallback: 'blocking'`处理未预生成的路径

### 实战示例：App Router布局系统

让我们使用现代化的App Router重构上述博客：

```jsx
// app/layout.jsx - 根布局
import './globals.css';
import Link from 'next/link';

export const metadata = {
  title: '技术博客',
  description: '分享前端开发经验和技巧'
};

export default function RootLayout({ children }) {
  return (
    <html lang="zh-CN">
      <body>
        <header className="site-header">
          <nav>
            <Link href="/" className="logo">我的博客</Link>
            <ul className="nav-links">
              <li><Link href="/blog">文章</Link></li>
              <li><Link href="/about">关于</Link></li>
              <li><Link href="/contact">联系</Link></li>
            </ul>
          </nav>
        </header>
        
        <main className="main-content">
          {children}
        </main>
        
        <footer className="site-footer">
          <p>&copy; 2024 技术博客. All rights reserved.</p>
        </footer>
      </body>
    </html>
  );
}
```

博客列表页：

```jsx
// app/blog/page.jsx
import Link from 'next/link';

async function getPosts() {
  const response = await fetch('https://cms.example.com/api/posts', {
    next: { revalidate: 60 } // ISR配置
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch posts');
  }
  
  return response.json();
}

export default async function BlogPage() {
  const posts = await getPosts();
  
  return (
    <div className="blog-page">
      <h1>最新文章</h1>
      
      <div className="post-grid">
        {posts.map(post => (
          <article key={post.id} className="post-card">
            <Link href={`/blog/${post.slug}`}>
              <h2>{post.title}</h2>
            </Link>
            
            <p className="excerpt">{post.excerpt}</p>
            
            <div className="post-meta">
              <span>{post.author}</span>
              <time>{new Date(post.date).toLocaleDateString('zh-CN')}</time>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
```

博客详情页：

```jsx
// app/blog/[slug]/page.jsx
import ReactMarkdown from 'react-markdown';
import { notFound } from 'next/navigation';

async function getPost(slug) {
  const response = await fetch(
    `https://cms.example.com/api/posts/${slug}`,
    { next: { revalidate: 60 } }
  );
  
  if (!response.ok) {
    return null;
  }
  
  return response.json();
}

export default async function BlogPostPage({ params }) {
  const post = await getPost(params.slug);
  
  if (!post) {
    notFound();
  }
  
  return (
    <article className="blog-post">
      <header>
        <h1>{post.title}</h1>
        <div className="post-meta">
          <span>作者：{post.author}</span>
          <time>{new Date(post.date).toLocaleDateString('zh-CN')}</time>
        </div>
      </header>
      
      <div className="post-content">
        <ReactMarkdown>{post.content}</ReactMarkdown>
      </div>
    </article>
  );
}
```

加载状态组件：

```jsx
// app/blog/loading.jsx
export default function BlogLoading() {
  return (
    <div className="loading-skeleton">
      <div className="skeleton-title"></div>
      <div className="skeleton-post"></div>
      <div className="skeleton-post"></div>
      <div className="skeleton-post"></div>
    </div>
  );
}
```

错误边界：

```jsx
// app/blog/error.jsx
'use client';

import { useEffect } from 'react';

export default function BlogError({ error, reset }) {
  useEffect(() => {
    console.error('Blog error:', error);
  }, [error]);
  
  return (
    <div className="error-container">
      <h2>加载文章失败</h2>
      <p>抱歉，暂时无法加载文章内容。</p>
      <button onClick={() => reset()}>重试</button>
    </div>
  );
}
```

App Router的优势：
- 布局组件在导航时保持状态
- 支持流式渲染和Suspense
- 更好的TypeScript支持
- 简化的数据获取（直接在组件中使用async/await）

### 综合示例：API路由与图片优化

最后，让我们创建一个完整的电商产品展示页面，结合API路由和图片优化：

```jsx
// pages/api/products.js - API路由
import fs from 'fs';
import path from 'path';

export default function handler(req, res) {
  if (req.method === 'GET') {
    // 读取产品数据
    const filePath = path.join(process.cwd(), 'data', 'products.json');
    const fileData = fs.readFileSync(filePath, 'utf8');
    const products = JSON.parse(fileData);
    
    // 支持分页和过滤
    const { page = 1, limit = 10, category } = req.query;
    let filteredProducts = products;
    
    if (category) {
      filteredProducts = products.filter(p => p.category === category);
    }
    
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedProducts = filteredProducts.slice(startIndex, endIndex);
    
    res.status(200).json({
      success: true,
      data: paginatedProducts,
      total: filteredProducts.length,
      page: parseInt(page),
      totalPages: Math.ceil(filteredProducts.length / limit)
    });
  } else if (req.method === 'POST') {
    // 验证用户身份（简化版）
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized'
      });
    }
    
    // 添加新产品
    const newProduct = req.body;
    
    // 这里应该写入数据库，简化起见我们只返回成功
    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      product: newProduct
    });
  } else {
    res.setHeader('Allow', ['GET', 'POST']);
    res.status(405).json({
      success: false,
      message: `Method ${req.method} Not Allowed`
    });
  }
}
```

产品展示页面：

```jsx
// pages/products.jsx
import Image from 'next/image';
import Head from 'next/head';
import { useState, useEffect } from 'react';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedCategory, setSelectedCategory] = useState('all');
  
  const categories = ['all', 'electronics', 'clothing', 'books'];
  
  useEffect(() => {
    async function fetchProducts() {
      setLoading(true);
      
      try {
        const params = new URLSearchParams({
          page: page.toString(),
          limit: '12'
        });
        
        if (selectedCategory !== 'all') {
          params.append('category', selectedCategory);
        }
        
        const response = await fetch(`/api/products?${params}`);
        const result = await response.json();
        
        if (result.success) {
          setProducts(result.data);
          setTotalPages(result.totalPages);
        }
      } catch (error) {
        console.error('Failed to fetch products:', error);
      } finally {
        setLoading(false);
      }
    }
    
    fetchProducts();
  }, [page, selectedCategory]);
  
  return (
    <>
      <Head>
        <title>产品中心</title>
        <meta name="description" content="浏览我们的优质商品" />
      </Head>
      
      <main className="products-page">
        <h1>产品中心</h1>
        
        {/* 分类过滤器 */}
        <div className="category-filter">
          {categories.map(category => (
            <button
              key={category}
              className={`filter-btn ${selectedCategory === category ? 'active' : ''}`}
              onClick={() => {
                setSelectedCategory(category);
                setPage(1);
              }}
            >
              {category === 'all' ? '全部' : category}
            </button>
          ))}
        </div>
        
        {/* 产品网格 */}
        {loading ? (
          <div className="loading-grid">
            {[...Array(12)].map((_, i) => (
              <div key={i} className="product-skeleton"></div>
            ))}
          </div>
        ) : (
          <div className="product-grid">
            {products.map(product => (
              <article key={product.id} className="product-card">
                <div className="image-wrapper">
                  <Image
                    src={product.image}
                    alt={product.name}
                    width={300}
                    height={300}
                    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                    priority={page === 1 && product.id <= 4}
                    className="product-image"
                  />
                </div>
                
                <div className="product-info">
                  <h3>{product.name}</h3>
                  <p className="price">¥{product.price.toFixed(2)}</p>
                  <p className="description">{product.description}</p>
                  
                  <button className="add-to-cart">
                    加入购物车
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
        
        {/* 分页 */}
        {!loading && totalPages > 1 && (
          <div className="pagination">
            <button
              disabled={page === 1}
              onClick={() => setPage(p => p - 1)}
            >
              上一页
            </button>
            
            <span className="page-info">
              第 {page} 页 / 共 {totalPages} 页
            </span>
            
            <button
              disabled={page === totalPages}
              onClick={() => setPage(p => p + 1)}
            >
              下一页
            </button>
          </div>
        )}
      </main>
    </>
  );
}
```

CSS样式（简化版）：

```css
/* styles/products.module.css */
.products-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.category-filter {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
}

.filter-btn {
  padding: 0.5rem 1.5rem;
  border: 2px solid #ddd;
  background: white;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s;
}

.filter-btn.active {
  background: #0070f3;
  color: white;
  border-color: #0070f3;
}

.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 2rem;
}

.product-card {
  border: 1px solid #eee;
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.3s, box-shadow 0.3s;
}

.product-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
}

.image-wrapper {
  position: relative;
  width: 100%;
  padding-top: 100%;
}

.product-image {
  position: absolute;
  top: 0;
  left: 0;
  object-fit: cover;
}

.product-info {
  padding: 1rem;
}

.price {
  font-size: 1.5rem;
  font-weight: bold;
  color: #0070f3;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 2rem;
  margin-top: 3rem;
}

.pagination button {
  padding: 0.5rem 1.5rem;
  border: 1px solid #ddd;
  background: white;
  border-radius: 4px;
  cursor: pointer;
}

.pagination button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

这个综合示例展示了：
- API路由处理CRUD操作
- Image组件的自动优化
- 分页和过滤功能
- 响应式网格布局
- 加载状态管理

## 常见陷阱对照表

| 陷阱 | 表现 | 解决方案 |
|------|------|----------|
| 在getServerSideProps中访问window/document | 服务端报错 | SSR代码只在服务器运行，不能使用浏览器API |
| getStaticProps忘记配置revalidate | 数据永远不更新 | 根据数据更新频率设置合理的revalidate值 |
| App Router中混用Client和Server组件 |  hydration错误 | 明确标记'use client'，避免在服务端组件中使用浏览器API |
| Image组件缺少width/height | 布局偏移警告 | 始终提供明确的尺寸或使用fill模式 |
| API路由未处理方法 | 404或500错误 | 检查req.method，返回适当的HTTP状态码 |
| 过度使用SSR导致性能下降 | 服务器负载高，响应慢 | 对不需要实时数据的页面使用SSG或ISR |
| 忘记处理getStaticPaths的fallback | 未预生成路径404 | 设置fallback为'blocking'或提供降级UI |

## 自测题目

### 问题1

关于Next.js的渲染策略，以下说法正确的是？

A. SSR适合内容频繁变化的页面，如新闻网站  
B. SSG适合完全静态的内容，如公司官网首页  
C. CSR适合高度交互的应用，如在线游戏  
D. 以上都正确  

**正确答案：D**

**详细解释：** 三种渲染策略各有适用场景。SSR（服务端渲染）每次请求都重新生成HTML，适合需要实时数据的场景，如新闻、股票行情。SSG（静态站点生成）在构建时生成HTML，适合内容不常变化的页面，如博客、文档。CSR（客户端渲染）依赖JavaScript动态渲染，适合交互密集的应用，如仪表盘、游戏。Next.js的强大之处在于可以在同一应用中混合使用这些策略，为每个页面选择最优方案。

---

### 问题2

以下代码有什么问题？

```jsx
export default function Page({ data }) {
  return <div>{data.message}</div>;
}

export async function getServerSideProps() {
  const data = { message: 'Hello' };
  
  // 尝试访问浏览器API
  const screenWidth = window.innerWidth;
  
  return {
    props: { data }
  };
}
```

A. getServerSideProps返回值格式错误  
B. 在服务端代码中访问了window对象  
C. data没有正确传递给组件  
D. 缺少必要的导入语句  

**正确答案：B**

**详细解释：** `getServerSideProps`在Node.js服务器上执行，而不是在浏览器中。因此它无法访问浏览器特有的API，如`window`、`document`、`localStorage`等。尝试访问这些API会导致运行时错误。如果需要根据屏幕尺寸做适配，应该在客户端组件中使用`useEffect`或CSS媒体查询。正确的做法是移除`window.innerWidth`这行代码，或在客户端处理响应式逻辑。

---

### 问题3

关于App Router的布局系统，以下说法错误的是？

A. layout.jsx会在路由切换时保持状态  
B. 每个路由段都可以有自己的layout  
C. layout必须包含children参数  
D. layout中可以随意使用useState和useEffect  

**正确答案：D**

**详细解释：** App Router默认使用React Server Components，这意味着layout默认是在服务端渲染的。在服务端组件中不能使用useState、useEffect等客户端Hooks。如果需要在layout中使用这些Hooks，必须在文件顶部添加`'use client'`指令，将其转换为客户端组件。选项A、B、C都是正确的：layout确实会在导航时保持状态，支持嵌套布局，且必须接收并渲染children。

---

### 问题4

Next.js Image组件相比普通img标签的优势不包括？

A. 自动转换为WebP/AVIF格式  
B. 根据设备像素比提供合适分辨率  
C. 自动添加alt属性提升可访问性  
D. 懒加载非首屏图片  

**正确答案：C**

**详细解释：** Next.js Image组件提供了多项性能优化：自动格式转换（选项A）、响应式图片（选项B）、懒加载（选项D）、防止布局偏移等。但它不会自动添加alt属性——开发者仍然需要手动提供有意义的alt文本以提升可访问性。这是故意的设计，因为AI无法准确判断图片内容，强制要求开发者思考图片的语义含义。其他三个选项都是Image组件的真实优势。

---

### 问题5

关于增量静态再生（ISR），以下描述正确的是？

A. revalidate设置为0表示永不更新  
B. 重新生成期间旧页面仍然可用  
C. 每次访问都会触发重新生成  
D. ISR只能用于getServerSideProps  

**正确答案：B**

**详细解释：** ISR是Next.js的独特功能，结合了SSG的速度和SSR的数据新鲜度。当设置了`revalidate`后，页面在后台异步重新生成，在此期间用户看到的仍然是旧的缓存版本（选项B正确）。选项A错误，revalidate为0表示每次请求都重新验证。选项C错误，ISR是按时间间隔触发，不是每次访问。选项D错误，ISR用于getStaticProps，而非getServerSideProps。ISR特别适合博客、电商产品等更新频率中等的场景。
