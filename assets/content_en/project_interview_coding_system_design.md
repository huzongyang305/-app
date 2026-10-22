# Interview Sprint: Coding and System Design

![Interview Sprint: Coding and System Design](images/remaining_project_interview_coding_system_design.webp)

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.

> Content update time: 2026-10-03 | Level: Advanced | Estimated time: 130 minutes

## Learning objectives

- Choose an algorithm pattern from the input size, data characteristics and failure boundaries.
- State the invariant, the complexity and the test cases before writing code.
- Run a system design answer through six steps: requirements, interface, data, capacity, reliability and monitoring.
- Explain bottlenecks, degradation, consistency and cost trade-offs under follow-up questions.

> One-sentence summary: practice arrays, hashing, sliding windows, trees, graphs, dynamic programming and system design with one repeatable interview framework.

## Prerequisites

- You can analyze the time and space complexity of a simple loop or recursive function.
- You know the standard operations of arrays, hash maps, stacks, queues and binary trees.
- You can write and run unit tests in Python.
- You can estimate requests per second and storage from a few given numbers.
- You are ready to narrate your reasoning instead of silently typing.

## Project scenario

You have limited time to complete one coding round and one system design round. The goal is not to memorize problems. The goal is to execute the same process every time: clarify inputs, outputs and constraints; write a minimal example; describe the brute-force solution and the optimization direction; code and verify the boundaries; then answer design follow-ups with capacity, reliability and trade-off reasoning.

The same framework works for an easy array question and for a multi-region service. Only the depth changes, not the order of operations.

## Architecture and data flow

```text
clarify -> minimal example -> brute force -> pattern -> invariant
   -> code -> boundary tests -> complexity -> follow-up trade-offs

system design: requirements -> interface -> data -> capacity
   -> reliability -> monitoring -> trade-offs
```

- Clarifying questions reduce rework: range, duplicates, empty input, sortedness, memory limit and expected call volume.
- The minimal example is a manual trace that exposes the invariant before code exists.
- The brute-force solution is a correctness baseline and a source of optimization ideas.
- Boundary tests cover empty, single-element, all-equal, maximum-size and adversarial inputs.
- The system design template ends with monitoring and trade-offs, because a design without failure handling is incomplete.

## Scope and features

- [ ] Prefix sums and frequency counting on arrays.
- [ ] Two pointers, sliding window and binary search on the answer.
- [ ] Tree traversal with recursion boundaries and an iterative rewrite.
- [ ] Graph shortest path, topological sort and union-find.
- [ ] Dynamic programming with state, transition, initialization and space optimization.
- [ ] System design capacity estimation and failure drills.
- [ ] A personal review log that records every mistake category.

## Implementation steps

### Step 1: Restate the problem and write two or three clarifying questions

Ask about the input size, the value range, duplicate elements, sortedness, the expected output format and whether the input can be modified. Write the answers next to the problem statement. This takes one minute and prevents the most expensive kind of rework.

Evidence: a written problem statement with constraints and two example cases.

### Step 2: Derive the answer by hand on a minimal example

Trace the smallest non-trivial input and write down the intermediate state after each step. The state you are tracking is usually the invariant of the final algorithm.

Evidence: a table with step number, index, state and decision for a five-element input.

### Step 3: State the brute-force solution and its complexity

Say the brute-force approach out loud, then state its time and space complexity. This creates a correctness anchor and makes the optimization goal explicit: remove repeated scanning, repeated computation or repeated allocation.

Evidence: one sentence for the approach and one sentence for the complexity.

### Step 4: Identify the reusable pattern and optimize the critical step

Map the bottleneck to a pattern: prefix sums for range queries, a hash map for lookups, a sliding window for contiguous constraints, binary search for monotonic predicates, BFS/DFS for graphs, or dynamic programming for overlapping subproblems. Write the invariant before coding.

Evidence: the pattern name, the invariant and the target complexity.

### Step 5: Code, then verify boundaries explicitly

