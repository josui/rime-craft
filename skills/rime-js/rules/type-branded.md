# type-branded

Use branded types to distinguish structurally identical but semantically different primitives.

## Why

A `userId` and a `postId` are both `string`, so TypeScript happily lets you pass one where the other is expected. This class of bug is invisible to the compiler and only surfaces when the wrong ID hits the database. Branded types add a phantom property that exists only at the type level — zero runtime cost, full compile-time safety.

## Bad

```typescript
// Any string accepted — wrong ID type compiles fine
function getUser(id: string): Promise<User> { /* ... */ }
function getPost(id: string): Promise<Post> { /* ... */ }

const oderId = "order_abc123"
getUser(oderId) // no error — silent bug
```

## Good

```typescript
// Branded types prevent cross-contamination at compile time
type UserId = string & { readonly __brand: unique symbol }
type PostId = string & { readonly __brand: unique symbol }

function userId(raw: string): UserId { return raw as UserId }
function postId(raw: string): PostId { return raw as PostId }

function getUser(id: UserId): Promise<User> { /* ... */ }
function getPost(id: PostId): Promise<Post> { /* ... */ }

const uid = userId("user_abc123")
const pid = postId("post_xyz789")

getUser(pid) // Compile error — PostId is not assignable to UserId
```

## Notes

Zero runtime overhead — the brand exists only in the type system. Useful for IDs, auth tokens, currency amounts, ISO date strings, and any domain primitive that should not be interchangeable. Factory functions (`userId()`, `postId()`) serve as the single validated entry point. For richer validation, combine the factory with runtime checks (e.g., regex or Zod parsing).
