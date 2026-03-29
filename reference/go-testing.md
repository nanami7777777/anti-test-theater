# Go Testing Patterns

## Table-driven tests — the Go way

```go
// ✓ GOOD — clear names, covers edge cases, easy to extend
func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name  string
        items []Item
        want  float64
    }{
        {"single item", []Item{{Price: 10, Qty: 2}}, 20},
        {"multiple items", []Item{{Price: 10, Qty: 2}, {Price: 5, Qty: 3}}, 35},
        {"empty cart", []Item{}, 0},
        {"zero quantity", []Item{{Price: 10, Qty: 0}}, 0},
        {"fractional price", []Item{{Price: 0.1, Qty: 1}, {Price: 0.2, Qty: 1}}, 0.3},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := CalculateTotal(tt.items)
            if math.Abs(got-tt.want) > 0.001 {
                t.Errorf("CalculateTotal(%v) = %v, want %v", tt.items, got, tt.want)
            }
        })
    }
}
```

```go
// ✗ BAD — one test, no edge cases, no subtests
func TestCalculateTotal(t *testing.T) {
    items := []Item{{Price: 10, Qty: 2}}
    result := CalculateTotal(items)
    if result != 20 {
        t.Fail()
    }
}
```

## Test error paths, not just success

```go
func TestTransfer(t *testing.T) {
    tests := []struct {
        name    string
        from    int64
        to      int64
        amount  int64
        balance int64
        wantErr string
    }{
        {"success", 1, 2, 100, 500, ""},
        {"insufficient balance", 1, 2, 1000, 500, "insufficient balance"},
        {"same account", 1, 1, 100, 500, "cannot transfer to same account"},
        {"zero amount", 1, 2, 0, 500, "amount must be positive"},
        {"negative amount", 1, 2, -50, 500, "amount must be positive"},
        {"account not found", 999, 2, 100, 0, "account not found"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            db := setupTestDB(t)
            seedAccount(t, db, tt.from, tt.balance)
            if tt.from != tt.to {
                seedAccount(t, db, tt.to, 0)
            }

            svc := NewTransferService(db)
            err := svc.Transfer(context.Background(), tt.from, tt.to, tt.amount)

            if tt.wantErr == "" {
                require.NoError(t, err)
                // Verify balances actually changed
                fromBal := getBalance(t, db, tt.from)
                toBal := getBalance(t, db, tt.to)
                assert.Equal(t, tt.balance-tt.amount, fromBal)
                assert.Equal(t, tt.amount, toBal)
            } else {
                require.ErrorContains(t, err, tt.wantErr)
            }
        })
    }
}
```

## Use real databases, not mocks

```go
// ✗ BAD — mocks the repository, tests nothing real
func TestCreateUser(t *testing.T) {
    repo := &MockUserRepo{}
    repo.On("Save", mock.Anything).Return(nil)
    svc := NewUserService(repo)

    err := svc.CreateUser(ctx, "Alice", "alice@test.com")

    assert.NoError(t, err)
    repo.AssertCalled(t, "Save", mock.Anything) // so what?
}

// ✓ GOOD — uses real database (SQLite or testcontainers)
func TestCreateUser(t *testing.T) {
    db := setupTestDB(t) // SQLite in-memory or testcontainers postgres
    svc := NewUserService(db)

    err := svc.CreateUser(ctx, "Alice", "alice@test.com")
    require.NoError(t, err)

    // Verify it was actually persisted
    var user User
    err = db.QueryRow("SELECT name, email FROM users WHERE email = $1", "alice@test.com").
        Scan(&user.Name, &user.Email)
    require.NoError(t, err)
    assert.Equal(t, "Alice", user.Name)
}

// ✓ GOOD — tests the constraint
func TestCreateUser_DuplicateEmail(t *testing.T) {
    db := setupTestDB(t)
    svc := NewUserService(db)

    err := svc.CreateUser(ctx, "Alice", "alice@test.com")
    require.NoError(t, err)

    err = svc.CreateUser(ctx, "Bob", "alice@test.com")
    assert.ErrorContains(t, err, "already exists")
}
```

