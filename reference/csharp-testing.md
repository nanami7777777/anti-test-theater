# C# Testing Patterns (xUnit + NSubstitute)

## Test behavior, not implementation

```csharp
// ✗ BAD — verifies method was called
[Fact]
public async Task CreateUser_CallsRepository()
{
    var repo = Substitute.For<IUserRepository>();
    var service = new UserService(repo);
    await service.CreateUser("Alice", "alice@test.com");
    await repo.Received(1).Save(Arg.Any<User>()); // proves nothing
}

// ✓ GOOD — verifies the outcome
[Fact]
public async Task CreateUser_PersistsUser()
{
    await using var db = new TestDbContext(); // in-memory EF Core
    var service = new UserService(db);

    var user = await service.CreateUser("Alice", "alice@test.com");

    var found = await db.Users.FindAsync(user.Id);
    Assert.NotNull(found);
    Assert.Equal("Alice", found.Name);
    Assert.Equal("alice@test.com", found.Email);
}

// ✓ GOOD — tests the constraint
[Fact]
public async Task CreateUser_RejectsDuplicateEmail()
{
    await using var db = new TestDbContext();
    var service = new UserService(db);
    await service.CreateUser("Alice", "alice@test.com");

    var ex = await Assert.ThrowsAsync<DuplicateEmailException>(
        () => service.CreateUser("Bob", "alice@test.com"));
    Assert.Contains("alice@test.com", ex.Message);
}
```

## Theory tests for edge cases

```csharp
[Theory]
[InlineData("", "Name is required")]
[InlineData("ab", "Name must be at least 3 characters")]
[InlineData(null, "Name is required")]
public async Task CreateUser_ValidatesName(string? name, string expectedError)
{
    await using var db = new TestDbContext();
    var service = new UserService(db);

    var ex = await Assert.ThrowsAsync<ValidationException>(
        () => service.CreateUser(name!, "valid@test.com"));
    Assert.Contains(expectedError, ex.Message);
}

[Theory]
[InlineData("")]
[InlineData("not-an-email")]
[InlineData("@missing-local")]
[InlineData("missing-domain@")]
public async Task CreateUser_RejectsInvalidEmail(string email)
{
    await using var db = new TestDbContext();
    var service = new UserService(db);

    await Assert.ThrowsAsync<ValidationException>(
        () => service.CreateUser("Alice", email));
}
```

## ASP.NET integration tests

```csharp
public class UserEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UserEndpointTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetUsers_ReturnsPaginatedList()
    {
        var response = await _client.GetAsync("/api/users?page=1&pageSize=10");

        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<PagedResult<UserDto>>();
        Assert.NotNull(body);
        Assert.NotEmpty(body.Items);
        Assert.All(body.Items, u => Assert.Null(u.PasswordHash)); // no leak
    }

    [Fact]
    public async Task GetUsers_Returns401WithoutAuth()
    {
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.GetAsync("/api/users");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
```

## When to use NSubstitute vs real dependencies

| Dependency | Use NSubstitute | Use real |
|-----------|----------------|---------|
| External HTTP API | ✅ (+ WireMock.Net) | ❌ |
| Database (EF Core) | ❌ | ✅ (InMemory / SQLite) |
| Your own services | ❌ | ✅ |
| IDateTimeProvider | ✅ | ❌ |
| IEmailSender | ✅ | ❌ |