After writing the solution, test empty input, a single element, all-equal values, a case where the window shrinks repeatedly, an unreachable node and the maximum input size. State the final complexity again after the code is correct.

Evidence: a short test table with input, expected output and the boundary it covers.

### Step 6: Complete one system design with the six-step template

Spend ten minutes on a whiteboard-style answer: functional and non-functional requirements, API shape, data model and storage, capacity estimate, reliability and failure handling, monitoring and trade-offs. Quantify at least two numbers, such as requests per second and storage per year.

Evidence: a one-page design outline with a data flow, two capacity numbers, one failure drill and one rejected alternative.

## Key code

The sliding-window solution below is a compact example of the whole framework: the invariant is written down, the left boundary never moves backwards, and the boundary cases are asserted next to the code.

```python
def longest_unique_substring(text: str) -> int:
    """Return the length of the longest substring without repeated characters.

    Invariant: the window [left, right] never contains a duplicate character.
    Complexity: O(n) time, O(min(n, alphabet)) space.
    """
    last_seen: dict[str, int] = {}
    left = 0
    best = 0
    for right, char in enumerate(text):
        if char in last_seen and last_seen[char] >= left:
            left = last_seen[char] + 1
        last_seen[char] = right
        best = max(best, right - left + 1)
    return best

assert longest_unique_substring('') == 0
assert longest_unique_substring('a') == 1
assert longest_unique_substring('aaaa') == 1
assert longest_unique_substring('abcabcbb') == 3
assert longest_unique_substring('abba') == 2
```

```python
from collections import deque

def topological_order(graph: dict[str, list[str]]) -> list[str]:
    """Return a topological order or raise when the graph contains a cycle."""
    indegree = {node: 0 for node in graph}
    for neighbors in graph.values():
        for node in neighbors:
            indegree[node] = indegree.get(node, 0) + 1

    queue = deque(node for node, degree in indegree.items() if degree == 0)
    order: list[str] = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph.get(node, []):
            indegree[neighbor] -= 1
            if indegree[neighbor] == 0:
                queue.append(neighbor)

    if len(order) != len(indegree):
        raise ValueError('graph contains a cycle')
    return order
```

Both examples show the same discipline: the invariant or precondition is stated first, the boundary cases are explicit, and the complexity claim is small enough to defend.

## Verification commands and expected output

```bash
python -m pytest -q tests/test_sliding_window.py
python -m pytest -q tests/test_graphs.py
python -m pytest -q tests/test_dp.py
```

Expected evidence: every test prints the case name and the covered boundary; the window tests include empty, single, all-equal and cross-window duplicates; the graph tests include an empty graph, a disconnected node and a cycle; the DP tests include the base case and the maximum-size case. Record which cases you initially missed in the review log.

## Suggested directory structure

```text
interview/
  patterns/
    arrays.py
    sliding_window.py
    trees.py
    graphs.py
    dp.py
  design/
    capacity.py
    templates.md
  notes/
    mistakes.md      # one line per missed boundary or concept
  tests/
    test_patterns.py
    test_edges.py
```

Keep the mistake log in the repository. Reviewing the categories you miss is more valuable than re-solving problems you already know.

## Quality gates

- [ ] Every solution states the invariant and the complexity before the code.
- [ ] Every solution has tests for empty, single-element and adversarial inputs.
- [ ] The review log records the mistake category, not only the problem name.
- [ ] A system design answer includes at least two quantified estimates.
- [ ] A system design answer includes one failure scenario and one rejected alternative.
- [ ] No answer relies on a memorized trick without explaining why it applies.

## Security, cost and observability

- In a design round, name the authentication boundary, the authorization model and where user input crosses a trust boundary.
- State where data is encrypted in transit and at rest, and which fields must be redacted from logs.
- Estimate cost per thousand requests and identify which component grows fastest with traffic.
- Define the metrics that would detect a partial failure: error rate, P95/P99 latency, queue depth and saturation.
- Describe one degradation mode, such as serving stale reads or rejecting low-priority traffic, and the user impact.
- Explain the consistency choice for the main data path and the cost of the alternative.

