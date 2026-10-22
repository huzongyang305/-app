#!/usr/bin/env node
/** 将Java Web和离散数学课程从原category中分离成独立的category */

const fs = require('fs');

function main() {
    // 读取manifest
    const data = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf-8'));
    
    const categories = data.categories;
    
    // 找到java和fundamentals category
    const javaCat = categories.find(c => c.id === 'java');
    const fundamentalsCat = categories.find(c => c.id === 'fundamentals');
    
    console.log(`Java category: ${javaCat.lessons.length} lessons`);
    console.log(`Fundamentals category: ${fundamentalsCat.lessons.length} lessons`);
    
    // Java Web相关课程的ID模式
    const javawebKeywords = ['servlet', 'jsp', 'spring', 'javaweb', 'java_web', 'web_', 'rest', 'inventory'];
    
    // 离散数学课程ID
    const discreteMathIds = ['discrete_math'];
    
    // 分离Java Web课程
    const javawebLessons = [];
    const javaRemaining = [];
    
    for (const lesson of javaCat.lessons) {
        const lessonId = lesson.id.toLowerCase();
        const isJavaweb = javawebKeywords.some(kw => lessonId.includes(kw));
        
        if (isJavaweb) {
            javawebLessons.push(lesson);
        } else {
            javaRemaining.push(lesson);
        }
    }
    
    console.log(`\nJava Web lessons to extract: ${javawebLessons.length}`);
    javawebLessons.forEach(l => {
        console.log(`  - ${l.id}: ${l.title.zh}`);
    });
    
    // 分离离散数学课程
    const discreteLessons = [];
    const fundamentalsRemaining = [];
    
    for (const lesson of fundamentalsCat.lessons) {
        if (discreteMathIds.includes(lesson.id)) {
            discreteLessons.push(lesson);
        } else {
            fundamentalsRemaining.push(lesson);
        }
    }
    
    console.log(`\nDiscrete Math lessons to extract: ${discreteLessons.length}`);
    discreteLessons.forEach(l => {
        console.log(`  - ${l.id}: ${l.title.zh}`);
    });
    
    // 更新原有category的lessons
    javaCat.lessons = javaRemaining;
    fundamentalsCat.lessons = fundamentalsRemaining;
    
    // 创建新的Java Web category
    const javawebCategory = {
        id: "javaweb",
        title: {
            zh: "Java Web开发",
            en: "Java Web Development"
        },
        icon: "language",
        color: "E76F00",
        lessons: javawebLessons
    };
    
    // 创建新的离散数学category
    const discreteMathCategory = {
        id: "discrete_mathematics",
        title: {
            zh: "离散数学",
            en: "Discrete Mathematics"
        },
        icon: "school",
        color: "8B5CF6",
        lessons: discreteLessons
    };
    
    // 插入新categories到合适的位置
    // Java Web放在Java之后
    const javaIndex = categories.indexOf(javaCat);
    categories.splice(javaIndex + 1, 0, javawebCategory);
    
    // 离散数学放在计算机基础之后
    const fundamentalsIndex = categories.indexOf(fundamentalsCat);
    categories.splice(fundamentalsIndex + 1, 0, discreteMathCategory);
    
    // 保存更新后的manifest
    fs.writeFileSync('assets/content/manifest.json', JSON.stringify(data, null, 2), 'utf-8');
    
    console.log(`\n✅ 完成！`);
    console.log(`  - Java category: ${javaRemaining.length} lessons (原${javaCat.lessons.length + javawebLessons.length})`);
    console.log(`  - Java Web category: ${javawebLessons.length} lessons (新建)`);
    console.log(`  - Fundamentals category: ${fundamentalsRemaining.length} lessons (原${fundamentalsCat.lessons.length + discreteLessons.length})`);
    console.log(`  - Discrete Mathematics category: ${discreteLessons.length} lessons (新建)`);
    console.log(`  - 总categories数: ${categories.length}`);
}

main();
