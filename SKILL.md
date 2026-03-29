---
name: anti-test-theater
description: >
  Prevents AI agents from generating "test theater" — tests that mirror
  implementation instead of verifying requirements. Core capabilities:
  anti-pattern detection (over-mocking, happy-path-only, snapshot abuse,
  implementation-coupled assertions), mock decision trees, test granularity
  selection (unit/integration/e2e), and requirement-driven test writing
  workflows. Use when writing tests, generating test suites, reviewing
  test code, improving test quality, increasing meaningful code coverage,
  or working with vitest, jest, pytest, playwright, go test, mocha, junit,
  xunit, nunit, rspec, or any testing framework. Do NOT use for non-test
  code generation, documentation writing, or code refactoring that doesn't
  involve tests.
---

# Anti-Test-Theater

## Why This Matters

Tests that mirror implementation are worse than no tests. They create false confidence ("90% coverage!"), break on every refactor (maintenance burden), and catch zero real bugs (the test has the same logic error as the code). The goal of testing is to verify *requirements*, not to confirm the code does what it already does.

## 3 Core Principles

1. **Understand the requirement first, then test it** — because a test derived from implementation is a tautology. If the code has a bug, a test that copies its logic has the same bug.

2. **Mock boundaries, not internals** — because mocking the thing you're testing means you're testing the mock, not your code. Mock external HTTP APIs, payment providers, email senders. Use real code for everything you own.

3. **Name the test before writing the body** — because if you can't describe the expected behavior in one sentence, you don't know what you're testing yet. Vague names produce vague tests.

## Anti-Patterns to Detect and Avoid

### 1. Implementation Mirroring

Why it's bad: the test recomputes the same formula as the code. Both will be wrong in the same way.

```typescript
// ✗ BAD — same logic as implementation
const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0)
expect(calculateTotal(items)).toBe(expected)

// ✓ GOOD — expected value computed by hand
expect(calculateTotal([{ price: 10, qty: 2 }, { price: 5, qty: 3 }])).toBe(35)
```

### 2. Over-Mocking

Why it's bad: when you mock the database and only assert `mockDb.create.toHaveBeenCalled()`, you've proven nothing about whether the data was actually persisted correctly.

```typescript
// ✗ BAD — tests the mock, not the service
expect(mockDb.create).toHaveBeenCalledWith({ name: 'Alice' })

// ✓ GOOD — real DB, real verification
const user = await service.create({ name: 'Alice' })
expect(await db.users.findById(user.id)).toMatchObject({ name: 'Alice' })
```

### 3. Happy Path Only

Why it's bad: the success case rarely has bugs. Real bugs hide in error paths, edge cases, and concurrent operations.

```typescript
// ✗ BAD — only tests success
test('login succeeds', ...)

// ✓ GOOD — tests the interesting failures
test('returns 401 for wrong password')
test('returns 400 for empty password')
test('returns 429 after 5 failed attempts')
```

### 4. Snapshot Abuse

Why it's bad: nobody reads snapshot diffs. They get blindly updated with `--update-snapshot` forever, catching zero regressions.

```typescript
// ✗ BAD
expect(container).toMatchSnapshot()

// ✓ GOOD — assert the specific thing that matters
expect(screen.getByTestId('total-revenue')).toHaveTextContent('$50,000')
```

### 5. Testing Framework Internals

Why it's bad: `render(<Component />)` without assertions tests React, not your component.

### 6. Brittle Selectors

Why it's bad: `querySelector('div > form > div:nth-child(3) > button')` breaks when any parent element changes. Use `getByRole('button', { name: /submit/i })`.

### 7. Flaky Async

Why it's bad: `setTimeout(2000)` is a race condition. Use `await screen.findByText('Alice')` or `waitFor()`.

## Mock Decision Table

| Dependency | Unit test | Integration test | Why |
|-----------|-----------|-----------------|-----|
| External HTTP API | Mock (msw/nock) | Mock or sandbox | Slow, flaky, costs money |
| Database | In-memory SQLite | Real (testcontainers) | Need to test real queries |
| Pure function | Never mock | Never mock | No side effects, just call it |
| Time/randomness | Fake timers/seed | Fake timers/seed | Determinism |
| File system | Mock if testing logic | Real if testing I/O | Depends on what you're testing |
| **Subject under test** | **Never mock** | **Never mock** | **You'd be testing the mock** |

## Test Granularity

| What you're testing | Type | Ratio | Why this type |
|--------------------|------|-------|---------------|
| Pure function, single method | Unit | ~60% | Fast, isolated, many edge cases |
| Components working together, API endpoint, DB query | Integration | ~35% | Catches wiring bugs mocks miss |
| Critical user journey end-to-end | E2E | ~5% | Expensive but catches real UX bugs |
| Not sure? | Integration | — | Better to test real interactions than mock everything |

## Writing Tests — Workflow

### Step 1: Identify the requirement

Before writing any test, answer: **what is this code supposed to do?**

Read the function signature, JSDoc, PR description, or ticket. If there's no spec, **ask the user before writing tests** — don't infer requirements from the implementation.

### Step 2: List behaviors to test

For each requirement:
- Happy path (normal input → expected output)
- Edge cases (empty, null, zero, max values, unicode, very long strings)
- Error cases (invalid input, missing dependencies, network failure, timeout)
- Security cases (unauthorized access, injection, overflow)

### Step 3: Write test names first, get agreement

```typescript
describe('TransferService.transfer', () => {
  test('transfers amount between accounts')
  test('fails if sender has insufficient balance')
  test('fails if sender equals receiver')
  test('fails if amount is zero or negative')
  test('is atomic — both update or neither does')
})
```

**Validation:** Present the test names to the user before writing bodies. This catches misunderstandings early.

### Step 4: Write bodies, then verify each test catches a real bug

For each test, ask: if the implementation had [specific bug], would this test fail?

- If the function silently returns null instead of throwing → would this test catch it?
- If input validation is missing → would this test catch it?
- If there's an off-by-one error → would this test catch it?

If the answer is no for any of these, the test is theater. Rewrite it.

## Test Naming Convention

```
test('[action] [expected result] [condition]')

test('returns 401 when token is expired')
test('creates order with correct total when cart has multiple items')
test('throws ValidationError when email format is invalid')
```

Never: `test('works correctly')`, `test('should handle edge case')`, `test('test1')`

## Language-Specific Patterns

Before writing tests for a specific framework, consult the relevant reference:

- **React/Vue/Playwright:** See `reference/frontend-testing.md` for component testing, form testing, msw API mocking, and E2E patterns
- **Node.js/Python API:** See `reference/api-testing.md` for supertest, database testing, concurrency testing, and error response patterns
- **Go:** See `reference/go-testing.md` for table-driven tests, httptest, t.Helper(), build tags, and testcontainers
- **Java:** See `reference/java-testing.md` for JUnit 5 parameterized tests, Mockito boundaries, and Spring Boot integration tests
- **C#:** See `reference/csharp-testing.md` for xUnit Theory tests, NSubstitute boundaries, and ASP.NET WebApplicationFactory
