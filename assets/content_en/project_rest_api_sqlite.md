# Project: REST API with SQLite Transactions

![Project: REST API with SQLite Transactions](images/remaining_project_rest_api_sqlite.webp)

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.

> Content update time: 2026-10-03 | Level: Advanced | Estimated time: 120 minutes

## Learning objectives

- Express an API contract with resources, status codes, request schemas and a single error model.
- Put the inventory check and the reservation insert inside one database transaction.
- Use a client-generated idempotency key plus a unique constraint to survive retries and restarts.
- Cover success, conflict, validation failure and retry with contract tests.

> One-sentence summary: build a testable, rollback-safe inventory reservation service that stays consistent when clients retry timeouts and multiple requests compete for the same stock.

## Prerequisites

- You can write a small HTTP service and call it from a test client.
- You understand primary keys, unique constraints and SQL transactions.
- You know why a timeout does not tell the client whether the server committed.
- You can read a Pydantic model or an equivalent request schema.
- You have run `pytest` against a database-backed test fixture.

## Project scenario

A warehouse system must expose an inventory reservation API. Clients retry requests after timeouts, and several requests may compete for the same SKU at the same time. The service must return a stable error structure and must keep reservation rows and inventory counts consistent on every failure path. A lost response, a duplicate submit or a cancelled reservation must never create or destroy stock silently.

The interesting part of this project is not the happy path. It is the set of guarantees around retries and concurrency: exactly-once effects for one idempotency key, no overselling under contention, and no partial state when any step fails.

## Architecture and data flow

```text
client -> HTTP layer (validation, auth, request id)
            |
            v
        use case (create / get / cancel)
            |
            v
        repository -> BEGIN IMMEDIATE -> conditional update -> insert/commit
            |                              |
            |                              v
            +---------------------- rollback on any failure
```

- The HTTP layer validates the request and maps domain errors to status codes; it never writes SQL.
- The use case owns the transaction boundary and decides which repository calls must succeed together.
- The repository encapsulates SQL statements, parameters and row mapping.
- A request identifier is attached to every response and log line so a client can correlate a retry chain.
- The database is the source of truth for idempotency; an in-memory cache is only an optimization.

## Scope and features

- [ ] `POST /reservations` creates a reservation and returns its identifier.
- [ ] `GET /reservations/{id}` returns the status and the reserved quantity.
- [ ] `GET /inventory/{sku}` returns the remaining available quantity.
- [ ] `DELETE /reservations/{id}` cancels a reservation that has not shipped and restores stock.
- [ ] Repeating a request with the same `Idempotency-Key` returns the original result instead of writing again.
- [ ] All errors share one JSON shape: `code`, `message`, `request_id` and optional `details`.
- [ ] A validation failure returns 422; an inventory conflict returns 409; an unknown resource returns 404.

## Implementation steps

### Step 1: Write the contract before the code

Describe each endpoint as a table: method, path, request schema, success status, error statuses and idempotency behavior. Define the error document once and reuse it. Writing the contract first prevents the code from inventing a new error shape per endpoint.

Evidence: an OpenAPI fragment or a Markdown table plus two example request/response pairs.

### Step 2: Design the tables and constraints

Create `inventory`, `reservations` and an optional `idempotency_keys` table. Put `CHECK (quantity > 0)` on the reservation quantity, a unique constraint on the idempotency key and a foreign key from the reservation to the SKU. Constraints are the last line of defense when two code paths race.

Evidence: the schema DDL committed to the repository and a test that inserts a duplicate key and receives an integrity error.

### Step 3: Implement the repository and the transaction boundary

Wrap the create operation in `BEGIN IMMEDIATE`. Perform a conditional update that subtracts stock only when enough is available, inspect the affected row count, and only then insert the reservation. If either statement fails, roll back both. Never split these statements across two connections.

Evidence: a test that forces the insert to fail and asserts that the inventory quantity is unchanged.

### Step 4: Implement create, read and cancel use cases

The create use case first looks up the idempotency key inside the transaction. If a completed record exists, it returns the stored response. The cancel use case loads the reservation with a row lock or an `UPDATE ... WHERE status = 'reserved'` guard, restores stock once, and writes a terminal status that makes a second cancel a no-op.

Evidence: tests for a duplicate submit, a cancel after shipping, and a repeated cancel.

### Step 5: Inject concurrency and duplicate requests

