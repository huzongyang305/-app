# Time Complexity

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Estimated duration: 14 minutes

## Learning objectives

- It's not just a word that explains the complexity of time.
- The relationship between "time complexity", "big O," "complexity" and "space complexity" is clear, with one example.
- It's a knowledge system that can put back "calculations and data structures" to show the boundaries of adjacent themes.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: describe trends over time and scale.

## Pre-knowledge

- One lesson, " Flowing sequences", is completed; if available, self-measurement can be done directly in this course.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: Time complexity, Big O, complexity.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Why does it have to be complicated?

The same code operates on different computers for a different time, so we ignore the hardware differences and describe only ** the growth of running times with data size. This is how Big O stands.

## Large O

```text
O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)
```

Common code versus complexity:

```python
# O(1)：执行次数与 n 无关
def first(nums):
    return nums[0]

# O(n)：一次遍历
def total(nums):
    result = 0
    for x in nums:
        result += x
    return result

# O(n²)：嵌套两层循环
def pairs(nums):
    count = 0
    for a in nums:
        for b in nums:
            count += 1
    return count
```

## How?

1. Look at the top, ignores the constant and lower: ⟦1.
2. The sequence of execution takes the maximum complexity: 0 and 1 and the whole is 2.
3. Loop the number of italics, embedding them.
4. Recursively.

```python
# 对数复杂度：每次规模减半
def count_halving(n):
    steps = 0
    while n > 1:
        n = n // 2
        steps += 1
    return steps      # 约等于 log2(n)
```

## Best, worst and average.

Take the example of linear search:

```python
def find(nums, target):
    for i, value in enumerate(nums):
        if value == target:
            return i
    return -1
```

- Best case scenario: the first one is target, zero.
- Worst case scenario: Target at end or non-existent, zero.
- Average: approximately 0.

In the absence of an explanation, it is common to discuss **the worst time complexity.

## Space complexity

The complexity is not just a description of the time. An additional array of n lengths, and space complexity is zero; with only a few variables it's one.

```python
def copy_list(nums):
    return nums[:]        # 额外 O(n) 空间
```

## Complexity versus analytical methods

|Complexity| n=10 | n=1,000 | n=10⁶ |Typical algorithm|
| --- | --- | --- | --- | --- |
| O(1) | 1 | 1 | 1 |Hash search, array subscript|
| O(log n) | 4 | 10 | 20 |Two-point search, balance.|
| O(n) | 10 | 10³ | 10⁶ |Sort through, count out.|
| O(n log n) | 33 | 10⁴ | 2×10⁷ |Squeeze/consolidate, sort|
| O(n²) | 100 | 10⁶ | 10¹² |Bubbles, double cycles.|
| O(2ⁿ) | 1024 |Exploding|It's not gonna work.|Subset count, simple return.|

Empirical judgement: **n 20 available index scale, n 5,000 available O(n2), n 105 must (n log n) and below**.It is the most practical step to solve this problem by looking at the scale of data.

## Analysis and common miscalculation

1. Only the highest order: ⟦O(n2).
2. Looping, embedding; but separate analysis when the inner layer is dependent on the outer layer (e.g. O(n2/2)=O(n2)).
3. Recursive: ⟦O (n log n); fast-ordered worst 1O(n2).
4. Do not lose sight of hidden costs: stringing, slices, zero judgment, Hashi conflict and memory distribution can all change the actual complexity.
5. Equivalent: Dynamic array ⟦ may be O(n), but equally distributed as O(1).

## It's the end of this class.
In analysing the complexity, I asked myself two questions:** how many times basic operations were carried out** and ** how much extra space was opened**.

<!-- appendix:v1 -->

## Complicated scale.

|Complexity|Name|n=103 Scale|Typical algorithm|
| --- | --- | --- | --- |
| O(1) |Constant| 1 |Hash search, array subscript|
| O(log n) |logarithm|About 10|Two-point, balance tree.|
| O(n) |Linear| 1000 |I'll go through it once and for all.|
| O(n log n) |Linear log|Approximately 104|Collapse/Script, Stack|
| O(n²) |Square| 10⁶ |Flow/insert Sorting, Double Cycle|
| O(n³) |Cube| 10⁹ |PARK Matrix Multiplication, DP|
| O(2ⁿ) |Index|Large|Subset count, simple return.|
| O(n!) |Factorial|It's not gonna work.|Violence in total.|

Data structure comparison:

|Structure|Visits|Find|Insert|Delete|
| --- | --- | --- | --- | --- |
|Numeric| O(1) | O(n) | O(n) | O(n) |
|Chain| O(n) | O(n) |O(1)(known location)|O(1)(known location)|
|Hash.|Not applicable|Average O(1)|Average O(1)|Average O(1)|
|Balance Tree| O(log n) | O(log n) | O(log n) | O(log n) |
|Stack|O(1) Top| O(n) | O(log n) |O(log n)|

## Data size and algorithm selection

|n Size|Accept Complexity|Common practice|
| --- | --- | --- |
| ≤ 10 | O(n!) |All set, violent search.|
| ≤ 20 | O(2ⁿ) |State compression, sub-counting|
| ≤ 500 | O(n³) |Region DP, Floyd|
| ≤ 5000 | O(n²) |Double cycle, simple DP|
| ≤ 10⁶ | O(n log n) |Sort, split and stack.|
| ≤ 10⁸ | O(n) |One scan, prefix and|

