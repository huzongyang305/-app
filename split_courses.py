#!/usr/bin/env python3
"""将Java Web和离散数学课程从原category中分离成独立的category"""

import json
import re

def main():
    # 读取manifest
    with open('assets/content/manifest.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    categories = data['categories']
    
    # 找到java和fundamentals category
    java_cat = next(c for c in categories if c['id'] == 'java')
    fundamentals_cat = next(c for c in categories if c['id'] == 'fundamentals')
    
    print(f"Java category: {len(java_cat['lessons'])} lessons")
    print(f"Fundamentals category: {len(fundamentals_cat['lessons'])} lessons")
    
    # Java Web相关课程的ID模式
    javaweb_keywords = ['servlet', 'jsp', 'spring', 'javaweb', 'java_web', 'web_', 'rest', 'inventory']
    
    # 离散数学课程ID
    discrete_math_ids = ['discrete_math']
    
    # 分离Java Web课程
    javaweb_lessons = []
    java_remaining = []
    
    for lesson in java_cat['lessons']:
        lesson_id = lesson['id'].lower()
        is_javaweb = any(kw in lesson_id for kw in javaweb_keywords)
        
        if is_javaweb:
            javaweb_lessons.append(lesson)
        else:
            java_remaining.append(lesson)
    
    print(f"\nJava Web lessons to extract: {len(javaweb_lessons)}")
    for l in javaweb_lessons:
        print(f"  - {l['id']}: {l['title']['zh']}")
    
    # 分离离散数学课程
    discrete_lessons = []
    fundamentals_remaining = []
    
    for lesson in fundamentals_cat['lessons']:
        if lesson['id'] in discrete_math_ids:
            discrete_lessons.append(lesson)
        else:
            fundamentals_remaining.append(lesson)
    
    print(f"\nDiscrete Math lessons to extract: {len(discrete_lessons)}")
    for l in discrete_lessons:
        print(f"  - {l['id']}: {l['title']['zh']}")
    
    # 更新原有category的lessons
    java_cat['lessons'] = java_remaining
    fundamentals_cat['lessons'] = fundamentals_remaining
    
    # 创建新的Java Web category
    javaweb_category = {
        "id": "javaweb",
        "title": {
            "zh": "Java Web开发",
            "en": "Java Web Development"
        },
        "icon": "language",
        "color": "E76F00",
        "lessons": javaweb_lessons
    }
    
    # 创建新的离散数学category
    discrete_math_category = {
        "id": "discrete_mathematics",
        "title": {
            "zh": "离散数学",
            "en": "Discrete Mathematics"
        },
        "icon": "school",
        "color": "8B5CF6",
        "lessons": discrete_lessons
    }
    
    # 插入新categories到合适的位置
    # Java Web放在Java之后
    java_index = categories.index(java_cat)
    categories.insert(java_index + 1, javaweb_category)
    
    # 离散数学放在计算机基础之后
    fundamentals_index = categories.index(fundamentals_cat)
    categories.insert(fundamentals_index + 1, discrete_math_category)
    
    # 保存更新后的manifest
    with open('assets/content/manifest.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 完成！")
    print(f"  - Java category: {len(java_remaining)} lessons (原{len(java_cat['lessons']) + len(javaweb_lessons)})")
    print(f"  - Java Web category: {len(javaweb_lessons)} lessons (新建)")
    print(f"  - Fundamentals category: {len(fundamentals_remaining)} lessons (原{len(fundamentals_cat['lessons']) + len(discrete_lessons)})")
    print(f"  - Discrete Mathematics category: {len(discrete_lessons)} lessons (新建)")
    print(f"  - 总categories数: {len(categories)}")

if __name__ == '__main__':
    main()