Run several clients against one SKU with limited stock and assert that exactly the available quantity is reserved. Then send the same idempotency key concurrently and assert that exactly one reservation row exists. Concurrency tests must reset the database to a known state before each run.

Evidence: a test report showing zero oversell and one row per idempotency key.

### Step 6: Record slow queries, conflicts and P95 latency

Log the statement name, duration, affected rows and outcome category. Track conflict counts separately from system errors so the team can tell a hot SKU from a broken service. Use `EXPLAIN QUERY PLAN` on the reservation lookup and keep an index on the columns used by the uniqueness rule.

Evidence: a short baseline table with query latency, conflict rate and the observed bottleneck.

## Key code

The DDL below makes the invariants explicit, and the transaction performs the check and the write as one unit. The comment about `changes()` marks the exact place where an oversell would otherwise be created.

```sql
CREATE TABLE inventory (
  sku TEXT PRIMARY KEY,
  available INTEGER NOT NULL CHECK (available >= 0)
);

CREATE TABLE reservations (
  id TEXT PRIMARY KEY,
  sku TEXT NOT NULL REFERENCES inventory(sku),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  status TEXT NOT NULL CHECK (status IN ('reserved', 'shipped', 'cancelled')),
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);

BEGIN IMMEDIATE;

UPDATE inventory
   SET available = available - :qty
 WHERE sku = :sku
   AND available >= :qty;

-- changes() = 0 means the conditional update matched nothing.
-- Raise an inventory_conflict and let the caller roll back.

INSERT INTO reservations (id, sku, quantity, status, idempotency_key, created_at)
VALUES (:id, :sku, :qty, 'reserved', :key, :now);

COMMIT;
```

```python
def create_reservation(conn, sku: str, qty: int, key: str, now: str) -> dict:
    existing = conn.execute(
        'SELECT id, status FROM reservations WHERE idempotency_key = ?', (key,)
    ).fetchone()
    if existing:
        return {'id': existing['id'], 'status': existing['status'], 'replayed': True}

    cursor = conn.execute(
        'UPDATE inventory SET available = available - ? '
        'WHERE sku = ? AND available >= ?',
        (qty, sku, qty),
    )
    if cursor.rowcount == 0:
        raise InventoryConflict(sku)

    reservation_id = new_id()
    conn.execute(
        'INSERT INTO reservations '
        '(id, sku, quantity, status, idempotency_key, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        (reservation_id, sku, qty, 'reserved', key, now),
    )
    return {'id': reservation_id, 'status': 'reserved', 'replayed': False}
```

The unique constraint on `idempotency_key` is what makes the guarantee survive a process restart. A dictionary in memory cannot protect a retry that arrives after the service is redeployed.

## Verification commands and expected output

```bash
pytest -q tests/test_reservations.py
curl -s -X POST localhost:8000/reservations \
  -H 'Content-Type: application/json' \
  -H 'Idempotency-Key: demo-001' \
  -d '{"sku":"SKU-1","quantity":2}'
curl -s localhost:8000/inventory/SKU-1
```

Expected evidence: the test summary shows the success, conflict, replay and cancel cases; the first POST returns a reservation identifier; the inventory endpoint shows exactly `available - 2`; sending the same POST again returns the same identifier with `replayed: true` and does not subtract stock a second time. A request for more than the available quantity returns 409 and leaves the inventory row unchanged.

## Suggested directory structure

```text
app/
  main.py            # application wiring
  api/
    routes.py        # HTTP resources and status mapping
    schemas.py       # request and response models
  domain/
    models.py        # reservation and inventory concepts
    errors.py        # conflict, not found, invalid state
  usecases/
    reserve.py       # transaction boundary for create
    cancel.py        # state machine and stock restore
  infra/
    db.py            # connection factory and migrations
    reservations.py  # SQL statements and row mapping
tests/
  test_contract.py
  test_concurrency.py
  test_migrations.py
```

The API layer maps domain errors to HTTP; the use case layer never imports the web framework. This keeps the business rules testable without a running server and makes a future transport change cheap.

## Quality gates

- [ ] Every endpoint has a contract test for its success path and at least one error path.
- [ ] The transaction test proves that a failed insert does not change inventory.
- [ ] A concurrency test proves that limited stock is never oversold.
- [ ] A retry test proves that one idempotency key creates exactly one reservation.
- [ ] Error responses contain a code, a safe message and a request identifier, but no SQL or stack trace.
- [ ] The migration script can build the schema from an empty database and is committed with the code.

