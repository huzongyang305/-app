const fs = require('fs');
let content = fs.readFileSync('assets/content/css_animation_render.md', 'utf8');

// Fix line 458
content = content.replace(
  /围绕"浏览器渲染与 CSS 动画"中的/,
  '围绕\u201c浏览器渲染与 CSS 动画\u201d中的'
);

fs.writeFileSync('assets/content/css_animation_render.md', content, 'utf8');
console.log('Fixed css_animation_render.md!');
