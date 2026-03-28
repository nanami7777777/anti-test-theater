# Frontend Testing Patterns

## React Component Testing (Vitest + Testing Library)

### Test user behavior, not implementation details

```typescript
// ✗ BAD — tests internal state
test('sets loading to true', () => {
  const { result } = renderHook(() => useUsers())
  expect(result.current.loading).toBe(true)
})

// ✓ GOOD — tests what the user sees
test('shows loading spinner while fetching users', () => {
  render(<UserList />)
  expect(screen.getByRole('progressbar')).toBeInTheDocument()
})

test('shows user list after loading', async () => {
  render(<UserList />)
  expect(await screen.findByText('Alice')).toBeInTheDocument()
  expect(screen.queryByRole('progressbar')).not.toBeInTheDocument()
})
```

### Form testing — test the workflow, not individual fields

```typescript
// ✗ BAD — tests each field in isolation
test('name input works', () => {
  render(<SignupForm />)
  fireEvent.change(screen.getByLabelText('Name'), { target: { value: 'Alice' } })
  expect(screen.getByLabelText('Name')).toHaveValue('Alice')
  // This tests React, not your form
})

// ✓ GOOD — tests the complete submission flow
test('submits form with valid data', async () => {
  const onSubmit = vi.fn()
  render(<SignupForm onSubmit={onSubmit} />)

  await userEvent.type(screen.getByLabelText('Name'), 'Alice')
  await userEvent.type(screen.getByLabelText('Email'), 'alice@test.com')
  await userEvent.click(screen.getByRole('button', { name: /sign up/i }))

  expect(onSubmit).toHaveBeenCalledWith({
    name: 'Alice',
    email: 'alice@test.com',
  })
})

test('shows validation errors for empty required fields', async () => {
  render(<SignupForm onSubmit={vi.fn()} />)
  await userEvent.click(screen.getByRole('button', { name: /sign up/i }))

  expect(screen.getByText(/name is required/i)).toBeInTheDocument()
  expect(screen.getByText(/email is required/i)).toBeInTheDocument()
})
```

### API mocking with msw (not manual mocks)

```typescript
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/users', () =>
    HttpResponse.json([
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
    ])
  ),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

test('shows error when API fails', async () => {
  server.use(
    http.get('/api/users', () => HttpResponse.json(null, { status: 500 }))
  )

  render(<UserList />)
  expect(await screen.findByText(/failed to load/i)).toBeInTheDocument()
})
```

## Vue Component Testing (Vitest + Vue Test Utils)

```typescript
import { mount } from '@vue/test-utils'

// ✓ GOOD — tests emitted events and rendered output
test('emits update when form is submitted', async () => {
  const wrapper = mount(EditForm, { props: { user: { name: 'Alice' } } })

  await wrapper.find('input[name="name"]').setValue('Bob')
  await wrapper.find('form').trigger('submit')

  expect(wrapper.emitted('update')).toHaveLength(1)
  expect(wrapper.emitted('update')![0]).toEqual([{ name: 'Bob' }])
})
```

## E2E Testing (Playwright)

```typescript
// ✓ GOOD — tests a real user journey
test('user can sign up and see dashboard', async ({ page }) => {
  await page.goto('/signup')
  await page.getByLabel('Email').fill('test@example.com')
  await page.getByLabel('Password').fill('securepass123')
  await page.getByRole('button', { name: 'Sign Up' }).click()

  // Should redirect to dashboard
  await expect(page).toHaveURL('/dashboard')
  await expect(page.getByText('Welcome')).toBeVisible()
})
```