## Analysis and optimization techniques

|Skills|Annotations|
| --- | --- |
|It's just the top level.|⟦ (n2)|
|Ignore Constants|It's the same level as ⟦1 but constant is important in engineering.|
|Embedded cycle multiplying, sequence adding|It's O (n)|
|Equivalence|Dynamic array ⟦1 (n), single worst, equal O(1)|
|Time change.|Hashi watch, caches, prefixes.|
|Early termination|I'll be right back.|
|Discrepancies|Sorted, Quick Select|

```python
import timeit

# 实测比空想更可靠：用 timeit 对比两种写法
setup = "data = list(range(10000))"
loop = "total = 0\nfor x in data:\n    total += x"
builtin = "total = sum(data)"

print(timeit.timeit(loop, setup=setup, number=1000))
print(timeit.timeit(builtin, setup=setup, number=1000))   # 通常快数倍
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Consider O2 (n2)|Complexity judgement error|Constant factor ignored, ⟦0 is still O(n)|
|Ignore the Python built-in function as C|It's more slow to write.|We're going to use the Zero, Zone, Quantum.|
|Think Hashi's forever.|Deterioration in times of serious conflict|Worst O(n), depending on Hash mass and load factor|
|Forget, ⟦0 is on the list.|Zero in the loop, cause O2.|We're going to use a zero.|
|Scroll a lot of content with string ⟦0|O(n2)|Use 0 or 1 ⟧ equivalent|
|I'll take it once.|It's got noise.|Multiwheel to fetch the statistical value|
|Ignore the complexity of space|Memory Spill|Assessing time and space.|
|I think it's going to be slower.|I don't think so.|Retrogression costs, but may be simpler; tailings optimized in some languages|
|Ignore Input Distribution|There's a big difference between the average and the worst.|Make it clear if the worst is acceptable.|
|Premature optimization|It's complicated, but small.|Let's parse the real hot spots.|

## Self-Detected List

- [ ] Can write common complexities and sort them by size.
- [ ] Can reverse acceptable complexity according to n's size.
- [ ] Knows the meaning of equal distribution complexity (dynamic array append).
- [ ] It's going to drop ⟦2 from O(n) to O(1).
- [ ] Measurement before optimization, not by perception.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of practice: Repeating, experimenting and delivering around "time complexity, big O." Each result is subject to scrutiny.

The change in the status of 8 elements is first calculated, then the number and complexity of operations are measured.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Time Complex?
2. Without it, what concrete consequences would there be?
3. What's it got to do with Big O?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Gives 8 to 12 manually constructed data, writes each step and counts the number of comparisons or exchanges.

Mission requests:

- The result must be checked, not just “I understand”.
- It's not like we have to go out there, but it doesn't make sense.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Time Complexity

**Summary:** Describe growth rates with Big O notation.

**Category:** Algorithms  
**Level:** Foundation
**Key terms:** Time Complexity, Big O, Complexity in Space, Performance

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: Any mainstream language (predominantly pseudocode and complexity)
- Source: Internal structured curriculum and engineering practices
- Related themes: Time complexity, Big O, complexity of space, performance
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- top50-rewrite:v1 -->

## Course excellence: Time complexity

### I. KNOWLEDGE

- ** Why the complexity is needed**: The same code operates on different computers for a different time, so we ignore hardware differences and only describe the trend of running times with data size. This is how Big O stands.
- ** Large O means**: O (1) < O(log n) < o(n) > O (no 2) < On!
- ** How to analyse: 1. Look at the top, ignore the constants and lower steps.
- **Best, worst and average.
- **Spatial Complexity**: Complication is more than just a description of time. An additional array of n lengths, space complexity is zero; with only a few variables it is one.
- ** Complicated comparison and analysis method: understanding its definition, input, output and failure boundary.
- **The analytical methods and common miscalculations**: 1. Only the highest ranking items are retained: ⟦O(n2).
- ** Complexity speed sheet: understanding its definition, input, output and failure boundaries.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|Why does it have to be complicated?|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Large O|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|How?|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Best, worst and average.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Space complexity|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Complexity versus analytical methods|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Analysis and common miscalculation|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Complicated scale.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. Why does it have to be complicated with the borderline?
2. What's the border between Big O and the adjacent subject?
3. How do you analyze the boundaries with each other?
4. What's the best, worst and average of borders with each other?
5. What's the boundary between space complexity and an adjacent subject?
6. What's the border between complexity and analysis?
7. What is the boundary between analysis and common miscalculation?
8. What's the limit to an adjacent subject?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Time Complexity** focuses on Describe growth rates with Big O notation.

### Learning Outcomes

- Explain what **Time Complexity** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Time Complexity**
- Relaid terms: Time Complexity, Big O, Complexity
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Why does it have to be complicated?|Why does it have to be complicated?|
|Large O|Large O|
|How?|How?|
|Best, worst and average.|Best, worst and average.|
|Space complexity|Space complexity|
|Complexity versus analytical methods|Complexity versus analytical methods|
|Analysis and common miscalculation|Analysis and common miscalculation|
|It's the end of this class.| Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

