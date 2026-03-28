# Java Testing Patterns (JUnit 5 + Mockito)

## Test behavior, not implementation

```java
// ✗ BAD — verifies internal method calls
@Test
void createUser() {
    when(repo.save(any())).thenReturn(new User(1L, "Alice"));
    service.createUser("Alice", "alice@test.com");
    verify(repo).save(any()); // proves nothing
}

// ✓ GOOD — verifies observable outcome
@Test
void createUser_persistsAndReturnsUser() {
    // Using real in-memory H2 database
    User user = service.createUser("Alice", "alice@test.com");

    assertThat(user.getId()).isNotNull();
    assertThat(userRepository.findById(user.getId()))
        .isPresent()
        .hasValueSatisfying(u -> {
            assertThat(u.getName()).isEqualTo("Alice");
            assertThat(u.getEmail()).isEqualTo("alice@test.com");
        });
}

// ✓ GOOD — tests the constraint, not just the happy path
@Test
void createUser_rejectsDuplicateEmail() {
    service.createUser("Alice", "alice@test.com");

    assertThatThrownBy(() -> service.createUser("Bob", "alice@test.com"))
        .isInstanceOf(DuplicateEmailException.class)
        .hasMessageContaining("alice@test.com");
}
```

## Parameterized tests for edge cases

```java
@ParameterizedTest
@CsvSource({
    "'',           'Name is required'",
    "'ab',         'Name must be at least 3 characters'",
    "'a]b@c',      'Name contains invalid characters'",
})
void createUser_validatesName(String name, String expectedError) {
    assertThatThrownBy(() -> service.createUser(name, "valid@test.com"))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining(expectedError);
}

@ParameterizedTest
@NullAndEmptySource
@ValueSource(strings = {"not-an-email", "@missing-local", "missing-domain@"})
void createUser_rejectsInvalidEmail(String email) {
    assertThatThrownBy(() -> service.createUser("Alice", email))
        .isInstanceOf(ValidationException.class);
}
```

## Spring Boot integration tests

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class UserControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void getUsers_returnsPaginatedList() throws Exception {
        userRepository.saveAll(List.of(
            new User("Alice", "alice@test.com"),
            new User("Bob", "bob@test.com")
        ));

        mockMvc.perform(get("/api/users").param("page", "0").param("size", "10"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray())
            .andExpect(jsonPath("$.content.length()").value(2))
            .andExpect(jsonPath("$.content[0].name").value("Alice"))
            .andExpect(jsonPath("$.content[0].passwordHash").doesNotExist());
    }

    @Test
    void getUsers_returns401WithoutAuth() throws Exception {
        mockMvc.perform(get("/api/users"))
            .andExpect(status().isUnauthorized());
    }
}
```

## When to use Mockito vs real dependencies

| Dependency | Use Mockito | Use real |
|-----------|------------|---------|
| External HTTP API | ✅ (WireMock) | ❌ |
| Database | ❌ | ✅ (H2 / Testcontainers) |
| Your own service classes | ❌ | ✅ |
| Clock/time | ✅ (`Clock.fixed()`) | ❌ |
| Email sender | ✅ | ❌ |
