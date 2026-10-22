#!/usr/bin/env python3
"""Extract quiz data from frontend framework markdown files and generate manifest entries."""

import json
import re
from pathlib import Path

def extract_quiz_from_markdown(file_path):
    """Extract quiz questions from markdown file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    quizzes = []
    # Find all quiz sections (问题1, 问题2, etc.)
    quiz_pattern = r'###\s+问题\d+\s*\n(.*?)(?=###\s+问题\d+|$)'
    quiz_matches = re.findall(quiz_pattern, content, re.DOTALL)

    for quiz_text in quiz_matches:
        # Extract question
        question_match = re.search(r'(关于|以下|下列|React|Vue|Angular|Next\.js|Svelte|状态管理|性能优化).*?[？?]', quiz_text)
        if not question_match:
            continue
        question = question_match.group(0).strip()

        # Extract options (A. B. C. D.)
        options = re.findall(r'[A-D]\.\s+(.*?)(?=\n[A-D]\.|\n\*\*正确|\Z)', quiz_text, re.DOTALL)
        options = [opt.strip() for opt in options]

        # Extract correct answer
        answer_match = re.search(r'\*\*正确答案[：:]\*\*\s*([A-D])', quiz_text)
        if not answer_match:
            continue
        answer_letter = answer_match.group(1)
        answer_index = ord(answer_letter) - ord('A')

        # Extract explanation
        explanation_match = re.search(r'\*\*详细解释[：:]\*\*\s*(.*?)(?=\n---|\Z)', quiz_text, re.DOTALL)
        explanation = explanation_match.group(1).strip() if explanation_match else ""

        if len(options) >= 2:
            quizzes.append({
                "type": "single",
                "question": question,
                "options": options,
                "answer": answer_index,
                "explanation": explanation
            })

    return quizzes

def generate_manifest_entry(chapter_file, order):
    """Generate manifest entry for a chapter."""
    file_stem = chapter_file.stem

    # Map filenames to titles and summaries
    chapter_info = {
        'frontend_react_hooks': {
            'id': 'frontend_react_hooks',
            'title_zh': 'React核心概念与Hooks',
            'title_en': 'React Core Concepts & Hooks',
            'summary_zh': '掌握React组件化思想、虚拟DOM原理和常用Hooks（useState/useEffect/useContext）。',
            'summary_en': 'Master React component thinking, virtual DOM, and common Hooks.',
            'minutes': 45,
            'keywords': ['React', 'Hooks', 'useState', 'useEffect', '组件化'],
            'difficulty': '入门'
        },
        'frontend_vue_composition': {
            'id': 'frontend_vue_composition',
            'title_zh': 'Vue 3组合式API',
            'title_en': 'Vue 3 Composition API',
            'summary_zh': '理解Composition API设计理念，掌握ref/reactive/computed/watch等响应式API。',
            'summary_en': 'Understand Composition API design and master reactive APIs.',
            'minutes': 45,
            'keywords': ['Vue 3', 'Composition API', 'ref', 'reactive', '响应式'],
            'difficulty': '入门'
        },
        'frontend_angular_basics': {
            'id': 'frontend_angular_basics',
            'title_zh': 'Angular基础与依赖注入',
            'title_en': 'Angular Basics & Dependency Injection',
            'summary_zh': '学习Angular架构、TypeScript集成、依赖注入系统和RxJS响应式编程。',
            'summary_en': 'Learn Angular architecture, TypeScript integration, DI system, and RxJS.',
            'minutes': 50,
            'keywords': ['Angular', '依赖注入', 'TypeScript', 'RxJS', '服务'],
            'difficulty': '入门'
        },
        'frontend_nextjs_ssr': {
            'id': 'frontend_nextjs_ssr',
            'title_zh': 'Next.js服务端渲染',
            'title_en': 'Next.js Server-Side Rendering',
            'summary_zh': '对比SSR/CSR/SSG渲染策略，掌握Next.js App Router和API Routes开发。',
            'summary_en': 'Compare SSR/CSR/SSG strategies and master Next.js App Router.',
            'minutes': 50,
            'keywords': ['Next.js', 'SSR', 'SSG', 'App Router', '服务端渲染'],
            'difficulty': '进阶'
        },
        'frontend_svelte_reactive': {
            'id': 'frontend_svelte_reactive',
            'title_zh': 'Svelte响应式编程',
            'title_en': 'Svelte Reactive Programming',
            'summary_zh': '探索Svelte编译时响应式系统，掌握stores、transitions和actions。',
            'summary_en': 'Explore Svelte compile-time reactivity, stores, transitions, and actions.',
            'minutes': 40,
            'keywords': ['Svelte', '响应式', 'stores', 'transitions', '无虚拟DOM'],
            'difficulty': '入门'
        },
        'frontend_framework_comparison': {
            'id': 'frontend_framework_comparison',
            'title_zh': '框架对比与选型指南',
            'title_en': 'Framework Comparison & Selection Guide',
            'summary_zh': '从性能、包体积、学习曲线等维度对比主流框架，提供选型决策树。',
            'summary_en': 'Compare frameworks on performance, bundle size, learning curve, and provide selection guide.',
            'minutes': 40,
            'keywords': ['框架对比', '性能基准', '选型指南', '生态系统', '最佳实践'],
            'difficulty': '进阶'
        },
        'frontend_state_management': {
            'id': 'frontend_state_management',
            'title_zh': '状态管理深入',
            'title_en': 'State Management Deep Dive',
            'summary_zh': '深入学习Redux Toolkit、Pinia、NgRx，理解何时需要全局状态管理。',
            'summary_en': 'Deep dive into Redux Toolkit, Pinia, NgRx, and when to use global state.',
            'minutes': 55,
            'keywords': ['Redux', 'Pinia', 'NgRx', '状态管理', 'Context API'],
            'difficulty': '进阶'
        },
        'frontend_performance_optimization': {
            'id': 'frontend_performance_optimization',
            'title_zh': '性能优化最佳实践',
            'title_en': 'Performance Optimization Best Practices',
            'summary_zh': '掌握代码分割、懒加载、记忆化、Tree Shaking和虚拟滚动等优化技术。',
            'summary_en': 'Master code splitting, lazy loading, memoization, Tree Shaking, and virtual scrolling.',
            'minutes': 50,
            'keywords': ['性能优化', '代码分割', '懒加载', 'Tree Shaking', '虚拟滚动'],
            'difficulty': '进阶'
        }
    }

    info = chapter_info.get(file_stem)
    if not info:
        return None

    # Extract quizzes from markdown file
    md_file = Path(f"F:/app/assets/content/{file_stem}.md")
    quizzes = extract_quiz_from_markdown(md_file) if md_file.exists() else []

    return {
        "id": info['id'],
        "title": {
            "zh": info['title_zh'],
            "en": info['title_en']
        },
        "summary": {
            "zh": info['summary_zh'],
            "en": info['summary_en']
        },
        "file": f"assets/content/{file_stem}.md",
        "minutes": info['minutes'],
        "keywords": info['keywords'],
        "difficulty": info['difficulty'],
        "order": order,
        "quiz": quizzes
    }

def main():
    """Generate manifest entries for all frontend framework chapters."""
    content_dir = Path("F:/app/assets/content")
    frontend_files = sorted(content_dir.glob("frontend_*.md"))

    category_entry = {
        "id": "frontend_frameworks",
        "title": {
            "zh": "前端框架专题",
            "en": "Frontend Frameworks"
        },
        "icon": "web",
        "color": "61DAFB",
        "lessons": []
    }

    for order, file_path in enumerate(frontend_files):
        lesson_entry = generate_manifest_entry(file_path, order)
        if lesson_entry:
            category_entry["lessons"].append(lesson_entry)
            print(f"✅ Processed: {file_path.name} ({len(lesson_entry['quiz'])} quizzes)")

    # Output JSON
    print("\n=== Manifest Entry ===")
    print(json.dumps(category_entry, ensure_ascii=False, indent=2))

    # Save to file
    output_file = Path("F:/app/scripts/frontend_manifest_entry.json")
    output_file.write_text(json.dumps(category_entry, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"\n💾 Saved to: {output_file}")

if __name__ == "__main__":
    main()
