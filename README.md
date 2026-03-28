# Anti-Test-Theater

[![Skills](https://img.shields.io/badge/agent--skills-compatible-blue)](https://skills.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Stop your AI agent from writing useless tests.

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

## What This Skill Does

After installing, your agent will:

1. Write tests from **requirements**, not from implementation
2. Use the **mock decision tree** — mock external services, never mock the subject under test
3. Test **failure modes** and edge cases, not just happy paths
4. Use **proper async patterns** instead of arbitrary timeouts
5. Write **descriptive test names**: `'returns 401 when token is expired'`

## Structure

```
anti-test-theater/
├── SKILL.md                          # Core rules (loaded when skill triggers)
└── reference/
    ├── frontend-testing.md           # React/Vue component testing patterns
    └── api-testing.md                # Backend API, database, concurrency patterns
```

The agent loads `SKILL.md` when you ask it to write tests. It reads the reference files only when working on frontend or backend tests specifically — keeping context usage efficient.

## Compatible With

Works with any AI agent that supports the Agent Skills standard:
Claude Code, Cursor, Kiro, OpenAI Codex, Gemini CLI, GitHub Copilot, OpenCode, Aider, and 30+ others.

Works with any test framework: Vitest, Jest, Playwright, pytest, Go testing, Mocha, etc.

## License

MIT
