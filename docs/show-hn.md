# Show HN: Anti-Test-Theater – Stop AI agents from writing useless tests

AI coding agents write tests that look great but catch zero bugs. They look at your implementation and write tests that confirm your code does what it already does. This is "Test Theater" (term from https://benhouston3d.com/blog/the-rise-of-test-theater).

I built an Agent Skill that fixes this. It teaches your AI agent to:

- Write tests from requirements, not from implementation
- Use a mock decision tree (mock external services, never mock the thing you're testing)
- Test failure modes, not just happy paths
- Avoid snapshot abuse, flaky async, and brittle selectors

It works with Claude Code, Cursor, Kiro, Codex, and any tool that supports the Agent Skills standard.

Install: `npx skills add nanami7777777/anti-test-theater`

GitHub: https://github.com/nanami7777777/anti-test-theater

The skill includes:
- 7 anti-patterns with bad/good code examples
- Mock decision table
- Reference files for React, Vue, API, Go, Python, Java, C#
- A bash script that scans your test files for anti-patterns

The key insight: the problem isn't that AI can't write tests. It's that AI defaults to writing tests from implementation (because it sees the code). This skill forces it to think from requirements first.
