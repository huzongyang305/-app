import '../models/localized_text.dart';
import '../models/sandbox_challenge.dart';

/// 内置的沙箱挑战题库（完全离线，随 APK 打包）。
///
/// 键是 [SandboxLanguage.id]；只有内置真实运行时的语言才有挑战，
/// 静态追踪模式（Java / C# / Dart / Go / Rust / Kotlin / Swift）不参与，
/// 因为它们的输出带有诊断信息，无法做严格比对。
const Map<String, List<SandboxChallenge>>
sandboxChallengesByLanguage = <String, List<SandboxChallenge>>{
  'javascript': <SandboxChallenge>[
    SandboxChallenge(
      id: 'js-fizzbuzz',
      title: LocalizedText(zh: 'FizzBuzz 判断', en: 'FizzBuzz'),
      prompt: LocalizedText(
        zh:
            '打印 1 到 15：3 的倍数输出 Fizz，5 的倍数输出 Buzz，'
            '同时是 3 和 5 的倍数输出 FizzBuzz，其余输出数字本身。',
        en:
            'Print 1 to 15: Fizz for multiples of 3, Buzz for multiples '
            'of 5, FizzBuzz for multiples of both, otherwise the number.',
      ),
      starterCode: r'''
for (let i = 1; i <= 15; i++) {
  // TODO: 先判断 i % 15 === 0，再判断 3 和 5 的倍数
  console.log(i);
}
''',
      hint: LocalizedText(
        zh: '先判断 i % 15 === 0，再判断 i % 3 === 0 和 i % 5 === 0。',
        en: 'Check i % 15 first, then i % 3 and i % 5.',
      ),
      expectedOutput: '''
1
2
Fizz
4
Buzz
Fizz
7
8
Fizz
Buzz
11
Fizz
13
14
FizzBuzz''',
    ),
    SandboxChallenge(
      id: 'js-max-of-line',
      title: LocalizedText(zh: '一行数字求最大值', en: 'Max of a line'),
      prompt: LocalizedText(
        zh: '读取一行用空格分隔的整数，输出其中的最大值。',
        en: 'Read one line of space-separated integers and print the max.',
      ),
      starterCode: r'''
const line = readLine();
const numbers = line.split(" ").map(Number);
// TODO: 求 numbers 中的最大值并输出
''',
      stdin: '3 17 8 42 5',
      expectedOutput: '42',
      hint: LocalizedText(
        zh: '可以用 Math.max(...numbers)，也可以自己写循环比较。',
        en: 'Math.max(...numbers) works, or write your own loop.',
      ),
    ),
    SandboxChallenge(
      id: 'js-sum-1-100',
      title: LocalizedText(zh: '1 到 100 求和', en: 'Sum 1 to 100'),
      prompt: LocalizedText(
        zh: '用循环计算 1 + 2 + ... + 100，输出结果。',
        en: 'Use a loop to compute 1 + 2 + ... + 100 and print the result.',
      ),
      starterCode: r'''
let sum = 0;
// TODO: 累加 1 到 100
console.log(sum);
''',
      expectedOutput: '5050',
    ),
  ],
  'typescript': <SandboxChallenge>[
    SandboxChallenge(
      id: 'ts-average',
      title: LocalizedText(zh: '计算平均分', en: 'Average score'),
      prompt: LocalizedText(
        zh: '根据学生数组计算平均分，保留一位小数输出（例如 92.0）。',
        en: 'Compute the average score and print it with one decimal place.',
      ),
      starterCode: r'''
interface Student {
  name: string;
  score: number;
}
const students: Student[] = [
  { name: "小明", score: 92 },
  { name: "小红", score: 88 },
  { name: "小刚", score: 96 },
];
// TODO: 计算平均分并保留一位小数输出
''',
      expectedOutput: '92.0',
      hint: LocalizedText(
        zh: '(总和 / 人数).toFixed(1) 可以得到一位小数。',
        en: 'Use (total / count).toFixed(1).',
      ),
    ),
    SandboxChallenge(
      id: 'ts-filter-names',
      title: LocalizedText(zh: '筛选高分学生', en: 'Filter top students'),
      prompt: LocalizedText(
        zh: '筛选出分数大于等于 90 的学生，把名字用 ", " 连接后输出。',
        en: 'Filter students with score >= 90 and join names with ", ".',
      ),
      starterCode: r'''
interface Student {
  name: string;
  score: number;
}
const students: Student[] = [
  { name: "小明", score: 92 },
  { name: "小红", score: 88 },
  { name: "小刚", score: 96 },
];
// TODO: 过滤 + map + join
''',
      expectedOutput: '小明, 小刚',
    ),
  ],
  'python': <SandboxChallenge>[
    SandboxChallenge(
      id: 'py-prime-check',
      title: LocalizedText(zh: '判断素数', en: 'Prime check'),
      prompt: LocalizedText(
        zh: '读入一个整数 n，判断它是否为素数，输出 True 或 False。',
        en: 'Read an integer n and print True if it is prime, else False.',
      ),
      starterCode: r'''
n = int(input())
is_prime = n > 1
# TODO: 用循环检查 2 到 n 的平方根之间是否存在因子
print(is_prime)
''',
      stdin: '17',
      expectedOutput: 'True',
      hint: LocalizedText(
        zh: '只要 n 能被 2..int(n ** 0.5) 中任意一个数整除，就不是素数。',
        en: 'If any number in 2..int(n ** 0.5) divides n, it is not prime.',
      ),
    ),
    SandboxChallenge(
      id: 'py-word-count',
      title: LocalizedText(zh: '统计单词数', en: 'Count words'),
      prompt: LocalizedText(
        zh: '读入一行英文句子，输出它包含的单词个数。',
        en: 'Read one line of text and print how many words it has.',
      ),
      starterCode: r'''
line = input()
# TODO: 用 split() 拆分后输出单词数
''',
      stdin: 'hello flutter world',
      expectedOutput: '3',
    ),
    SandboxChallenge(
      id: 'py-fib-10',
      title: LocalizedText(zh: '斐波那契数列', en: 'Fibonacci'),
      prompt: LocalizedText(
        zh: '输出前 10 个斐波那契数（从 0 开始），用空格分隔在同一行。',
        en:
            'Print the first 10 Fibonacci numbers (starting at 0) on one '
            'line, separated by spaces.',
      ),
      starterCode: r'''
a, b = 0, 1
values = []
# TODO: 生成 10 个数后打印
print(*values)
''',
      expectedOutput: '0 1 1 2 3 5 8 13 21 34',
    ),
  ],
  'lua': <SandboxChallenge>[
    SandboxChallenge(
      id: 'lua-factorial',
      title: LocalizedText(zh: '计算阶乘', en: 'Factorial'),
      prompt: LocalizedText(
        zh: '计算 6 的阶乘并输出结果。',
        en: 'Compute 6! and print the result.',
      ),
      starterCode: r'''
local result = 1
-- TODO: 用循环累乘 1 到 6
print(result)
''',
      expectedOutput: '720',
    ),
    SandboxChallenge(
      id: 'lua-sum-1-100',
      title: LocalizedText(zh: '1 到 100 求和', en: 'Sum 1 to 100'),
      prompt: LocalizedText(
        zh: '用循环计算 1 + 2 + ... + 100 并输出。',
        en: 'Use a loop to sum 1 to 100 and print it.',
      ),
      starterCode: r'''
local sum = 0
-- TODO: 累加 1 到 100
print(sum)
''',
      expectedOutput: '5050',
    ),
  ],
  'sql': <SandboxChallenge>[
    SandboxChallenge(
      id: 'sql-count-rows',
      title: LocalizedText(zh: '统计学生人数', en: 'Count students'),
      prompt: LocalizedText(
        zh: '建表并插入三名学生后，用聚合函数统计总人数。',
        en: 'Create the table, insert three students and count the rows.',
      ),
      starterCode: r'''
CREATE TABLE students (name TEXT, score INTEGER);
INSERT INTO students VALUES ('小明', 92), ('小红', 88), ('小刚', 96);
-- TODO: 统计总人数并命名为 total
''',
      expectedOutput: '''
total
-----
3''',
      hint: LocalizedText(
        zh: 'SELECT COUNT(*) AS total FROM students;',
        en: 'SELECT COUNT(*) AS total FROM students;',
      ),
    ),
    SandboxChallenge(
      id: 'sql-order-by-score',
      title: LocalizedText(zh: '按分数排序', en: 'Order by score'),
      prompt: LocalizedText(
        zh: '查询所有学生的姓名，按分数从高到低排列，只输出姓名列。',
        en: 'Select student names ordered by score descending.',
      ),
      starterCode: r'''
CREATE TABLE students (name TEXT, score INTEGER);
INSERT INTO students VALUES ('小明', 92), ('小红', 88), ('小刚', 96);
-- TODO: SELECT name FROM students ORDER BY ...
''',
      expectedOutput: '''
name
----
小刚
小明
小红''',
    ),
  ],
  'bash': <SandboxChallenge>[
    SandboxChallenge(
      id: 'bash-squares',
      title: LocalizedText(zh: '输出平方数', en: 'Print squares'),
      prompt: LocalizedText(
        zh: '用 for 循环输出 1 到 5 的平方，每行一个。',
        en: 'Use a for loop to print the squares of 1..5, one per line.',
      ),
      starterCode: r'''
# TODO: for i in 1 2 3 4 5; do ... done
''',
      expectedOutput: '''
1
4
9
16
25''',
      hint: LocalizedText(
        zh: r'算术运算写作 $((i * i))，输出用 echo。',
        en: r'Arithmetic uses $((i * i)) and output uses echo.',
      ),
    ),
    SandboxChallenge(
      id: 'bash-sum-loop',
      title: LocalizedText(zh: '循环求和', en: 'Sum with a loop'),
      prompt: LocalizedText(
        zh: '用循环计算 1 到 10 的和并输出。',
        en: 'Sum 1 to 10 with a loop and print the total.',
      ),
      starterCode: r'''
sum=0
# TODO: 累加 1 到 10
echo "$sum"
''',
      expectedOutput: '55',
    ),
  ],
  'scheme': <SandboxChallenge>[
    SandboxChallenge(
      id: 'scheme-sum-recursive',
      title: LocalizedText(zh: '递归求和', en: 'Recursive sum'),
      prompt: LocalizedText(
        zh: '用递归函数计算 1 到 10 的和并输出。',
        en: 'Compute the sum of 1..10 with a recursive function.',
      ),
      starterCode: r'''
(define (sum n)
  ; TODO: 当 n 为 0 时返回 0，否则返回 n + (sum (- n 1))
  0)

(display (sum 10))
(newline)
''',
      expectedOutput: '55',
    ),
    SandboxChallenge(
      id: 'scheme-double-list',
      title: LocalizedText(zh: '列表元素翻倍', en: 'Double a list'),
      prompt: LocalizedText(
        zh: '把列表 (1 2 3 4 5) 中的每个元素乘以 2 并输出结果列表。',
        en: 'Double each element of (1 2 3 4 5) and print the result list.',
      ),
      starterCode: r'''
(define (double-list lst)
  ; TODO: 用 map 和 lambda 实现
  lst)

(display (double-list '(1 2 3 4 5)))
(newline)
''',
      expectedOutput: '(2 4 6 8 10)',
    ),
  ],
  'cpp': <SandboxChallenge>[
    SandboxChallenge(
      id: 'cpp-sum-1-100',
      title: LocalizedText(zh: '1 到 100 求和', en: 'Sum 1 to 100'),
      prompt: LocalizedText(
        zh: '用 for 循环计算 1 到 100 的和并输出。',
        en: 'Use a for loop to sum 1 to 100 and print it.',
      ),
      starterCode: r'''
#include <iostream>
using namespace std;

int main() {
    int sum = 0;
    // TODO: 累加 1 到 100
    cout << sum << endl;
    return 0;
}
''',
      expectedOutput: '5050',
    ),
    SandboxChallenge(
      id: 'cpp-even-sum',
      title: LocalizedText(zh: '偶数求和', en: 'Sum of evens'),
      prompt: LocalizedText(
        zh: '计算 1 到 20 之间所有偶数的和并输出。',
        en: 'Compute the sum of all even numbers from 1 to 20.',
      ),
      starterCode: r'''
#include <iostream>
using namespace std;

int main() {
    int sum = 0;
    // TODO: 累加 1 到 20 中的偶数
    cout << sum << endl;
    return 0;
}
''',
      expectedOutput: '110',
    ),
  ],
};
