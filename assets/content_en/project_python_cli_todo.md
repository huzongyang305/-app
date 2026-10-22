# Project: Python CLI Todo Tool

![Project: Python CLI Todo Tool](images/remaining_project_python_cli_todo.webp)

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.

> Content update time: 2026-10-03 | Level: Advanced | Estimated time: 110 minutes

## Learning objectives

- Split command-line input, business rules and file persistence into modules that can be unit tested without spawning a process.
- Use a temporary file plus an atomic replace so an interrupted write never leaves a half-written JSON document.
- Separate argument errors, data errors and runtime errors with stable exit codes and machine-readable output.
- Ship an installable `pyproject.toml` entry point and verify it from a clean virtual environment.

> One-sentence summary: build an installable, testable, publishable command-line todo tool from an empty directory, covering argument parsing, atomic persistence, exit codes and packaging.

## Prerequisites

- You can create a virtual environment, install a package and run `pytest` from a terminal.
- You understand Python dictionaries, lists, exceptions and context managers.
- You have used `argparse` or another command-line parsing library at least once.
- You know how `pathlib.Path` differs from a plain string path.
- You can read a JSON document and explain why it must stay parseable at every moment.

## Project scenario

A small team needs a todo tool that does not depend on a server. It must support adding, listing, completing and deleting tasks while keeping all data in a local JSON file. If the process is killed halfway through a save, the previous file must remain readable. The tool must install from a clean environment, run its tests, and complete one full workflow from the command line.

This is deliberately a small product. The value of the exercise is not the feature list; it is the delivery discipline around a single, well-understood feature set. Every boundary in this project appears again in larger services: untrusted input arrives at the edge, business rules validate it, a storage adapter persists it, and an error model tells callers what happened without leaking internals.

## Architecture and data flow

```text
argv -> argument parser -> validated command object -> pure service functions
                                                          |
                                                          v
                                             repository (JSON + atomic replace)
                                                          |
                                                          v
                                             stdout / stderr + exit code
```

- The entry layer converts strings into typed values and rejects malformed input before any business rule runs.
- The domain layer receives plain Python objects and never reads `sys.argv` or prints directly.
- The repository layer owns the file path, the JSON encoding and the atomic write sequence.
- The output layer decides whether a result is human-readable text or `--json` for scripts.
- Error handling is centralized so every command maps failures to a documented exit code.

## Scope and features

- [ ] `add` appends a task with a stable, monotonically increasing identifier.
- [ ] `list` supports `--all`, `--pending` and `--done` filters.
- [ ] `done` marks one task complete and rejects unknown identifiers.
- [ ] `delete` removes one task and reports whether anything changed.
- [ ] Every command accepts `--json` so scripts can consume structured output.
- [ ] `--data-file` overrides the default path, which keeps tests isolated.
- [ ] `--version` prints the installed package version.

## Implementation steps

### Step 1: Define the task model and error types

Write down the fields of a task before writing any command: `id` (integer), `title` (non-empty string), `done` (boolean) and `created_at` (ISO-8601 string). Then define explicit errors such as `TaskNotFound`, `InvalidTitle` and `CorruptDataFile`. Explicit error classes make the exit-code mapping a table lookup instead of a chain of string comparisons.

Evidence for this step: a short design note plus a unit test that constructs a task and round-trips it through `json.dumps`.

### Step 2: Build the argument parser

Create a subparser for each command. Attach `--json` to every subcommand or to the shared parent parser. Validate that a title is not empty and that an identifier is a positive integer. Keep the parser thin: it may translate arguments into a dataclass, but it must not touch the filesystem.

Evidence for this step: `todo --help`, `todo add --help` and one test that calls `parser.parse_args` with a valid and an invalid command line.

### Step 3: Implement pure service functions

Implement `add_task(tasks, title)`, `complete_task(tasks, task_id)` and `delete_task(tasks, task_id)` as pure functions over an in-memory list. They return a new list or raise a domain error. Pure functions are fast to test, deterministic, and independent of the storage format.

Evidence for this step: tests for the empty list, the normal case, a duplicate title and an unknown identifier.

### Step 4: Persist with a temporary file and atomic replace

Create the temporary file in the same directory as the target so `os.replace` stays on one filesystem and is atomic. Flush the Python buffer, call `os.fsync` on the file descriptor, close the file, then replace the target. Remove the temporary file in a `finally` block if anything fails.