## Security, cost and observability

- Validate `sku` against a documented pattern, bound the quantity to a sane maximum and reject negative values before SQL runs.
- Use parameterized statements only; never build SQL by string concatenation.
- Keep database credentials and API tokens out of the repository and rotate them through a documented process.
- Limit the connection pool and set a busy timeout so a hot SKU cannot exhaust every worker.
- Log request id, endpoint, status, duration and conflict category; do not log full request bodies.
- Track reservations per minute, conflict rate, P95/P99 latency and inventory drift as first-class signals.
- Record a small cost baseline: database size per 10k reservations and the write amplification of each transaction.

## Tests and acceptance

- A reservation with sufficient stock creates one row and subtracts the quantity exactly once.
- Insufficient stock returns 409 and inserts no reservation row.
- The same idempotency key returns the original reservation identifier on every retry.
- Cancelling a reserved order restores stock once; cancelling again does not add stock twice.
- Cancelling a shipped order returns 409 and leaves both the status and the inventory unchanged.
- Two concurrent requests for the last unit produce one success and one conflict.

### Acceptance record

| Check | Evidence | Result | Notes |
| --- | --- | --- | --- |
| Contract matches implementation | Contract test report | | |
| Transaction rolls back cleanly | Failure-injection test | | |
| Retry is idempotent | Duplicate-key test | | |
| Concurrency is safe | Parallel test output | | |

## Common pitfalls

| Problem | Cause | Fix |
| --- | --- | --- |
| Stock is oversold under load | The check and the update are separate statements | Use a conditional update inside one transaction |
| Internal details leak to clients | Exception text is returned directly | Map errors to a stable error document |
| Retries create duplicates after a restart | Idempotency keys live only in memory | Persist the key with a unique constraint |
| A shipped order can be cancelled | The cancel path does not check the state machine | Guard the update by status and return 409 |
| The service holds locks too long | External calls run inside the transaction | Finish the transaction before calling the network |

## Extension tasks

- Add a warehouse dimension and partition the stock by location.
- Generate a client from the OpenAPI document and run the same contract tests through it.
- Move from SQLite to PostgreSQL, keep the SQL portable and repeat the concurrency benchmark.
- Add a reservation expiry worker that releases stock after a timeout.
- Add a reconciliation job that compares reserved quantities with the reservation table nightly.

## Performance and failure drills

| Dimension | Baseline | Method | Failure signal |
| --- | --- | --- | --- |
| Write latency | P50/P95 for a single reservation | Increase concurrent writers | Latency rises or lock waits dominate |
| Throughput | Reservations per second | Push until CPU or disk saturates | Queue growth and timeouts |
| Contention | Conflicts per 1k requests | Point many clients at one SKU | Retry storm or lock timeout |
| Recovery | Time to restore consistency | Kill the process mid-transaction | Partial row or missing rollback |

Run at least one real drill: stop the service in the middle of a transaction, restart it, and verify that neither a partial reservation nor a lost inventory update exists. Compare the result with the expected behavior and update the tests if the drill revealed a gap.

## Practice exercises

### Exercise 1: Contract first (40 minutes)

Write the endpoint table and the shared error schema. Implement only `POST /reservations` and its contract tests.

Acceptance: a success response, a 409 for insufficient stock and a 422 for an invalid quantity.

### Exercise 2: Idempotent retry (40 minutes)

Add an `Idempotency-Key` header, persist it and prove that a retry returns the same reservation without a second decrement.

Acceptance: two identical requests produce one row and one inventory change.

### Exercise 3: Concurrency proof (60 minutes)

Write a test that launches several clients against limited stock and asserts zero oversell. Then explain which lock or conditional update made the result correct.

Acceptance: the test output shows exactly the available quantity reserved and the remaining count at zero.

## Summary

- A stable contract is a design artifact, not a byproduct of the implementation.
- Inventory and reservation state must change inside one transaction or not at all.
- Idempotency belongs in durable storage, because retries outlive processes.
- Concurrency tests are the only convincing evidence that a stock service cannot oversell.
- Conflict counts and latency percentiles belong in the operational dashboard from day one.

## References

- FastAPI documentation: https://fastapi.tiangolo.com/
- SQLite transactions: https://www.sqlite.org/lang_transaction.html
- SQLite foreign keys and constraints: https://www.sqlite.org/foreignkeys.html
- Pydantic documentation: https://docs.pydantic.dev/latest/
- HTTP status code registry: https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
