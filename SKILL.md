---
name: anti-test-theater
description: Use this skill whenever writing, generating, or reviewing tests. It prevents the agent from producing "test theater" — tests that mirror implementation instead of verifying requirements. Provides decision trees for when to mock vs use real dependencies, how to choose test granularity (unit/integration/e2e), and anti-patterns to avoid. Triggers on test writing, test generation, TDD, test review, or any task involving test code.
---

# Anti-Test-Theater

Stop writing tests that only prove your code does what it already does.

## The #1 Rule

**Never look at the implementation first, then write tests to match it.**

Instead: understand what the code is *supposed to do*, then write tests that verify *that*.

```
✗ "This function returns X, so I'll test that it returns X"
  → This is a tautology. If the function has a bug, your test has the same bug.

✓ "The spec says users with expired tokens should get 401, so I'll test that"
  → This catches bugs because the test is independent of the implementation.
```

## 7 Anti-Patterns to Never Produce

### 1. Implementation Mirroring
```typescript
// ✗ BAD — test mirrors the implementation line by line
test('calculates total', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 3 }]
  // This is literally the same logic as the implementation:
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  expect(calculateTotal(items)).toBe(expected)
})

// ✓ GOOD — test uses independently computed expected values
test('calculates total from item prices and quantities', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 3 }]
  expect(calculateTotal(items)).toBe(35) // 10*2 + 5*3 = 35, computed by hand
})
```

### 2. Over-Mocking
```typescript
// ✗ BAD — mocks the thing you're trying to test
test('user service creates user', () => {
  const mockDb = { create: vi.fn().mockResolvedValue({ id: 1, name: 'Alice' }) }
  const service = new UserService(mockDb)
  const user = await service.create({ name: 'Alice' })
  expect(mockDb.create).toHaveBeenCalledWith({ name: 'Alice' })
  // This test only proves you called the mock. It tests nothing.
})

// ✓ GOOD — use a real (in-memory) database or test container
test('user service creates user and persists it', () => {
  const db = createTestDatabase() // SQLite in-memory or testcontainers
  const service = new UserService(db)
  const user = await service.create({ name: 'Alice' })
  const found = await db.users.findById(user.id)
  expect(found.name).toBe('Alice')
})
```

### 3. Happy Path Only
```typescript
// ✗ BAD — only tests the success case
test('login succeeds', () => {
  const result = await login('user@test.com', 'correct-password')
  expect(result.token).toBeDefined()
})

// ✓ GOOD — tests the interesting failure modes
test('login with wrong password returns 401', () => { ... })
test('login with non-existent email returns 401 (same error, no info leak)', () => { ... })
test('login with empty password returns 400', () => { ... })
test('login after 5 failed attempts returns 429', () => { ... })
test('login with expired account returns 403', () => { ... })
```

### 4. Testing Framework Internals
```typescript
// ✗ BAD — tests that React renders, not that your component works
test('renders without crashing', () => {
  render(<UserProfile userId={1} />)
  // ...that's it. This tests React, not your component.
})

// ✓ GOOD — tests user-visible behavior
test('shows user name and email after loading', async () => {
  render(<UserProfile userId={1} />)
  expect(await screen.findByText('Alice')).toBeInTheDocument()
  expect(screen.getByText('alice@test.com')).toBeInTheDocument()
})

test('shows error message when user not found', async () => {
  render(<UserProfile userId={999} />)
  expect(await screen.findByText(/not found/i)).toBeInTheDocument()
})
```

### 5. Snapshot Abuse
```typescript
// ✗ BAD — snapshot of entire component output
test('renders correctly', () => {
  const { container } = render(<Dashboard data={mockData} />)
  expect(container).toMatchSnapshot()
  // Any change to the HTML breaks this test. Nobody reads the diff.
  // This test will be blindly updated with `--update-snapshot` forever.
})

// ✓ GOOD — assert specific things that matter
test('dashboard shows total revenue', () => {
  render(<Dashboard data={{ revenue: 50000 }} />)
  expect(screen.getByTestId('total-revenue')).toHaveTextContent('$50,000')
})
```

### 6. Brittle Selectors
```typescript
// ✗ BAD — coupled to DOM structure
test('clicks submit', () => {
  const btn = container.querySelector('div > form > div:nth-child(3) > button')
  fireEvent.click(btn!)
})

// ✓ GOOD — uses accessible queries
test('submits the form', () => {
  fireEvent.click(screen.getByRole('button', { name: /submit/i }))
})
```