Evidence for this step: a test that monkeypatches `json.dump` to raise halfway and then asserts the original file still parses.

### Step 5: Map results and errors to exit codes

Use `0` for success, `1` for an unexpected runtime failure, `2` for an argument error and `3` for a domain or data error. Print human-readable messages to stderr and structured JSON to stdout when `--json` is set. Never print a traceback as the primary user-facing message.

Evidence for this step: a table-driven test that runs the CLI in a subprocess and checks both the exit code and the parsed JSON.

### Step 6: Package and verify from a clean environment

Declare the console script in `pyproject.toml`, build a wheel, create a fresh virtual environment, install the wheel and run `todo --help` plus one end-to-end workflow. Clean-environment verification catches missing package data and accidental reliance on the current working directory.

Evidence for this step: the install command, the `todo --version` output and a recorded end-to-end transcript.

## Key code

The repository below shows the whole persistence contract in one place: an in-memory task list goes in, a complete JSON document comes out, and the caller never observes a partial write.

```python
from pathlib import Path
import json
import os
import tempfile

DEFAULT_DATA = Path.home() / '.todo.json'

def load_tasks(path: Path) -> list[dict]:
    if not path.exists():
        return []
    text = path.read_text(encoding='utf-8')
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise CorruptDataFile(f'{path} is not valid JSON') from exc
    if not isinstance(data, list):
        raise CorruptDataFile(f'{path} must contain a JSON array')
    return data

def save_tasks(path: Path, tasks: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(dir=path.parent, prefix='.todo-')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as handle:
            json.dump(tasks, handle, ensure_ascii=False, indent=2)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)

def add_task(tasks: list[dict], title: str, now: str) -> tuple[list[dict], dict]:
    clean = title.strip()
    if not clean:
        raise InvalidTitle('title must not be empty')
    next_id = max((task['id'] for task in tasks), default=0) + 1
    task = {'id': next_id, 'title': clean, 'done': False, 'created_at': now}
    return [*tasks, task], task
```

Two details deserve attention. First, `next_id` is derived from the data rather than from `len(tasks)`; deleting the last task must not cause an identifier to be reused. Second, `os.fsync` is called before `os.replace`, so the new content is durable before the directory entry changes.

## Verification commands and expected output

Run the following commands in order and keep the real output in the project README or an implementation log. A verdict of "it works" is not evidence.

```bash
python -m venv .venv
. .venv/bin/activate
pip install -e '.[dev]'
pytest -q
todo --data-file /tmp/demo.json add "write the README" --json
todo --data-file /tmp/demo.json list --pending --json
todo --data-file /tmp/demo.json done 999 --json; echo "exit=$?"
```

The expected result contains four pieces of evidence: the test summary line, a created task with `"id": 1`, a pending list that includes that task, and a non-zero exit code with a structured not-found error for task `999`. Run the `add` command twice with different titles and confirm that identifiers never repeat and that the JSON file parses after every step.

## Suggested directory structure

```text
todo_tool/
  __init__.py
  cli.py            # argparse wiring and exit-code mapping
  models.py         # Task dataclass and domain errors
  service.py        # pure add / complete / delete functions
  repository.py     # JSON load, atomic save
  __main__.py       # python -m todo_tool support
tests/
  test_service.py
  test_repository.py
  test_cli.py
pyproject.toml
README.md
```

The dependency direction is one-way: `cli` imports `service`, `service` imports `models`, and only `repository` knows about the file system. A change to the storage format must not require a change to the command-line grammar.

## Quality gates

- [ ] `ruff check` or `flake8` passes with no new warnings.
- [ ] Every domain rule has a unit test; the repository has a failure-injection test.
- [ ] A subprocess test covers at least one success and one failure exit code.
- [ ] The wheel installs in a clean environment and the console script is on `PATH`.
- [ ] The README documents installation, usage, data location, backup and uninstall.
- [ ] No traceback, absolute user path or internal identifier is printed for expected errors.

## Security, cost and observability

