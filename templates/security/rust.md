# Security Patterns — Rust

Language-specific extension of `RULES.md §5`. The universal rules apply; this file adds Rust-specific forbidden patterns, recommended idioms, memory safety, secrets handling, secure deletion, and tooling. Tier 1 — force-synced from the kit.

Rust's safety story is excellent on memory and data races. The patterns below cover the parts the borrow checker does **not** catch: panics in production, `unsafe` discipline, async pitfalls, and secrets that outlive their drop.

## 1. Forbidden patterns

| Forbidden | Why | Use instead |
|-----------|-----|-------------|
| `.unwrap()`, `.expect("…")` in non-test code | Panics on `None`/`Err` — DoS | `?` operator returning a `Result<_, _>`; `let … else { … }` for early exit |
| `panic!(...)`, `todo!()`, `unimplemented!()` in library code | Same | Return `Err`; for genuinely unreachable, use `unreachable!()` only with an invariant proof comment |
| `unsafe { … }` without a `// SAFETY:` comment proving each invariant | Reviewers can't verify | Justify every invariant the compiler can't check |
| `std::mem::transmute` outside `repr(C)` round-trips | UB landmine | Use safe casts (`as`, `From`/`Into`), or `bytemuck` for POD types |
| `MaybeUninit` read before init / `mem::uninitialized` (deprecated) | UB | `MaybeUninit::assume_init` only after every byte is written |
| `static mut` | Unsynchronized global state | `Mutex<T>` / `RwLock<T>` / `OnceCell` / `Atomic*` |
| `Rc<RefCell<…>>` crossed across threads | Compile error if you try directly; people reach for `Arc<Mutex<…>>` and over-share | Prefer message passing (channels) before reaching for shared mutability |
| `std::sync::Mutex` in async code | Blocks the runtime if held across `.await` | `tokio::sync::Mutex` (or hold the std mutex only across non-await code) |
| `.await` while holding a non-async mutex | Deadlock / starvation | Drop the guard before awaiting, or use `tokio::sync::Mutex` |
| `tokio::spawn(async move { … })` with un-cancelled tasks | Resource leak / dangling work | Track the `JoinHandle`; abort on shutdown |
| `.clone()` to silence the borrow checker without thought | Hides ownership bugs; perf cost | Refactor; clone deliberately for correctness, not for compile success |
| Hardcoded secrets in source | Same as everywhere | `std::env::var`, secret manager |
| `println!`/`dbg!` for application logging | No level, no structure | `tracing` / `log` |
| Integer overflow in release mode is **silent wrapping** | Bugs slip through tests | `checked_*` / `saturating_*` / `wrapping_*` made explicit, or `overflow-checks = true` in release |
| `Vec::set_len` after `with_capacity` without writing the bytes | Reads uninitialized memory | Push elements, or `MaybeUninit` + `assume_init` after every slot is written |

## 2. Recommended idioms

- **`#![deny(unsafe_code)]` at the crate root** when you have no `unsafe`. Re-enable per-module only where unavoidable, with a `// SAFETY:` comment.
- **`#[must_use]` on Result-returning functions** and on important newtypes. Silent error drops are real bugs.
- **Errors as types.** `thiserror` for libraries (typed `enum` of error variants), `anyhow` for applications (`anyhow::Result<_>` + `.context("...")`).
- **Newtype wrappers** to make illegal states unrepresentable: `struct UserId(u64)`, `struct ValidatedEmail(String)`.
- **Builder pattern with `#[must_use]` per setter** for non-trivial constructors.
- **`#[non_exhaustive]` on public enums/structs** so adding a variant isn't a breaking change.
- **Constant-time crypto comparison**: `subtle::ConstantTimeEq` (`a.ct_eq(&b)`), not `==`.
- **Async cancellation safety**: hold no critical state across an `.await` you didn't write yourself.

## 3. Memory safety — the `unsafe` discipline

Rust's safe subset is memory-safe. The danger is `unsafe`. When you write it:

1. **Minimize the block.** `unsafe` should wrap one or two lines, not a function body.
2. **`// SAFETY: …` comment immediately above** the block, naming every invariant the compiler can't check.
3. **Encapsulate behind a safe API.** Callers should not need to know `unsafe` is inside.
4. **Run Miri** (`cargo +nightly miri test`) — catches UB the regular sanitizer can't see (provenance, uninit reads).
5. **Run AddressSanitizer** on the FFI boundary if you link C.
6. **Don't write `unsafe` to get performance** before measuring — the safe version is usually within 1% and the compiler keeps getting better.

## 4. Secrets handling

```toml
# Cargo.toml
[dependencies]
secrecy = "0.8"
zeroize = { version = "1.7", features = ["zeroize_derive"] }
```

```rust
use secrecy::{Secret, ExposeSecret};

let api_key: Secret<String> = Secret::new(std::env::var("STRIPE_API_KEY")?);
//   ^ Debug, Display, Serialize all redact to "[REDACTED]"

// To use it (briefly):
client.bearer_auth(api_key.expose_secret());
//                          ^ explicit — auditable in code review
```

- **`secrecy::Secret<T>`** wraps a secret so `Debug`/`Display`/`Serialize` print `[REDACTED]`. The only way out is `expose_secret()`, which makes audit grep-able.
- **`zeroize::Zeroize` + `#[derive(ZeroizeOnDrop)]`** ensures the memory is wiped when the value is dropped — and the compiler **cannot** dead-store-eliminate it (the crate uses inline assembly / `volatile_write`).
- **Don't put secrets in `String` long-term.** A `String` reallocation copies bytes. Wrap secrets in `Secret<Box<[u8]>>` or a custom `Zeroizing<Vec<u8>>` to control re-allocation.
- **Don't pass secrets through process arguments** (`argv` is world-readable on Linux). Use env vars or a file descriptor.
- **Don't `.clone()` a secret without thinking.** Every clone is a new memory residence.

## 5. Secure deletion

```rust
use zeroize::Zeroize;

let mut password: Vec<u8> = read_password()?;
// … use it …
password.zeroize();   // explicit wipe — survives optimizer
drop(password);
```

Or, the type-system-enforced version:

```rust
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Zeroize, ZeroizeOnDrop)]
struct SessionKey([u8; 32]);
//                ^ wiped automatically when the value goes out of scope
```

For files: there is no portable secure-delete. Encrypt the file with a per-file key (use `chacha20poly1305` or `aes-gcm` from the `RustCrypto` org), then drop the key when the file should be gone.

## 6. Tooling — wire into `make lint` / `make review`

| Tool | What it catches |
|------|-----------------|
| `cargo clippy -- -D warnings -W clippy::pedantic -W clippy::nursery` | Lints + style + correctness |
| `cargo fmt --check` | Style consistency |
| `cargo audit` | CVE scan against `Cargo.lock` |
| `cargo deny check` | Licenses, banned crates, advisories, sources |
| `cargo +nightly miri test` | UB in `unsafe` code, uninit reads, provenance bugs |
| `cargo test --release` with `RUSTFLAGS="-Z sanitizer=address"` | Heap-related UB (nightly) |
| `RUSTFLAGS="-D warnings"` in CI | Treat any warning as error |
| `cargo geiger` | Counts `unsafe` blocks per dependency |

`make review` Step 0 (deps audit) should run `cargo audit && cargo deny check`. Step 6 should run `cargo clippy` with deny-warnings and treat any clippy hit at `correctness`/`suspicious` as blocking.