## Tests and acceptance

- Empty string, single character and all-repeated characters return the correct window length.
- The window's left boundary never moves backwards and the solution stays linear.
- Tree and graph exercises cover an empty structure, a cycle and an unreachable node.
- The DP exercise covers the base case, an overlapping subproblem and the maximum input size.
- A system design answer includes capacity estimates, a failure path and monitoring metrics.
- A recorded explanation covers clarify, brute force, invariant, code and boundary verification in order.

### Acceptance record

| Check | Evidence | Result | Notes |
| --- | --- | --- | --- |
| Pattern selection is justified | Written constraints and complexity | | |
| Boundary tests are complete | Test table output | | |
| Design has quantified estimates | Capacity numbers | | |
| Failure handling is explicit | Failure drill outline | | |

## Common pitfalls

| Problem | Cause | Fix |
| --- | --- | --- |
| Rework after coding starts | Range, duplicates and empty input were not clarified | Ask two or three clarifying questions first |
| The optimal solution sounds memorized | Only the final answer is explained | Start from the brute force and show the optimization step |
| Boundary bugs survive coding | The code was never tested beyond the sample | Test normal, boundary and counter-examples explicitly |
| The design is only a component diagram | Data flow, capacity and failure were skipped | Use the six-step template and quantify two numbers |
| The same mistake repeats across rounds | The review log records problems, not categories | Record the mistake category and the missing check |

## Extension tasks

- Solve three variants of each pattern and write one sentence about how they differ.
- Turn a system design answer into a ten-minute whiteboard script with timings.
- Record your explanation and mark every missing clarification or verification step.
- Build a spaced-repetition list of mistake categories and review it weekly.
- Pair with another learner and interview each other with a strict timer.

## Performance and failure drills

| Dimension | Baseline | Method | Failure signal |
| --- | --- | --- | --- |
| Coding time | Minutes per medium problem | Solve with a timer | Clarification or testing is skipped |
| Boundary coverage | Cases per solution | Compare with a checklist | Empty or duplicate input is missed |
| Design depth | Quantified estimates per answer | Review the whiteboard outline | Only components are named |
| Explanation clarity | Reviewer can restate the plan | Ask a peer to repeat it | The invariant or trade-off is missing |

Run one full mock round: 35 minutes of coding plus 35 minutes of system design, with a peer asking follow-up questions. Write down the first point where you lost structure, then practice that specific transition.

## Practice exercises

### Exercise 1: Pattern drill (40 minutes)

Solve one sliding-window problem and one binary-search problem. For each, write the constraints, brute force, invariant and boundary tests before coding.

Acceptance: two solutions with a complete written derivation and passing tests.

### Exercise 2: System design outline (40 minutes)

Design a URL shortener with the six-step template. Include requests per second, storage per year, one failure drill and one rejected alternative.

Acceptance: a one-page outline that another engineer can review without asking what the system does.

### Exercise 3: Mock interview (60 minutes)

Run a timed coding round and a timed design round with a peer. Ask for feedback on clarification, narration, testing and trade-off reasoning.

Acceptance: a written list of three concrete improvements for the next round.

## Summary

- A repeatable framework beats memorized answers because it survives unfamiliar problems.
- Clarifying constraints and writing the invariant prevent most rework.
- The brute force is a correctness baseline; the optimization must name what it removes.
- Boundary tests are part of the answer, not an optional extra.
- A system design answer is complete only when it includes capacity, failure handling, monitoring and trade-offs.

## References

- Big-O cheat sheet: https://www.bigocheatsheet.com/
- Python data structures documentation: https://docs.python.org/3/tutorial/datastructures.html
- System design primer: https://github.com/donnemartin/system-design-primer
- Latency numbers every programmer should know: https://gist.github.com/jboner/2841832
- LeetCode study plans: https://leetcode.com/studyplan/