- Treat the title as untrusted text: reject control characters, limit the length and never interpolate it into a shell command.
- Write the data file with permissions that do not expose private tasks to other users on a shared machine.
- Keep the tool offline by default; if a future version syncs remotely, the token belongs in an environment variable or keychain, not in the JSON file.
- Log the command name, duration and result category, but never log full task titles in a shared log.
- Bound memory use by reading the file once and rejecting documents above a documented size limit.
- Record a small performance baseline: number of tasks, file size and command duration, so regressions are visible.

## Tests and acceptance

- Adding two tasks and listing with `--json` returns a stable order and stable identifiers.
- Completing an unknown identifier exits non-zero and leaves the data file byte-for-byte unchanged.
- Simulated interruption during a save leaves the previous JSON document parseable.
- A clean `pip install -e .` in a fresh virtual environment exposes a working `todo` command.
- Deleting the final task and adding a new one never reuses a deleted identifier.
- Running the same `done` command twice is idempotent and reports the second call clearly.

### Acceptance record

| Check | Evidence | Result | Notes |
| --- | --- | --- | --- |
| Minimum path runs | Install and command transcript | | |
| Failure path recovers | Error output and exit code | | |
| Automated tests pass | `pytest` summary | | |
| Configuration is safe | Path and permission review | | |

## Common pitfalls

| Problem | Cause | Fix |
| --- | --- | --- |
| The JSON file becomes unreadable after a crash | The target file was truncated before the new content was complete | Write a sibling temporary file, fsync it, then `os.replace` |
| Tests interfere with each other | A module-level global holds the task list or default path | Pass the path and the list explicitly into every function |
| A script cannot tell failure from success | Every error returns exit code 0 | Define and document stable exit codes per error class |
| Only the happy path is tested | Empty data, duplicate identifiers and corrupt files reach users | Add boundary and failure-injection tests to the suite |
| Identifiers change after deletion | `id` is computed from `len(tasks)` | Compute the next identifier from the maximum existing identifier |

## Extension tasks

- Add an optional `due` date and an `--overdue` filter with timezone-aware comparisons.
- Abstract the repository behind an interface and add a SQLite backend without changing the CLI grammar.
- Add a `--format csv` exporter and test it against titles containing commas and quotes.
- Build the wheel in GitHub Actions, install it in a clean container and run the end-to-end test.
- Add structured logging behind `--verbose` and keep the default output unchanged.

## Performance and failure drills

| Dimension | Baseline | Method | Failure signal |
| --- | --- | --- | --- |
| Command latency | Record P50/P95 for 1k tasks | Generate 10x tasks and repeat each command | Latency grows faster than the data |
| File size | Record bytes per task | Insert long titles and unicode text | A single document exceeds the size limit |
| Recovery | Record time to restore a backup | Kill the process during a save | The target file is missing or unreadable |
| Concurrency | Record behavior of two processes | Run two writers against one file | Lost updates or duplicated identifiers |

At least one drill must be performed for real: write down the expected behavior, inject the failure, compare the observed behavior, and then improve the code or the documentation.

## Practice exercises

### Exercise 1: Minimum runnable version (40 minutes)

Implement `add` and `list` with a fixed data path. The tool must start, write valid JSON and print the created task.

Acceptance: a recorded command transcript and one repository unit test.

### Exercise 2: Failure path (40 minutes)

Inject a write failure and verify that the previous document survives. Then run `done` with an unknown identifier and verify the exit code and message.

Acceptance: the original file still parses and the error output contains no traceback.

### Exercise 3: Package it (60 minutes)

Add `pyproject.toml`, a console entry point and a `--version` flag. Build a wheel and install it in a fresh environment.

Acceptance: `todo --version` works outside the source directory and the full workflow still passes.

## Summary

- A small CLI becomes reliable when input, rules, storage and output are separate layers with explicit contracts.
- Atomic replacement is the cheapest way to make a local file store crash-safe.
- Exit codes and structured output turn a human tool into a dependable building block for scripts.
- Clean-environment installation exposes packaging mistakes that are invisible during development.
- Each step should leave behind a command, an output, a test or a short note that another engineer can reproduce.

## References

- Python documentation for `argparse`: https://docs.python.org/3/library/argparse.html
- Python documentation for `os.replace`: https://docs.python.org/3/library/os.html#os.replace
- Python packaging user guide: https://packaging.python.org/en/latest/tutorials/packaging-projects/
- pytest documentation: https://docs.pytest.org/en/stable/
