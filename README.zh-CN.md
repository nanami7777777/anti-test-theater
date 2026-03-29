# Anti-Test-Theater

[![Skills](https://img.shields.io/badge/agent--skills-compatible-blue)](https://skills.sh)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-green)](https://github.com/nanami7777777/anti-test-theater/releases)

让你的 AI agent 不再写废测试。

[English](./README.md) | [中文](./README.zh-CN.md)

**兼容：** Claude Code · Cursor · Kiro · OpenAI Codex · Gemini CLI · GitHub Copilot · OpenCode · Aider

## 装了前 vs 装了后

没装这个 skill 时，agent 写出来的测试：
```typescript
// ❌ "测试剧场" — 照抄实现逻辑，什么 bug 都抓不到
test('calculates total', () => {
  const items = [{ price: 10, qty: 2 }]
  const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0)
  expect(calculateTotal(items)).toBe(expected) // 同义反复
})

test('renders without crashing', () => {
  render(<UserProfile />)  // 测的是 React 能不能跑，不是你的组件对不对
})
```

装了之后：
```typescript
// ✅ 从需求出发，能抓到真 bug
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

## 安装

```bash
npx skills add nanami7777777/anti-test-theater
```

## 问题是什么

AI agent 写的测试看着很专业，但实际上什么 bug 都抓不到：

| 反模式 | 表现 | 有多常见 |
|--------|------|---------|
| 照抄实现 | 测试里重新算一遍和代码一样的逻辑 | 非常常见 |
| 过度 mock | mock 了所有东西，测试只证明你调用了 mock | [40% 的 AI mock 有问题](https://markaicode.com/troubleshooting-ai-mock-objects-unit-tests/) |
| 只测正常路径 | 跳过边界情况，而真正的 bug 就藏在那里 | 非常常见 |
| 滥用快照 | 对所有东西 `toMatchSnapshot()`，改了就盲目更新 | 常见 |
| 异步靠等 | `setTimeout(2000)` 然后祈祷 | [30% 的 AI 测试是 flaky 的](https://markaicode.com/solving-ai-test-case-flakiness-developer-guide/) |

延伸阅读：[The Rise of Test Theater](https://benhouston3d.com/blog/the-rise-of-test-theater)

## 包含什么

### 核心规则（SKILL.md — 自动加载）
- 7 种反模式 + 正反代码对比
- Mock 决策表（什么时候该 mock、什么时候用真实依赖）
- 测试粒度指南（单元 / 集成 / E2E 怎么选）
- 4 步需求驱动测试编写流程
- 测试命名规范

### 参考文件（按需加载）
- `reference/frontend-testing.md` — React、Vue、Playwright 模式
- `reference/api-testing.md` — API 接口、数据库、并发、Go、Python
- `reference/go-testing.md` — 表驱动测试、httptest、并发测试、testcontainers
- `reference/java-testing.md` — JUnit 5、Mockito、Spring Boot
- `reference/csharp-testing.md` — xUnit、NSubstitute、ASP.NET

### 脚本
- `scripts/check-test-quality.sh` — 扫描测试文件，找出反模式

```bash
bash scripts/check-test-quality.sh src/
```

输出示例：
```
  Anti-Test-Theater Quality Check
  ================================

  Scanning 27 test files...

  ⚠ Snapshot usage: 3 files use toMatchSnapshot
  ✗ Flaky async: 2 lines use setTimeout in tests
  ⚠ Debug logs: 1 lines have console.log in test files

  2 issues, 4 warnings found.
```

## 目录结构

```
anti-test-theater/
├── SKILL.md                          # 核心规则（~200 行）
├── reference/
│   ├── frontend-testing.md           # React/Vue/Playwright
│   ├── api-testing.md                # API/数据库/并发/Python
│   ├── go-testing.md                 # 表驱动测试/httptest/并发
│   ├── java-testing.md               # JUnit 5/Mockito/Spring Boot
│   └── csharp-testing.md             # xUnit/NSubstitute/ASP.NET
├── scripts/
│   └── check-test-quality.sh         # 反模式扫描器
└── CHANGELOG.md
```

## 更新日志

见 [CHANGELOG.md](./CHANGELOG.md)。

## License

MIT