## Test helpers with t.Helper()

```go
// ✓ GOOD — clean test setup with proper cleanup
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db, err := sql.Open("sqlite3", ":memory:")
    require.NoError(t, err)

    _, err = db.Exec(schema) // CREATE TABLE statements
    require.NoError(t, err)

    t.Cleanup(func() { db.Close() })
    return db
}

func seedAccount(t *testing.T, db *sql.DB, id int64, balance int64) {
    t.Helper()
    _, err := db.Exec("INSERT INTO accounts (id, balance) VALUES (?, ?)", id, balance)
    require.NoError(t, err)
}
```

## HTTP handler testing

```go
// ✓ GOOD — tests the full HTTP contract
func TestGetUsersHandler(t *testing.T) {
    db := setupTestDB(t)
    seedUsers(t, db, []User{
        {Name: "Alice", Email: "alice@test.com"},
        {Name: "Bob", Email: "bob@test.com"},
    })

    handler := NewUserHandler(db)
    srv := httptest.NewServer(handler)
    defer srv.Close()

    resp, err := http.Get(srv.URL + "/api/users?page=1&pageSize=10")
    require.NoError(t, err)
    defer resp.Body.Close()

    assert.Equal(t, http.StatusOK, resp.StatusCode)

    var body struct {
        Users []User `json:"users"`
        Total int    `json:"total"`
    }
    err = json.NewDecoder(resp.Body).Decode(&body)
    require.NoError(t, err)

    assert.Len(t, body.Users, 2)
    assert.Equal(t, 2, body.Total)
    assert.Equal(t, "Alice", body.Users[0].Name)
}

func TestGetUsersHandler_Unauthorized(t *testing.T) {
    handler := NewUserHandler(setupTestDB(t))
    srv := httptest.NewServer(handler)
    defer srv.Close()

    req, _ := http.NewRequest("GET", srv.URL+"/api/users", nil)
    // No auth header
    resp, err := http.DefaultClient.Do(req)
    require.NoError(t, err)
    defer resp.Body.Close()

    assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)
}
```

## Testing concurrent operations

```go
func TestTransfer_NoConcurrentDoubleSpend(t *testing.T) {
    db := setupTestDB(t)
    seedAccount(t, db, 1, 100) // Alice has $100
    seedAccount(t, db, 2, 0)   // Bob has $0

    svc := NewTransferService(db)

    // Run 10 concurrent transfers of $20
    var wg sync.WaitGroup
    var succeeded atomic.Int32

    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            err := svc.Transfer(ctx, 1, 2, 20)
            if err == nil {
                succeeded.Add(1)
            }
        }()
    }
    wg.Wait()

    // At most 5 should succeed ($100 / $20)
    assert.LessOrEqual(t, succeeded.Load(), int32(5))

    // Alice's balance must never go negative
    balance := getBalance(t, db, 1)
    assert.GreaterOrEqual(t, balance, int64(0))
}
```

## Mock decision for Go

| Dependency | Mock it? | How |
|-----------|---------|-----|
| External HTTP API | Yes | `httptest.NewServer` with fake handler |
| Database | No | SQLite `:memory:` or testcontainers |
| Your own interfaces | No | Use real implementation |
| Time | Yes | Inject `clock` interface |
| Random | Yes | Inject `rand` source with fixed seed |
| File system | Depends | `os.CreateTemp` for real, `afero` for mock |

## Testing with build tags

```go
//go:build integration

// Separate slow integration tests from fast unit tests
// Run with: go test -tags=integration ./...

func TestDatabaseMigration(t *testing.T) {
    // Uses real PostgreSQL via testcontainers
    container := startPostgres(t)
    defer container.Terminate(ctx)

    db := connectDB(t, container.ConnectionString())
    err := RunMigrations(db)
    require.NoError(t, err)

    // Verify schema
    tables := listTables(t, db)
    assert.Contains(t, tables, "users")
    assert.Contains(t, tables, "orders")
}
```
