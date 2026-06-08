# Security Patterns — C

Language-specific extension of `RULES.md §5`. The universal rules apply; this file adds C-specific forbidden patterns, recommended idioms, memory safety, secrets handling, secure deletion, and tooling. Tier 1 — force-synced from the kit.

C has the largest gap between "compiles" and "safe" of any language in common use. Treat every rule below as load-bearing.

## 1. Forbidden patterns

| Forbidden | Why | Use instead |
|-----------|-----|-------------|
| `strcpy`, `strcat`, `sprintf`, `gets` | No bounds check — classic overflow | `strncpy_s`/`strncat_s`/`snprintf` (or C11 Annex K), check return value |
| `scanf("%s", buf)` without width | Unbounded write | `scanf("%63s", buf)` with `sizeof buf - 1` |
| Format-string with user input: `printf(user_str)` | Format-string vuln (`%n` writes memory) | `printf("%s", user_str)` |
| `system(cmd)` with concatenated input | Shell injection | `fork`+`execve` with argv; never pass through `/bin/sh` |
| `memcpy(dst, src, n)` where `dst`/`src` overlap | UB | `memmove` |
| `malloc(n)` without checking return for `NULL` | NULL deref on OOM | Always check; fail loud |
| `malloc(a * b)` where `a*b` may overflow `size_t` | Heap overflow setup | `calloc(a, b)` (overflow-checked) or check before multiplying |
| Signed-integer arithmetic on attacker-controlled values without overflow check | UB | Use `__builtin_add_overflow`, or operate on `unsigned` |
| Mixing signed/unsigned in comparisons | Surprise wraparound | Explicit casts after bounds checks |
| Reading uninitialized stack/heap memory | Info disclosure (Heartbleed-class) | Zero-initialize: `T x = {0};`, `calloc`, or memset before use |
| `free(p)` without `p = NULL;` after | Double-free if reused | Define `#define FREE(p) do { free(p); (p) = NULL; } while(0)` |
| Casting away `const` | Defeats the type system | Refactor; if truly unavoidable, isolate and document |
| `volatile` for thread synchronization | Wrong tool — does not give acquire/release | `<stdatomic.h>` (C11) or pthread mutexes |
| `goto` for non-cleanup flow | Tangled control flow | Restrict `goto` to forward-jump cleanup pattern |
| Hardcoded secrets / keys in `.c` source | Binary disclosure leaks them | Read from file/env at runtime |
| `setuid(0)` without dropping immediately | Privilege escalation if exploit | Drop ASAP; do the privileged work in a forked helper |

## 2. Recommended idioms

- **Bounds checking on every buffer write.** `snprintf` returns chars-that-would-have-been-written — check it.
- **One allocation, one owner, one free.** Document ownership in the header; consider a `cleanup` attribute (`__attribute__((cleanup))`, GCC/Clang) for RAII-style auto-free.
- **`size_t` for sizes**, `ssize_t` for read/write returns, `int` for small counters only.
- **`static` everything that doesn't need external linkage** — shrinks the attack surface and helps the linker.
- **Use `assert` for invariants** (off in `NDEBUG` release builds — those are dev-time checks, not security gates).
- **Define a thin error type** (an `enum`) and pass it via out-param; never silently swallow errors.
- **Prefer `restrict` on pointer parameters** where aliasing is impossible — lets the compiler optimize and lets reviewers spot mistakes.

## 3. Memory safety — compiler / linker flags

Make the toolchain do half the work. In `CFLAGS`:

```make
CFLAGS += -std=c11 -Wall -Wextra -Wpedantic -Werror
CFLAGS += -Wformat=2 -Wformat-security -Wnull-dereference -Wshadow
CFLAGS += -Wcast-qual -Wcast-align -Wconversion -Wsign-conversion
CFLAGS += -D_FORTIFY_SOURCE=2 -fstack-protector-strong
CFLAGS += -fPIE -fstack-clash-protection
LDFLAGS += -pie -Wl,-z,relro,-z,now,-z,noexecstack
```

In debug/CI builds, **add the sanitizers**:

```make
SAN_FLAGS = -fsanitize=address,undefined -fno-omit-frame-pointer -g
# (use ThreadSanitizer separately for concurrency tests)
```

Run the full nonreg suite under ASan + UBSan in CI. Every sanitizer report is a bug.

## 4. Secrets handling

- **Don't `strcpy` a secret into a static buffer.** Pass a pointer + length; consume it; wipe it.
- **Don't pass secrets through `argv`** — it's visible in `/proc/PID/cmdline` to other users on Linux. Use environment variable, file descriptor inherited from parent, or `read(0, ...)` from stdin.
- **Don't log a secret.** If a debug build prints structs, mark sensitive fields and have your formatter substitute `<redacted>`.
- **`mlock(addr, len)`** to prevent the page from swapping to disk while a secret is resident.
- **`madvise(addr, len, MADV_DONTDUMP)`** to keep the page out of core dumps.
- **Drop privileges** between handling the secret and the rest of the program.

## 5. Secure deletion — wipe before free

`memset(buf, 0, n)` is **NOT safe** — the compiler will dead-store-eliminate it if it can prove `buf` is unused after. Use one of:

```c
// C11 Annex K — only some libcs
memset_s(buf, n, 0, n);

// BSD/glibc/libbsd — preferred when available
explicit_bzero(buf, n);

// Portable fallback — volatile pointer prevents the optimizer from dropping the write
static void *(*const volatile zero_memory)(void *, int, size_t) = memset;
zero_memory(buf, 0, n);
```

Wipe **before** `free()`. After `free`, the pointer should be zeroed too (`p = NULL`).

For sensitive data on disk: there is no portable "secure delete" on modern filesystems (CoW, SSD wear leveling). Encrypt the file at write time, discard the key when you want it gone.

## 6. Tooling — wire into `make lint` / `make review`

| Tool | What it catches |
|------|-----------------|
| `clang-tidy` with `bugprone-*`, `cert-*`, `clang-analyzer-security.*` | Static security checks |
| `scan-build` (Clang static analyzer) | Path-sensitive bug finding |
| `cppcheck --enable=all --inconclusive` | Complementary static analysis |
| `valgrind --error-exitcode=1` | Leaks, use-after-free, uninit reads (slow — for nonreg) |
| AddressSanitizer / UBSan / TSan | Same class, much faster (every test run) |
| `infer` (Facebook) | Inter-procedural analysis (deeper, slower) |
| Compiler `-Wall -Wextra -Werror` | The cheapest check there is |

`make review` Step 6 should run **clang-tidy** with security checks and treat any HIGH as blocking.
