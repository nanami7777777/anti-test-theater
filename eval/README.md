# Evaluation

This directory contains test cases for evaluating the skill's trigger accuracy and output quality.

## Trigger Tests (`trigger-tests.json`)

20 test queries (10 should-trigger, 10 should-not-trigger) to evaluate description accuracy.

**How to run:**
1. Send each query to your agent with the skill installed
2. Check if the skill was loaded (look for skill activation in agent logs)
3. Calculate recall (should-trigger hit rate) and precision (should-not-trigger rejection rate)

**Target:** >90% recall, >90% precision.

## Body Quality Tests

To evaluate output quality, run these tasks with and without the skill:

1. "Write tests for a function that calculates order totals with discounts"
2. "Generate a test suite for a user authentication API (login, register, password reset)"
3. "Write React component tests for a data table with sorting and pagination"

Compare the outputs on:
- Does it test failure modes, not just happy path?
- Are expected values independent of implementation?
- Is mocking appropriate (external deps only)?
- Are test names descriptive?
