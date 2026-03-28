# Anti-Test-Theater

[![Skills](https://img.shields.io/badge/agent--skills-compatible-blue)](https://skills.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-green)](https://github.com/nanami7777777/anti-test-theater/releases)

Stop your AI agent from writing useless tests.

**Works with:** Claude Code · Cursor · Kiro · OpenAI Codex · Gemini CLI · GitHub Copilot · OpenCode · Aider

## Before / After

Without this skill, your agent writes:
```typescript
// ❌ "Test theater" — mirrors implementation, catches nothing
test('calculates total', () => {
  const items = [{ price: 10, qty: 2 }]
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  expect(calculateTotal(items)).toBe(expected) // tautology
})

test('renders without crashing', () => {
  render(<UserProfile />)  // tests React, not your component
})
```

With this skill installed:
```typescript
// ✅ Tests requirements, catches real bugs
test('calculates total from item prices and quantities', () => {
  expect(calculateTotal([{ price: 10, qty: 2 }, { price: 5, qty: 3 }])).toBe(35)
})

test('returns 0 for empty cart', () => {
  expect(calculateTotal([])).toBe(0)
})

test('handles floating point precision (0.1 + 0.2)', () => {
  expect(calculateTotal([{ price: 0.1, qty: 1 }, { price: 0.2, qty: 1 }])).toBeCloseTo(0.3)
})

test('shows user name and email after loading', async () => {
  render(<UserProfile userId={1} />)
  expect(await screen.findByText('Alice')).toBeInTheDocument()
  expect(screen.getByText('alice@test.com')).toBeInTheDocument()
})

test('shows error when user not found', async () => {
  render(<UserProfile userId={999} />)
  expect(await screen.findByText(/not found/i)).toBeInTheDocument()
})
```

## Install

```bash
npx skills add nanami7777777/anti-test-theater
```

## The Problem

AI agents produce "test theater" — tests that look impressive but catch zero bugs:

| Anti-Pattern | What Happens | How Often |
|-------------|-------------|-----------|
| Implementation mirroring | Test recomputes the same logic as the code | Very common |
| Over-mocking | Mocks everything, test validates nothing | [40% of AI mocks are broken](https://markaicode.com/troubleshooting-ai-mock-objects-unit-tests/) |
| Happy path only | Skips edge cases where real bugs live | Very common |
| Snapshot abuse | `toMatchSnapshot()` on everything | Common |
| Flaky async | `setTimeout(2000)` and hoping | [30% of AI tests are flaky](https://markaicode.com/solving-ai-test-case-flakiness-developer-guide/) |

Read more: [The Rise of Test Theater](https://benhouston3d.com/blog/the-rise-of-test-theater)

## What's Inside

### Core Rules (SKILL.md — loaded automatically)
- 7 anti-patterns with bad/good code examples
- Mock decision table (when to mock vs use real deps)
- Test granularity guide (unit vs integration vs e2e)
- 4-step requirement-driven test writing process
- Test naming convention

### Reference Files (loaded on demand)
- `reference/frontend-testing.md` — React, Vue, Playwright patterns
- `reference/api-testing.md` — API endpoints, database, concurrency, Go, Python
- `reference/java-testing.md` — JUnit 5, Mockito, Spring Boot patterns
- `reference/csharp-testing.md` — xUnit, NSubstitute, ASP.NET patterns

### Scripts
- `scripts/check-test-quality.sh` — Scan your test files for anti-patterns

```bash
# Run the test quality checker
bash ~/.claude/skills/anti-test-theater/scripts/check-test-quality.sh src/
```

## Structure

```
anti-test-theater/
├── SKILL.md                          # Core rules (~200 lines)
├── reference/
│   ├── frontend-testing.md           # React/Vue/Playwright
│   ├── api-testing.md                # API/DB/concurrency/Go/Python
│   ├── java-testing.md               # JUnit 5/Mockito/Spring Boot
│   └── csharp-testing.md             # xUnit/NSubstitute/ASP.NET
├── scripts/
│   └── check-test-quality.sh         # Anti-pattern scanner
└── CHANGELOG.md
```

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT
