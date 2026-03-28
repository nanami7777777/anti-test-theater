# Anti-Test-Theater

[![Skills](https://img.shields.io/badge/agent--skills-compatible-blue)](https://skills.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Stop your AI agent from writing useless tests.

## The Problem

AI agents write tests that look impressive but catch zero bugs:
- **Test Theater**: tests that mirror implementation instead of verifying requirements ([read more](https://benhouston3d.com/blog/the-rise-of-test-theater))
- **Over-mocking**: mocking everything until the test validates nothing
- **Happy path only**: skipping the edge cases where real bugs live
- **Snapshot abuse**: `toMatchSnapshot()` on everything, updated blindly forever
- **Flaky async**: `setTimeout(2000)` and hoping for the best

## The Fix

```bash
npx skills add nanami7777777/anti-test-theater
```

After installing, your agent will:
- Write tests from requirements, not from implementation
- Use the mock decision tree (mock external services, never mock the thing you're testing)
- Test failure modes, not just happy paths
- Use proper async patterns instead of arbitrary timeouts
- Name tests descriptively: `'returns 401 when token is expired'`

## What's Inside

- **7 anti-patterns** with bad/good code examples the agent learns to avoid
- **Mock decision tree** — when to mock, when to use real dependencies
- **Test granularity decision** — unit vs integration vs e2e for each scenario
- **Requirement-driven test writing process** — 4-step workflow
- **Test naming convention** — descriptive names that document behavior

## Who This Is For

Any developer using AI agents (Claude Code, Cursor, Kiro, Codex, OpenCode) to write tests. Works with any test framework (Vitest, Jest, Playwright, pytest, Go testing).

## License

MIT
