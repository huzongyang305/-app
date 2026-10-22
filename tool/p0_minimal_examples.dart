// P0 内容修复：为 128 篇「最小示例」仍是占位符的课程补齐主题化示例。
//
// 每条记录包含：代码围栏语言、可运行代码、与代码严格对应的预期输出。
// 预期输出必须是该代码真实运行的结果，不能是描述性文字（UI/SQL DDL 除外）。

/// 单篇课程的最小示例。
class P0Example {
  const P0Example(this.language, this.code, this.output);

  /// Markdown 代码围栏语言标记。
  final String language;

  /// 最小可运行代码。
  final String code;

  /// 运行 [code] 后的真实输出。
  final String output;
}

const Map<String, P0Example> p0MinimalExamples = <String, P0Example>{
  // === C ===
  'c_first_program': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    printf("hello from C\n");
    return 0;
}''',
    r'''hello from C''',
  ),
  'c_variables_io': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    int count = 3;
    double price = 2.5;
    printf("count=%d total=%.2f\n", count, count * price);
    return 0;
}''',
    r'''count=3 total=7.50''',
  ),
  'c_conditions': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    int score = 72;
    if (score >= 60) {
        printf("pass\n");
    } else {
        printf("fail\n");
    }
    return 0;
}''',
    r'''pass''',
  ),
  'c_loops': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    int sum = 0;
    for (int i = 1; i <= 5; i++) {
        sum += i;
    }
    printf("sum=%d\n", sum);
    return 0;
}''',
    r'''sum=15''',
  ),
  'c_functions_intro': P0Example(
    'c',
    r'''#include <stdio.h>

int square(int n) { return n * n; }

int main(void) {
    printf("square(7)=%d\n", square(7));
    return 0;
}''',
    r'''square(7)=49''',
  ),

  // === C++ ===
  'cpp_first_program': P0Example(
    'cpp',
    r'''#include <iostream>

int main() {
    std::cout << "hello from C++\n";
    return 0;
}''',
    r'''hello from C++''',
  ),
  'cpp_variables_io': P0Example(
    'cpp',
    r'''#include <iostream>
#include <string>

int main() {
    std::string name = "Ada";
    int year = 1815;
    std::cout << name << " born in " << year << "\n";
    return 0;
}''',
    r'''Ada born in 1815''',
  ),
  'cpp_conditions': P0Example(
    'cpp',
    r'''#include <iostream>

int main() {
    int temperature = 31;
    std::cout << (temperature > 30 ? "hot" : "normal") << "\n";
    return 0;
}''',
    r'''hot''',
  ),
  'cpp_loops': P0Example(
    'cpp',
    r'''#include <iostream>

int main() {
    int total = 0;
    for (int i = 1; i <= 5; ++i) {
        total += i;
    }
    std::cout << "total=" << total << "\n";
    return 0;
}''',
    r'''total=15''',
  ),
  'cpp_functions_intro': P0Example(
    'cpp',
    r'''#include <iostream>

int square(int n) { return n * n; }

int main() {
    std::cout << "square(7)=" << square(7) << "\n";
    return 0;
}''',
    r'''square(7)=49''',
  ),
  'cpp_move_semantics': P0Example(
    'cpp',
    r'''#include <iostream>
#include <string>
#include <utility>

int main() {
    std::string source = "payload";
    std::string target = std::move(source);
    std::cout << "target=" << target << "\n";
    return 0;
}''',
    r'''target=payload''',
  ),
  'cpp_concepts_ranges': P0Example(
    'cpp',
    r'''#include <concepts>
#include <iostream>

template <std::integral T>
T twice(T value) { return value + value; }

int main() {
    std::cout << twice(21) << "\n";
    return 0;
}''',
    r'''42''',
  ),
  'cpp_concurrency_atomics': P0Example(
    'cpp',
    r'''#include <atomic>
#include <iostream>
#include <thread>

int main() {
    std::atomic<int> counter{0};
    std::thread worker([&counter] {
        for (int i = 0; i < 1000; ++i) counter.fetch_add(1);
    });
    worker.join();
    std::cout << "counter=" << counter.load() << "\n";
    return 0;
}''',
    r'''counter=1000''',
  ),

  // === C# ===
  'csharp_dotnet_first': P0Example(
    'csharp',
    r'''Console.WriteLine("hello from C#");''',
    r'''hello from C#''',
  ),
  'csharp_variables_input': P0Example(
    'csharp',
    r'''var name = "Ada";
int year = 1815;
Console.WriteLine($"{name} born in {year}");''',
    r'''Ada born in 1815''',
  ),
  'csharp_conditions': P0Example(
    'csharp',
    r'''int temperature = 31;
Console.WriteLine(temperature > 30 ? "hot" : "normal");''',
    r'''hot''',
  ),
  'csharp_loops': P0Example(
    'csharp',
    r'''int total = 0;
for (int i = 1; i <= 5; i++)
{
    total += i;
}
Console.WriteLine($"total={total}");''',
    r'''total=15''',
  ),
  'csharp_methods_intro': P0Example(
    'csharp',
    r'''static int Square(int n) => n * n;

Console.WriteLine($"square(7)={Square(7)}");''',
    r'''square(7)=49''',
  ),
  'csharp_records_patterns': P0Example(
    'csharp',
    r'''record Point(int X, int Y);

var point = new Point(2, 3);
var label = point switch
{
    (0, 0) => "origin",
    (_, 0) => "x-axis",
    _ => "plane",
};
Console.WriteLine($"{point} -> {label}");''',
    r'''Point { X = 2, Y = 3 } -> plane''',
  ),
  'csharp_async_streams': P0Example(
    'csharp',
    r'''async IAsyncEnumerable<int> Countdown(int from)
{
    for (int i = from; i > 0; i--)
    {
        await Task.Delay(10);
        yield return i;
    }
}

await foreach (var value in Countdown(3))
{
    Console.WriteLine(value);
}''',
    r'''3
2
1''',
  ),
  'csharp_gc_performance': P0Example(
    'csharp',
    r'''Span<int> values = stackalloc int[4];
for (int i = 0; i < values.Length; i++)
{
    values[i] = i * i;
}
Console.WriteLine(string.Join(",", values.ToArray()));''',
    r'''0,1,4,9''',
  ),

  // === Java ===
  'java_first_class': P0Example(
    'java',
    r'''public class Main {
    public static void main(String[] args) {
        System.out.println("hello from Java");
    }
}''',
    r'''hello from Java''',
  ),
  'java_variables_output': P0Example(
    'java',
    r'''public class Main {
    public static void main(String[] args) {
        String name = "Ada";
        int year = 1815;
        System.out.printf("%s born in %d%n", name, year);
    }
}''',
    r'''Ada born in 1815''',
  ),
  'java_conditions': P0Example(
    'java',
    r'''public class Main {
    public static void main(String[] args) {
        int temperature = 31;
        System.out.println(temperature > 30 ? "hot" : "normal");
    }
}''',
    r'''hot''',
  ),
  'java_loops': P0Example(
    'java',
    r'''public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i <= 5; i++) {
            total += i;
        }
        System.out.println("total=" + total);
    }
}''',
    r'''total=15''',
  ),
  'java_methods_intro': P0Example(
    'java',
    r'''public class Main {
    static int square(int n) {
        return n * n;
    }

    public static void main(String[] args) {
        System.out.println("square(7)=" + square(7));
    }
}''',
    r'''square(7)=49''',
  ),
  'java_modern_features': P0Example(
    'java',
    r'''record Point(int x, int y) {}

public class Main {
    public static void main(String[] args) {
        Object value = new Point(2, 3);
        String label = switch (value) {
            case Point(int x, int y) when x == 0 && y == 0 -> "origin";
            case Point(int x, int y) -> "point " + x + "," + y;
            default -> "unknown";
        };
        System.out.println(label);
    }
}''',
    r'''point 2,3''',
  ),
  'java_virtual_threads': P0Example(
    'java',
    r'''import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) throws Exception {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var future = executor.submit(() -> "virtual-thread-ok");
            System.out.println(future.get());
        }
    }
}''',
    r'''virtual-thread-ok''',
  ),
  'java_gc_tuning': P0Example(
    'java',
    r'''public class Main {
    public static void main(String[] args) {
        Runtime runtime = Runtime.getRuntime();
        System.out.println("heap>0: " + (runtime.maxMemory() > 0));
    }
}''',
    r'''heap>0: true''',
  ),

  // === Kotlin ===
  'kotlin_first_program': P0Example(
    'kotlin',
    r'''fun main() {
    println("hello from Kotlin")
}''',
    r'''hello from Kotlin''',
  ),
  'kotlin_variables_null': P0Example(
    'kotlin',
    r'''fun main() {
    val name: String? = "Ada"
    println(name?.length ?: 0)
}''',
    r'''3''',
  ),
  'kotlin_conditions': P0Example(
    'kotlin',
    r'''fun main() {
    val temperature = 31
    println(if (temperature > 30) "hot" else "normal")
}''',
    r'''hot''',
  ),
  'kotlin_loops': P0Example(
    'kotlin',
    r'''fun main() {
    var total = 0
    for (i in 1..5) {
        total += i
    }
    println("total=$total")
}''',
    r'''total=15''',
  ),
  'kotlin_functions_intro': P0Example(
    'kotlin',
    r'''fun square(n: Int) = n * n

fun main() {
    println("square(7)=${square(7)}")
}''',
    r'''square(7)=49''',
  ),
  'kotlin_basics': P0Example(
    'kotlin',
    r'''fun main() {
    val name = "Ada"
    val year = 1815
    println("$name born in $year")
}''',
    r'''Ada born in 1815''',
  ),
  'kotlin_functions': P0Example(
    'kotlin',
    r'''fun main() {
    val numbers = listOf(1, 2, 3, 4)
    val doubled = numbers.map { it * 2 }
    println(doubled.joinToString(","))
}''',
    r'''2,4,6,8''',
  ),
  'kotlin_oop': P0Example(
    'kotlin',
    r'''class Counter(private var value: Int = 0) {
    fun increment() {
        value++
    }

    override fun toString() = "counter=$value"
}

fun main() {
    val counter = Counter()
    repeat(3) { counter.increment() }
    println(counter)
}''',
    r'''counter=3''',
  ),
  'kotlin_collections': P0Example(
    'kotlin',
    r'''fun main() {
    val scores = mapOf("a" to 90, "b" to 72)
    println(scores.filterValues { it >= 80 }.keys)
}''',
    r'''[a]''',
  ),
  'kotlin_coroutines': P0Example(
    'kotlin',
    r'''import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

fun main() = runBlocking {
    val value = withContext(Dispatchers.Default) { 6 * 7 }
    println("answer=$value")
}''',
    r'''answer=42''',
  ),
  'kotlin_android': P0Example(
    'kotlin',
    r'''data class UiState(val title: String, val loading: Boolean = false)

fun render(state: UiState) = if (state.loading) "loading" else state.title

fun main() {
    println(render(UiState(title = "课程列表")))
}''',
    r'''课程列表''',
  ),
  'kotlin_testing': P0Example(
    'kotlin',
    r'''fun square(n: Int) = n * n

fun main() {
    check(square(7) == 49) { "square(7) 应该是 49" }
    println("test passed")
}''',
    r'''test passed''',
  ),
  'kotlin_project': P0Example(
    'kotlin',
    r'''data class Task(val title: String, val done: Boolean = false)

fun main() {
    val tasks = listOf(Task("读一节教程"), Task("跑一个示例", done = true))
    println(tasks.count { it.done })
}''',
    r'''1''',
  ),

  // === Swift ===
  'swift_first_program': P0Example(
    'swift',
    r'''print("hello from Swift")''',
    r'''hello from Swift''',
  ),
  'swift_constants_variables': P0Example(
    'swift',
    r'''let name = "Ada"
var year = 1815
year += 1
print("\(name) \(year)")''',
    r'''Ada 1816''',
  ),
  'swift_conditions': P0Example(
    'swift',
    r'''let temperature = 31
print(temperature > 30 ? "hot" : "normal")''',
    r'''hot''',
  ),
  'swift_loops': P0Example(
    'swift',
    r'''var total = 0
for i in 1...5 {
    total += i
}
print("total=\(total)")''',
    r'''total=15''',
  ),
  'swift_functions_intro': P0Example(
    'swift',
    r'''func square(_ n: Int) -> Int { n * n }

print("square(7)=\(square(7))")''',
    r'''square(7)=49''',
  ),
  'swift_basics': P0Example(
    'swift',
    r'''let nickname: String? = "ada"
print(nickname?.uppercased() ?? "none")''',
    r'''ADA''',
  ),
  'swift_functions': P0Example(
    'swift',
    r'''protocol Shape {
    func area() -> Int
}

struct Square: Shape {
    let side: Int
    func area() -> Int { side * side }
}

print(Square(side: 7).area())''',
    r'''49''',
  ),
  'swift_oop': P0Example(
    'swift',
    r'''class Counter {
    var value = 0
    func increment() { value += 1 }
}

let counter = Counter()
counter.increment()
counter.increment()
print("counter=\(counter.value)")''',
    r'''counter=2''',
  ),
  'swift_collections': P0Example(
    'swift',
    r'''let scores = ["a": 90, "b": 72]
let passed = scores.filter { $0.value >= 80 }.keys.sorted()
print(passed)''',
    r'''["a"]''',
  ),
  'swift_async': P0Example(
    'swift',
    r'''func fetchValue() async -> Int { 42 }

@main
struct App {
    static func main() async {
        print("answer=\(await fetchValue())")
    }
}''',
    r'''answer=42''',
  ),
  'swift_swiftui': P0Example(
    'swift',
    r'''struct CounterView: View {
    @State private var count = 0

    var body: some View {
        Button("count=\(count)") { count += 1 }
    }
}''',
    r'''界面显示一个按钮：初始文案为 count=0，每次点击后数字加一''',
  ),
  'swift_testing': P0Example(
    'swift',
    r'''func square(_ n: Int) -> Int { n * n }

assert(square(7) == 49)
print("test passed")''',
    r'''test passed''',
  ),
  'swift_project': P0Example(
    'swift',
    r'''struct Task {
    let title: String
    var done = false
}

let tasks = [Task(title: "读教程"), Task(title: "写代码", done: true)]
print(tasks.filter { $0.done }.count)''',
    r'''1''',
  ),

  // === JavaScript ===
  'js_console_start': P0Example(
    'javascript',
    r'''console.log("hello from JavaScript");''',
    r'''hello from JavaScript''',
  ),
  'js_variables_types_intro': P0Example(
    'javascript',
    r'''const name = "Ada";
const year = 1815;
console.log(`${name} born in ${year}`);''',
    r'''Ada born in 1815''',
  ),
  'js_conditions_loops': P0Example(
    'javascript',
    r'''let total = 0;
for (let i = 1; i <= 5; i++) {
  total += i;
}
console.log(`total=${total}`);''',
    r'''total=15''',
  ),
  'js_functions_intro': P0Example(
    'javascript',
    r'''const square = (n) => n * n;
console.log(`square(7)=${square(7)}`);''',
    r'''square(7)=49''',
  ),
  'js_dom_intro': P0Example(
    'javascript',
    r'''const button = document.createElement("button");
button.textContent = "点击我";
document.body.append(button);
console.log(document.querySelector("button").textContent);''',
    r'''点击我''',
  ),
  'js_execution_context': P0Example(
    'javascript',
    r'''function makeCounter() {
  let count = 0;
  return () => ++count;
}

const next = makeCounter();
next();
next();
console.log(next());''',
    r'''3''',
  ),
  'js_memory_gc': P0Example(
    'javascript',
    r'''const tracked = new WeakSet();
let node = { id: 1 };
tracked.add(node);
console.log("tracked:", tracked.has(node));
node = null;
console.log("after release:", tracked.has(node));''',
    r'''tracked: true
after release: false''',
  ),
  'js_node_backend': P0Example(
    'javascript',
    r'''import http from "node:http";

const server = http.createServer((req, res) => {
  res.end(JSON.stringify({ path: req.url }));
});

server.listen(0, () => {
  console.log("listening");
  server.close();
});''',
    r'''listening''',
  ),

  // === TypeScript ===
  'ts_first_types': P0Example(
    'typescript',
    r'''const name: string = "Ada";
const year: number = 1815;
console.log(`${name} born in ${year}`);''',
    r'''Ada born in 1815''',
  ),
  'ts_basic_types': P0Example(
    'typescript',
    r'''let count: number = 3;
count += 1;
console.log(`count=${count}`);''',
    r'''count=4''',
  ),
  'ts_interface_intro': P0Example(
    'typescript',
    r'''interface Lesson {
  id: string;
  minutes: number;
}

const lesson: Lesson = { id: "ts-1", minutes: 15 };
console.log(`${lesson.id}:${lesson.minutes}`);''',
    r'''ts-1:15''',
  ),
  'ts_function_types': P0Example(
    'typescript',
    r'''type Formatter = (value: number) => string;

const format: Formatter = (value) => `#${value}`;
console.log(format(42));''',
    r'''#42''',
  ),
  'ts_arrays_objects': P0Example(
    'typescript',
    r'''const scores: Record<string, number> = { a: 90, b: 72 };
const passed = Object.entries(scores).filter(([, value]) => value >= 80);
console.log(passed.map(([key]) => key).join(","));''',
    r'''a''',
  ),
  'ts_type_level': P0Example(
    'typescript',
    r'''type Split<S extends string> = S extends `${infer Head},${infer Tail}`
  ? [Head, ...Split<Tail>]
  : [S];

const items: Split<"a,b,c"> = ["a", "b", "c"];
console.log(items.join("-"));''',
    r'''a-b-c''',
  ),
  'ts_runtime_validation': P0Example(
    'typescript',
    r'''function parsePort(value: unknown): number {
  const port = Number(value);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new RangeError(`invalid port: ${value}`);
  }
  return port;
}

console.log(parsePort("8080"));''',
    r'''8080''',
  ),
  'ts_performance': P0Example(
    'typescript',
    r'''const values = Array.from({ length: 1000 }, (_, i) => i);
const total = values.reduce((sum, value) => sum + value, 0);
console.log(`total=${total}`);''',
    r'''total=499500''',
  ),

  // === Shell ===
  'shell_first_script': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

echo "hello from bash"''',
    r'''hello from bash''',
  ),
  'shell_variables_args': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

name="${1:-world}"
echo "hello, ${name}"''',
    r'''hello, world''',
  ),
  'shell_conditions': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

count=3
if (( count > 2 )); then
  echo "count is large"
fi''',
    r'''count is large''',
  ),
  'shell_loops': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

total=0
for i in 1 2 3 4 5; do
  total=$((total + i))
done
echo "total=${total}"''',
    r'''total=15''',
  ),
  'shell_pipeline_intro': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

printf 'b\na\nc\n' | sort | paste -sd, -''',
    r'''a,b,c''',
  ),
  'shell_automation_advanced': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail

log() { printf '[%s] %s\n' "$1" "$2"; }

retry() {
  local attempts=0
  until "$@"; do
    attempts=$((attempts + 1))
    if (( attempts >= 3 )); then
      return 1
    fi
  done
}

retry true
log INFO "job done"''',
    r'''[INFO] job done''',
  ),
  'shell_portability': P0Example(
    'bash',
    r'''#!/bin/sh
set -eu

path="${1:-/tmp}"
if [ -d "$path" ]; then
  printf 'dir: %s\n' "$path"
else
  printf 'missing: %s\n' "$path"
fi''',
    r'''dir: /tmp''',
  ),
  'shell_security_hardening': P0Example(
    'bash',
    r'''#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

target="${workdir}/report.txt"
printf 'safe\n' > "$target"
if [[ -f "$target" ]]; then
  printf 'checked: %s\n' "$(basename "$target")"
fi''',
    r'''checked: report.txt''',
  ),

  // === Python ===
  'python_first_script': P0Example(
    'python',
    r'''print("hello from Python")''',
    r'''hello from Python''',
  ),
  'python_input_output': P0Example(
    'python',
    r'''name = input("名字：").strip() or "world"
print(f"hello, {name}")''',
    r'''（运行后输入 Ada）
名字：Ada
hello, Ada''',
  ),
  'python_if_else': P0Example(
    'python',
    r'''score = 72
if score >= 60:
    print("pass")
else:
    print("fail")''',
    r'''pass''',
  ),
  'python_loops': P0Example(
    'python',
    r'''total = 0
for number in range(1, 6):
    total += number
print(f"total={total}")''',
    r'''total=15''',
  ),
  'python_list_dict_basics': P0Example(
    'python',
    r'''lesson = {"id": "python-1", "minutes": 15}
print(lesson["id"], lesson["minutes"])''',
    r'''python-1 15''',
  ),
  'python_decorators_generators': P0Example(
    'python',
    r'''def trace(func):
    def wrapper(*args):
        print(f"call {func.__name__}")
        return func(*args)
    return wrapper


@trace
def square(n):
    return n * n


print(square(7))''',
    r'''call square
49''',
  ),
  'python_context_iterators': P0Example(
    'python',
    r'''class Counter:
    def __init__(self, limit):
        self.limit = limit
        self.value = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.value >= self.limit:
            raise StopIteration
        self.value += 1
        return self.value


print(list(Counter(3)))''',
    r'''[1, 2, 3]''',
  ),
  'python_packaging_performance': P0Example(
    'python',
    r'''from timeit import timeit

elapsed = timeit("sum(range(1000))", number=1000)
print(f"ok={elapsed > 0}")''',
    r'''ok=True''',
  ),

  // === Go ===
  'go_first_program': P0Example(
    'go',
    r'''package main

import "fmt"

func main() {
	fmt.Println("hello from Go")
}''',
    r'''hello from Go''',
  ),
  'go_variables_input': P0Example(
    'go',
    r'''package main

import "fmt"

func main() {
	name := "Ada"
	var year int = 1815
	fmt.Printf("%s born in %d\n", name, year)
}''',
    r'''Ada born in 1815''',
  ),
  'go_conditions': P0Example(
    'go',
    r'''package main

import "fmt"

func main() {
	temperature := 31
	if temperature > 30 {
		fmt.Println("hot")
	} else {
		fmt.Println("normal")
	}
}''',
    r'''hot''',
  ),
  'go_loops': P0Example(
    'go',
    r'''package main

import "fmt"

func main() {
	total := 0
	for i := 1; i <= 5; i++ {
		total += i
	}
	fmt.Println("total =", total)
}''',
    r'''total = 15''',
  ),
  'go_functions_intro': P0Example(
    'go',
    r'''package main

import "fmt"

func square(n int) int { return n * n }

func main() {
	fmt.Println("square(7) =", square(7))
}''',
    r'''square(7) = 49''',
  ),
  'go_generics_deep': P0Example(
    'go',
    r'''package main

import "fmt"

type Number interface{ ~int | ~float64 }

func Sum[T Number](values []T) T {
	var total T
	for _, value := range values {
		total += value
	}
	return total
}

func main() {
	fmt.Println(Sum([]int{1, 2, 3}))
}''',
    r'''6''',
  ),
  'go_profiling_deep': P0Example(
    'go',
    r'''package main

import (
	"fmt"
	"testing"
)

func BenchmarkConcat(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = fmt.Sprint("a", "b")
	}
}

func main() {
	result := testing.Benchmark(BenchmarkConcat)
	fmt.Println("rounds>0:", result.N > 0)
}''',
    r'''rounds>0: true''',
  ),
  'go_cloud_native_security': P0Example(
    'go',
    r'''package main

import (
	"fmt"
	"net/http"
	"time"
)

func main() {
	client := &http.Client{Timeout: 2 * time.Second}
	fmt.Println("timeout:", client.Timeout)
}''',
    r'''timeout: 2s''',
  ),

  // === Rust ===
  'rust_cargo_first': P0Example(
    'rust',
    r'''fn main() {
    println!("hello from Rust");
}''',
    r'''hello from Rust''',
  ),
  'rust_variables_mutability': P0Example(
    'rust',
    r'''fn main() {
    let mut count = 0;
    count += 1;
    println!("count={count}");
}''',
    r'''count=1''',
  ),
  'rust_conditions': P0Example(
    'rust',
    r'''fn main() {
    let temperature = 31;
    let state = if temperature > 30 { "hot" } else { "normal" };
    println!("{state}");
}''',
    r'''hot''',
  ),
  'rust_loops': P0Example(
    'rust',
    r'''fn main() {
    let mut total = 0;
    for i in 1..=5 {
        total += i;
    }
    println!("total={total}");
}''',
    r'''total=15''',
  ),
  'rust_functions_intro': P0Example(
    'rust',
    r'''fn square(n: i32) -> i32 {
    n * n
}

fn main() {
    println!("square(7)={}", square(7));
}''',
    r'''square(7)=49''',
  ),
  'rust_traits_generics': P0Example(
    'rust',
    r'''trait Doubler {
    fn double(&self) -> Self;
}

impl Doubler for i32 {
    fn double(&self) -> i32 {
        self * 2
    }
}

fn main() {
    println!("{}", 21.double());
}''',
    r'''42''',
  ),
  'rust_smart_pointers': P0Example(
    'rust',
    r'''use std::rc::Rc;

fn main() {
    let value = Rc::new(String::from("shared"));
    let clone = Rc::clone(&value);
    println!("count={}", Rc::strong_count(&value));
    drop(clone);
    println!("count={}", Rc::strong_count(&value));
}''',
    r'''count=2
count=1''',
  ),
  'rust_macros_wasm': P0Example(
    'rust',
    r'''macro_rules! twice {
    ($value:expr) => {
        $value * 2
    };
}

fn main() {
    println!("{}", twice!(21));
}''',
    r'''42''',
  ),

  // === C（进阶篇：原先被 Python 位运算片段污染） ===
  'c_basics': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    int value = 7;
    printf("%d squared is %d\n", value, value * value);
    return 0;
}''',
    r'''7 squared is 49''',
  ),
  'c_types': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    printf("int=%zu bytes, double=%zu bytes\n", sizeof(int), sizeof(double));
    return 0;
}''',
    r'''int=4 bytes, double=8 bytes''',
  ),
  'c_control_functions': P0Example(
    'c',
    r'''#include <stdio.h>

int classify(int value) {
    if (value < 0) return -1;
    if (value == 0) return 0;
    return 1;
}

int main(void) {
    printf("%d %d %d\n", classify(-5), classify(0), classify(7));
    return 0;
}''',
    r'''-1 0 1''',
  ),
  'c_pointers': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    int value = 42;
    int *pointer = &value;
    *pointer += 1;
    printf("value=%d\n", value);
    return 0;
}''',
    r'''value=43''',
  ),
  'c_arrays_strings': P0Example(
    'c',
    r'''#include <stdio.h>
