---
name: anti-test-theater
description: >
  Prevents AI agents from generating "test theater" — tests that mirror
  implementation instead of verifying requirements. Provides anti-pattern
  detection for over-mocking, happy-path-only coverage, snapshot abuse,
  and implementation-coupled assertions. Includes mock decision trees,
  test granularity selection (unit/integration/e2e), and requirement-driven
  test writing workflows. Use when writing tests, generating test suites,
  reviewing test code, improving test quality, increasing code coverage,
  or working with vitest, jest, pytest, playwright, go test, mocha, junit,
  xunit, nunit, rspec, or any testing framework.
---

# Anti-Test-Theater

**3 rules. Memorize these.**

1. Never write a test by looking at the implementation first — understand the *requirement*, then test *that*
2. Never mock the thing you're testing — mock external services, use real code for everything else
3. Write test names before test bodies — if you can't name it clearly, you don't know what you're testing

## Anti-Patterns — Do Not Produce These

### 1. Implementation Mirroring

The test recomputes the same logic as the implementation. If the code has a bug, the test has the same bug.

```typescript
// ✗ BAD
test('calculates total', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 3 }]
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  expect(calculateTotal(items)).toBe(expected)
})

// ✓ GOOD — expected value computed by hand, independent of implementation
test('calculates total from item prices and quantities', () => {
  expect(calculateTotal([{ price: 10, qty: 2 }, { price: 5, qty: 3 }])).toBe(35)
})
```

### 2. Over-Mocking

Mocking the thing you're testing. The test only proves you called the mock.

```typescript
// ✗ BAD
const mockDb = { create: vi.fn().mockResolvedValue({ id: 1, name: 'Alice' }) }
const service = new UserService(mockDb)
await service.create({ name: 'Alice' })
expect(mockDb.create).toHaveBeenCalledWith({ name: 'Alice' }) // tests nothing

// ✓ GOOD — real dependency, real verification
const db = createTestDatabase()
const service = new UserService(db)
const user = await service.create({ name: 'Alice' })
expect(await db.users.findById(user.id)).toMatchObject({ name: 'Alice' })
```

### 3. Happy Path Only

Only testing the success case. Real bugs live in failure modes.

```typescript
// ✗ BAD — one test, success only
test('login succeeds', async () => {
  expect((await login('user@test.com', 'pass')).token).toBeDefined()
})

// ✓ GOOD — test the interesting failures
test('returns 401 for wrong password')
test('returns 401 for non-existent email (same error, no info leak)')
test('returns 400 for empty password')
test('returns 429 after 5 failed attempts')
```

### 4. Testing Framework Internals

Testing that React renders, not that your component works.

```typescript
// ✗ BAD
test('renders without crashing', () => { render(<UserProfile />) })

// ✓ GOOD
test('shows user name after loading', async () => {
  render(<UserProfile userId={1} />)
  expect(await screen.findByText('Alice')).toBeInTheDocument()
})
```

### 5. Snapshot Abuse

Snapshot of entire component output. Any change breaks it. Nobody reads the diff.

```typescript
// ✗ BAD
expect(container).toMatchSnapshot()

// ✓ GOOD — assert specific things that matter
expect(screen.getByTestId('total-revenue')).toHaveTextContent('$50,000')
```

### 6. Brittle Selectors

```typescript
// ✗ BAD
container.querySelector('div > form > div:nth-child(3) > button')

// ✓ GOOD
screen.getByRole('button', { name: /submit/i })
```

### 7. Flaky Async

```typescript
// ✗ BAD
await new Promise(r => setTimeout(r, 2000))

// ✓ GOOD
await screen.findByText('Alice')
```

## Mock Decision Tree

| Dependency type | Unit test | Integration test |
|----------------|-----------|-----------------|
| External HTTP API | Mock (msw/nock) | Mock or real sandbox |
| Database | Mock or in-memory SQLite | Real (testcontainers) |
| Pure function | Never mock | Never mock |
| Time/randomness | Mock (fake timers) | Mock (fake timers) |
| File system | Mock if testing logic | Real if testing I/O |
| The subject under test | **Never mock** | **Never mock** |

**Rule: if you're mocking the thing you're testing, the test is worthless.**

## Test Granularity

| What you're testing | Test type | How many |
|--------------------|-----------|----------|
| Pure function, single method | Unit | Many (~60%) |
| Two+ components together, API endpoint, DB operation | Integration | Moderate (~35%) |
| Full user journey, critical path | E2E | Few (~5%) |
| Not sure? | Integration | Default to this |

## Writing Tests — 4-Step Process

### Step 1: Identify the requirement

Before writing any test, answer: **what is this code supposed to do?**

- Read the function signature, JSDoc, or PR description
- If there's no spec, **ask before writing tests**
- Never infer requirements from the implementation

### Step 2: List behaviors

For each requirement, list:
- Happy path (normal input → expected output)
- Edge cases (empty, null, zero, max, unicode)
- Error cases (invalid input, missing deps, network failure)
- Security cases (unauthorized, injection, overflow)

### Step 3: Write test names first

```typescript
describe('TransferService.transfer', () => {
  test('transfers amount between accounts')
  test('fails if sender has insufficient balance')
  test('fails if sender equals receiver')
  test('fails if amount is zero or negative')
  test('is atomic — both update or neither does')
})
```

Agree on test names before writing bodies.

### Step 4: Verify tests catch real bugs

For each test, ask: if the implementation had [specific bug], would this test catch it?

- Silent null return instead of throwing → caught?
- Missing input validation → caught?
- Off-by-one error → caught?

If the answer is no, the test is theater.

## Test Naming

```
test('[action] [expected result] [condition]')

test('returns 401 when token is expired')
test('creates order with correct total when cart has multiple items')
test('throws ValidationError when email format is invalid')
```

Never: `test('works correctly')`, `test('should handle edge case')`, `test('test1')`

## Additional Resources

For detailed examples by language/framework, see:
- [reference/frontend-testing.md](reference/frontend-testing.md) — React/Vue component testing patterns
- [reference/api-testing.md](reference/api-testing.md) — Backend API and database testing patterns
- [reference/go-testing.md](reference/go-testing.md) — Table-driven tests, httptest, concurrency, testcontainers
- [reference/java-testing.md](reference/java-testing.md) — JUnit 5, Mockito, Spring Boot patterns
- [reference/csharp-testing.md](reference/csharp-testing.md) — xUnit, NSubstitute, ASP.NET patterns
