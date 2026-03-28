# API & Backend Testing Patterns

## API Endpoint Testing (Supertest / Vitest)

### Test the HTTP contract, not internal implementation

```typescript
import request from 'supertest'
import { app } from '../app'
import { createTestDatabase, seedUsers } from '../test-utils'

let db: TestDatabase

beforeEach(async () => {
  db = await createTestDatabase()
  await seedUsers(db, [
    { name: 'Alice', email: 'alice@test.com', role: 'admin' },
    { name: 'Bob', email: 'bob@test.com', role: 'viewer' },
  ])
})

afterEach(async () => {
  await db.cleanup()
})

// ✓ GOOD — tests the full request/response cycle
test('GET /api/users returns paginated user list', async () => {
  const res = await request(app)
    .get('/api/users?page=1&pageSize=10')
    .set('Authorization', `Bearer ${adminToken}`)
    .expect(200)

  expect(res.body.data.list).toHaveLength(2)
  expect(res.body.data.total).toBe(2)
  expect(res.body.data.list[0]).toMatchObject({
    name: 'Alice',
    email: 'alice@test.com',
  })
  // Should NOT expose password hash
  expect(res.body.data.list[0]).not.toHaveProperty('passwordHash')
})

test('GET /api/users returns 401 without auth token', async () => {
  await request(app)
    .get('/api/users')
    .expect(401)
})

test('GET /api/users returns 403 for non-admin users', async () => {
  await request(app)
    .get('/api/users')
    .set('Authorization', `Bearer ${viewerToken}`)
    .expect(403)
})
```

## Database Testing

### Use real databases, not mocks

```typescript
// ✗ BAD — mocks the database, tests nothing
test('creates user', async () => {
  const mockPrisma = { user: { create: vi.fn().mockResolvedValue({ id: 1 }) } }
  const service = new UserService(mockPrisma as any)
  await service.create({ name: 'Alice' })
  expect(mockPrisma.user.create).toHaveBeenCalled() // so what?
})

// ✓ GOOD — uses real database (in-memory SQLite or testcontainers)
test('creates user and enforces unique email', async () => {
  const db = await createTestDatabase()
  const service = new UserService(db)

  await service.create({ name: 'Alice', email: 'alice@test.com' })

  // Verify it was actually persisted
  const found = await db.user.findUnique({ where: { email: 'alice@test.com' } })
  expect(found?.name).toBe('Alice')

  // Verify unique constraint
  await expect(
    service.create({ name: 'Alice2', email: 'alice@test.com' })
  ).rejects.toThrow(/already exists/)
})
```

### Test database constraints, not just application logic

```typescript
test('order total cannot be negative (DB constraint)', async () => {
  await expect(
    db.order.create({ data: { total: -100, userId: user.id } })
  ).rejects.toThrow() // DB CHECK constraint catches this
})

test('deleting user cascades to their orders', async () => {
  await db.user.delete({ where: { id: user.id } })
  const orders = await db.order.findMany({ where: { userId: user.id } })
  expect(orders).toHaveLength(0)
})
```

## Testing Concurrent Operations

```typescript
test('concurrent transfers do not double-spend', async () => {
  // Setup: Alice has $100
  await db.account.update({
    where: { id: aliceId },
    data: { balance: 100 },
  })

  // Run 10 concurrent transfers of $20 each
  const transfers = Array.from({ length: 10 }, () =>
    transferService.transfer(aliceId, bobId, 20)
  )

  const results = await Promise.allSettled(transfers)
  const succeeded = results.filter(r => r.status === 'fulfilled').length

  // At most 5 should succeed ($100 / $20 = 5)
  expect(succeeded).toBeLessThanOrEqual(5)

  // Alice's balance should never go negative
  const alice = await db.account.findUnique({ where: { id: aliceId } })
  expect(alice!.balance).toBeGreaterThanOrEqual(0)
})
```

## Testing Error Responses

```typescript
// Test that errors don't leak internal details
test('database error returns 500 without stack trace', async () => {
  // Force a DB error
  await db.$disconnect()

  const res = await request(app)
    .get('/api/users')
    .set('Authorization', `Bearer ${adminToken}`)
    .expect(500)

  expect(res.body.message).toBe('Internal server error')
  expect(res.body).not.toHaveProperty('stack')
  expect(res.body).not.toHaveProperty('sql')
  expect(JSON.stringify(res.body)).not.toContain('prisma')
})
```

## Go Testing Patterns

```go
// ✓ GOOD — table-driven tests with clear names
func TestTransfer(t *testing.T) {
    tests := []struct {
        name      string
        from      int64
        to        int64
        amount    int64
        wantErr   string
    }{
        {"success", 1, 2, 100, ""},
        {"insufficient balance", 1, 2, 99999, "insufficient balance"},
        {"same account", 1, 1, 100, "cannot transfer to same account"},
        {"zero amount", 1, 2, 0, "amount must be positive"},
        {"negative amount", 1, 2, -50, "amount must be positive"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := svc.Transfer(ctx, tt.from, tt.to, tt.amount)
            if tt.wantErr == "" {
                require.NoError(t, err)
            } else {
                require.ErrorContains(t, err, tt.wantErr)
            }
        })
    }
}
```

## Python Testing Patterns (pytest)

```python
# ✓ GOOD — parametrized tests for edge cases
@pytest.mark.parametrize("email,expected_error", [
    ("", "Email is required"),
    ("not-an-email", "Invalid email format"),
    ("a" * 255 + "@test.com", "Email too long"),
    ("alice@test.com", None),  # valid
])
def test_validate_email(email, expected_error):
    if expected_error:
        with pytest.raises(ValidationError, match=expected_error):
            validate_email(email)
    else:
        assert validate_email(email) is True
```