#include <string.h>

int main(void) {
    char name[8] = "ada";
    printf("name=%s len=%zu\n", name, strlen(name));
    return 0;
}''',
    r'''name=ada len=3''',
  ),
  'c_structs': P0Example(
    'c',
    r'''#include <stdio.h>

struct Point {
    int x;
    int y;
};

int main(void) {
    struct Point point = {2, 3};
    printf("point=(%d,%d) size=%zu\n", point.x, point.y, sizeof(point));
    return 0;
}''',
    r'''point=(2,3) size=8''',
  ),
  'c_preprocessor': P0Example(
    'c',
    r'''#include <stdio.h>

#define SQUARE(x) ((x) * (x))

int main(void) {
    printf("SQUARE(7)=%d\n", SQUARE(7));
    return 0;
}''',
    r'''SQUARE(7)=49''',
  ),
  'c_files': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    FILE *file = fopen("notes.txt", "w");
    if (file == NULL) {
        perror("fopen");
        return 1;
    }
    fputs("hello file\n", file);
    fclose(file);
    printf("wrote notes.txt\n");
    return 0;
}''',
    r'''wrote notes.txt''',
  ),
  'c_debugging': P0Example(
    'c',
    r'''#include <assert.h>
#include <stdio.h>

int divide(int a, int b) {
    assert(b != 0);
    return a / b;
}

int main(void) {
    printf("result=%d\n", divide(42, 6));
    return 0;
}''',
    r'''result=7''',
  ),
  'c_project': P0Example(
    'c',
    r'''#include <stdio.h>

int main(void) {
    const char *tasks[] = {"read", "code", "test"};
    size_t count = sizeof(tasks) / sizeof(tasks[0]);
    for (size_t i = 0; i < count; i++) {
        printf("%zu: %s\n", i + 1, tasks[i]);
    }
    return 0;
}''',
    r'''1: read
2: code
3: test''',
  ),

  // === Flutter ===
  'flutter_widget_intro': P0Example(
    'dart',
    r'''import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hello Flutter')),
      ),
    ),
  );
}''',
    r'''屏幕中央显示一行文本 Hello Flutter''',
  ),
  'flutter_layout_intro': P0Example(
    'dart',
    r'''import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF2F6BFF))),
            SizedBox(height: 12, child: ColoredBox(color: Color(0xFFE7EAF0))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
          ],
        ),
      ),
    ),
  );
}''',
    r'''页面被分成上下两块等高的色块，中间是一条 12px 高的浅灰间隔''',
  ),

  // === 计算机基础 ===
  'fundamentals_pipeline': P0Example(
    'python',
    r'''stages = ["取指", "译码", "执行", "写回"]
for index, stage in enumerate(stages, start=1):
    print(f"第 {index} 级：{stage}")''',
    r'''第 1 级：取指
第 2 级：译码
第 3 级：执行
第 4 级：写回''',
  ),
  'fundamentals_simd': P0Example(
    'python',
    r'''values = [1.0, 2.0, 3.0, 4.0]
scaled = [value * 2 for value in values]
print(scaled)''',
    r'''[2.0, 4.0, 6.0, 8.0]''',
  ),
  'fundamentals_cache_coherence': P0Example(
    'python',
    r'''cache = {"core0": 1, "core1": 1}
cache["core0"] = 2
# core1 的缓存行失效后必须重新读取，否则会读到旧值
cache["core1"] = cache["core0"]
print(cache)''',
    r'''{'core0': 2, 'core1': 2}''',
  ),
  'fundamentals_storage_stack': P0Example(
    'python',
    r'''block = 4096
for size in (100, 4096, 8192):
    amplification = max(1, -(-size // block))
    print(f"{size} 字节 -> 写放大 {amplification}x")''',
    r'''100 字节 -> 写放大 1x
4096 字节 -> 写放大 1x
8192 字节 -> 写放大 2x''',
  ),
  'fundamentals_embedded_iot': P0Example(
    'python',
    r'''state = "idle"
for tick in range(1, 4):
    state = "sample" if tick % 2 else "send"
    print(f"tick {tick}: {state}")''',
    r'''tick 1: sample
tick 2: send
tick 3: sample''',
  ),
  'fundamentals_architecture_case': P0Example(
    'python',
    r'''def speedup(parallel_fraction, factor):
    return 1 / ((1 - parallel_fraction) + parallel_fraction / factor)


print(round(speedup(0.5, 4), 2))''',
    r'''1.6''',
  ),

  // === 数据库 ===
  'db_postgresql_deep': P0Example(
    'sql',
    r'''WITH events(day, kind) AS (
  VALUES (DATE '2026-10-01', 'click'),
         (DATE '2026-10-01', 'view'),
         (DATE '2026-10-02', 'click')
)
SELECT day, count(*) AS events
FROM events
GROUP BY day
ORDER BY day;''',
    r'''day        | events
2026-10-01 |      2
2026-10-02 |      1''',
  ),
  'db_backup_recovery': P0Example(
    'sql',
    r'''WITH wal(lsn, applied) AS (
  VALUES (1, true), (2, true), (3, false)
)
SELECT max(lsn) FILTER (WHERE applied) AS last_applied,
       count(*) FILTER (WHERE NOT applied) AS pending
FROM wal;''',
    r'''last_applied | pending
            2 |       1''',
  ),
  'db_graph': P0Example(
    'sql',
    r'''WITH RECURSIVE edges(src, dst) AS (
  VALUES ('a', 'b'), ('b', 'c'), ('c', 'd')
), walk(node, depth) AS (
  SELECT 'a', 0
  UNION ALL
  SELECT edges.dst, walk.depth + 1
  FROM edges
  JOIN walk ON edges.src = walk.node
)
SELECT node, depth FROM walk ORDER BY depth;''',
    r'''node | depth
a    |     0
b    |     1
c    |     2
d    |     3''',
  ),
  'db_time_series': P0Example(
    'sql',
    r'''WITH samples(ts, value) AS (
  VALUES (TIMESTAMP '2026-10-05 10:00', 12.0),
         (TIMESTAMP '2026-10-05 10:05', 15.0),
         (TIMESTAMP '2026-10-05 10:10', 9.0)
)
SELECT date_trunc('hour', ts) AS bucket, avg(value) AS avg_value
FROM samples
GROUP BY bucket;''',
    r'''bucket              | avg_value
2026-10-05 10:00:00 |      12.0''',
  ),
  'db_migration_governance': P0Example(
    'sql',
    r'''BEGIN;
ALTER TABLE lessons ADD COLUMN reviewed_at date;
COMMENT ON COLUMN lessons.reviewed_at IS '最后复核日期';
COMMIT;''',
    r'''BEGIN
ALTER TABLE
COMMENT
COMMIT''',
  ),
  'db_permissions_security': P0Example(
    'sql',
    r'''CREATE ROLE reader LOGIN PASSWORD 'change-me';
GRANT CONNECT ON DATABASE learn TO reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reader;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM reader;''',
    r'''CREATE ROLE
GRANT
GRANT
REVOKE''',
  ),

  // 文件名与 lesson id 不一致的课程（manifest: python_variables）
  'programming_python_variables': P0Example(
    'python',
    r'''name = "Ada"
age = 36
print(f"{name} is {age}")''',
    r'''Ada is 36''',
  ),

  // === 补齐的 18 篇入门课：此前仍是 print("hello") / result=5 占位 ===
  'binary_intro': P0Example(
    'python',
    r'''value = 0b1011
print(value, bin(11), hex(value))''',
    r'''11 0b1011 0xb''',
  ),
  'algorithm_intro': P0Example(
    'python',
    r'''def find_max(values):
    best = values[0]
    for value in values[1:]:
        if value > best:
            best = value
    return best

print(find_max([3, -1, 7, 2]))''',
    r'''7''',
  ),
  'ai_concept_intro': P0Example(
    'python',
    r'''def classify(task):
    return "生成式 AI" if "创作" in task else "传统 AI"

print(classify("请帮我创作一首诗"))
print(classify("识别这张图片里的猫"))''',
    r'''生成式 AI
传统 AI''',
  ),
  'git_intro': P0Example(
    'bash',
    r'''git init -q demo
cd demo
printf '# 学习笔记\n' > README.md
git add README.md
git -c user.name=learner -c user.email=learner@example.com commit -q -m "docs: 添加说明"
git log -1 --format=%s''',
    r'''docs: 添加说明''',
  ),
  'cli_intro': P0Example(
    'bash',
    r'''printf 'banana\napple\nbanana\n' | sort | uniq -c''',
    r'''      1 apple
      2 banana''',
  ),
  'ip_port_intro': P0Example(
    'bash',
    r'''python3 -m http.server 8000 --bind 127.0.0.1 >/dev/null 2>&1 &
server_pid=$!
sleep 1
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/
kill "$server_pid"''',
    r'''200''',
  ),
  'math_set_function_intro': P0Example(
    'python',
    r'''A = {1, 2, 3}
B = {3, 4}
print(sorted(A & B), sorted(A | B))''',
    r'''[3] [1, 2, 3, 4]''',
  ),
  'sql_table_intro': P0Example(
    'sql',
    r'''CREATE TABLE students (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
INSERT INTO students (id, name) VALUES (1, 'Ada');
SELECT id, name FROM students;''',
    r'''id | name
1  | Ada''',
  ),
  'computer_organization_intro': P0Example(
    'python',
    r'''memory = [0] * 4
memory[2] = 42
pc = 2
print(f"PC={pc}, MEM[2]={memory[pc]}")''',
    r'''PC=2, MEM[2]=42''',
  ),
  'network_layers_intro': P0Example(
    'python',
    r'''layers = ["应用层 HTTP", "传输层 TCP", "网络层 IP", "链路层 Ethernet"]
for layer in layers:
    print("封装 ->", layer)''',
    r'''封装 -> 应用层 HTTP
封装 -> 传输层 TCP
封装 -> 网络层 IP
封装 -> 链路层 Ethernet''',
  ),
  'process_thread_intro': P0Example(
    'python',
    r'''import threading

counter = 0
lock = threading.Lock()

def worker():
    global counter
    with lock:
        counter += 1

threads = [threading.Thread(target=worker) for _ in range(3)]
for thread in threads:
    thread.start()
for thread in threads:
    thread.join()
print(counter)''',
    r'''3''',
  ),
  'linear_search_intro': P0Example(
    'python',
    r'''def linear_search(values, target):
    for index, value in enumerate(values):
        if value == target:
            return index
    return -1

print(linear_search([5, 3, 8], 8))
print(linear_search([5, 3, 8], 7))''',
    r'''2
-1''',
  ),
  'prompt_intro': P0Example(
    'python',
    r'''prompt = {
    "任务": "把反馈分类为 bug 或 feature",
    "约束": "只输出 JSON",
    "输出格式": {"type": "bug | feature"},
}
print(prompt["任务"], prompt["约束"], prompt["输出格式"]["type"], sep=" | ")''',
    r'''把反馈分类为 bug 或 feature | 只输出 JSON | bug | feature''',
  ),
  'security_concept_intro': P0Example(
    'python',
    r'''asset = {"name": "用户数据库", "value": 5}
threat = {"name": "弱口令", "likelihood": 4}
vulnerability = {"name": "未启用多因素认证", "severity": 5}
risk = threat["likelihood"] * vulnerability["severity"]
print(asset["name"], threat["name"], risk)''',
    r'''用户数据库 弱口令 20''',
  ),
  'password_hash_intro': P0Example(
    'python',
    r'''import hashlib

password = b"abc"
digest = hashlib.sha256(password).hexdigest()
print(len(digest), digest[:12])''',
    r'''64 ba7816bf8f01''',
  ),
  'sql_query_intro': P0Example(
    'sql',
    r'''SELECT name, score
FROM students
WHERE score >= 60
ORDER BY score DESC;''',
    r'''name | score
Ada  | 92
Lin  | 75''',
  ),
  'css_selectors_intro': P0Example(
    'html',
    r'''<style>
  .notice { color: #0b57d0; font-weight: 600; }
</style>
<p class="notice">保存成功</p>''',
    r'''浏览器渲染为蓝色加粗文字：保存成功''',
  ),
  'html_tags_intro': P0Example(
    'html',
    r'''<h1>学习笔记</h1>
<p>今天完成了第一个 HTML 页面。</p>
<ul>
  <li>标题</li>
  <li>段落</li>
</ul>''',
    r'''页面显示一级标题“学习笔记”、一段文字和一个两项列表。''',
  ),

  // == INSERT POINT ==
};