### 7. Flaky Async Tests
```typescript
// ✗ BAD — arbitrary timeout
test('data loads', async () => {
  render(<UserList />)
  await new Promise(r => setTimeout(r, 2000)) // hope it loaded by now
  expect(screen.getByText('Alice')).toBeInTheDocument()
})

// ✓ GOOD — wait for the actual condition
test('data loads', async () => {
  render(<UserList />)
  expect(await screen.findByText('Alice')).toBeInTheDocument()
})
```

## Mock Decision Tree

```
Do I need to mock this dependency?
│
├── Is it a network call (HTTP API, database, external service)?
│   ├── Unit test → YES, mock it (fast, deterministic)
│   ├── Integration test → NO, use real dependency (test container, test DB)
│   └── E2E test → NO, use real everything
│
├── Is it a pure function with no side effects?
│   └── NO, never mock pure functions. Just call them.
│
├── Is it time/randomness/filesystem?
│   └── YES, mock it (deterministic tests)
│
├── Is it the thing I'm actually testing?
│   └── NO, never mock the subject under test.
│       If you're testing UserService, don't mock UserService.
│
└── Am I mocking to avoid slow setup?
    ├── Setup takes < 1 second → NO, use real dependency
    └── Setup takes > 5 seconds → YES, mock it, but also have
        integration tests that use the real thing
```

### What to Mock (Short List)
- External HTTP APIs (use msw or nock, not manual mocks)
- Email/SMS sending
- Payment processors (in unit tests)
- Current time (`vi.useFakeTimers()`)
- Random number generation
- File system (only if testing logic, not file operations)

### What NOT to Mock
- Your own code (if you mock everything you own, you're testing nothing)
- Database queries (use in-memory SQLite or testcontainers)
- Simple utility functions
- Data transformations
- The module you're testing

## Test Granularity Decision

```
What am I testing?
│
├── A pure function or single class method
│   → Unit test (mock external deps, fast, many of these)
│
├── Two or more components working together
│   → Integration test (real deps, fewer of these)
│
├── A user workflow from start to finish
│   → E2E test (real browser/API, very few of these)
│
└── Not sure?
    → Default to integration test.
    It's better to have fewer meaningful tests than
    many unit tests that mock everything away.
```

### The Testing Ratio

```
E2E tests:          ~5%   (critical user journeys only)
Integration tests: ~35%   (API endpoints, DB operations, component interactions)
Unit tests:        ~60%   (pure logic, calculations, transformations)
```

This is a guideline, not a law. Some projects need more integration tests (API-heavy backends). Some need more unit tests (algorithm-heavy libraries).

## Writing Tests from Requirements

When asked to write tests, follow this process:

### Step 1: Identify the requirement
Before writing any test, answer: "What is this code supposed to do?"
- Read the function signature, JSDoc, or PR description
- If there's no spec, ASK before writing tests
- Never infer requirements from the implementation

### Step 2: List the behaviors to test
For each requirement, list:
- The happy path (normal input → expected output)
- Edge cases (empty input, null, zero, max values, unicode)
- Error cases (invalid input, missing dependencies, network failure)
- Security cases (unauthorized access, injection, overflow)

### Step 3: Write test names first
```typescript
describe('TransferService.transfer', () => {
  test('transfers amount from sender to receiver')
  test('fails if sender has insufficient balance')
  test('fails if sender and receiver are the same account')
  test('fails if amount is zero or negative')
  test('fails if either account does not exist')
  test('is atomic — both accounts update or neither does')
  test('handles concurrent transfers without double-spending')
})
// Write the test bodies AFTER agreeing on the test names.
```

### Step 4: Write assertions that would catch real bugs
Ask yourself: "If the implementation had [specific bug], would this test catch it?"
- If the function silently returns null instead of throwing → would your test catch it?
- If the function doesn't validate input → would your test catch it?
- If the function has an off-by-one error → would your test catch it?

## Test Naming Convention

```
test('[unit] [action] [expected result] [condition]')

test('returns 401 when token is expired')
test('creates order with correct total when cart has multiple items')
test('throws ValidationError when email format is invalid')
test('retries 3 times before failing when API returns 503')
```

Don't:
```
test('works correctly')
test('should handle edge case')
test('test1')
test('it does the thing')
```
