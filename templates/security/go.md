# Security Patterns — Go

Language-specific extension of `RULES.md §5`. The universal rules apply; this file adds Go-specific forbidden patterns, recommended idioms, concurrency safety, secrets handling, secure deletion, and tooling. Tier 1 — force-synced from the kit.

## 1. Forbidden patterns

| Forbidden | Why | Use instead |
|-----------|-----|-------------|
| Ignoring an error: `_ = doThing()` or no assignment at all | Silent failure mode | Always check and handle: `if err != nil { return fmt.Errorf("doThing: %w", err) }` |
| `panic(...)` in library code | DoS on a path the caller can't recover | Return `error`; reserve `panic` for truly unreachable invariants |
| `init()` doing I/O, network, or non-trivial work | Hidden startup cost; hard to test; order-dependent | Explicit `func New() (*X, error)` |
| Goroutine leaks (spawning without a `context.Context` or done channel) | OOM / dangling work | Pass `ctx`; check `<-ctx.Done()` in long-running loops |
| Goroutine-mutated state without `sync.Mutex` / channel | Data race | One owner; channels for handoff; `sync.RWMutex` for read-heavy maps |
| `fmt.Sprintf("%s", x)` in SQL queries | SQL injection | `db.QueryContext(ctx, "SELECT … WHERE id = ?", id)` |
| `exec.Command("sh", "-c", userInput)` | Command injection | `exec.Command("prog", "--flag", userValue)` — no shell |
| `math/rand` for tokens, IDs, passwords, nonces | Deterministic given the seed | `crypto/rand` |
| `crypto/md5`, `crypto/sha1` for security purposes | Broken | `crypto/sha256`, `crypto/sha512`, or `golang.org/x/crypto/blake2b` |
| `==` to compare HMACs / tokens | Timing leak | `subtle.ConstantTimeCompare(a, b)` |
| `time.Sleep` for retry/backoff | Blocks goroutine; can't cancel | `time.After` selected with `ctx.Done()`; or `time.NewTimer` |
| Reading a whole file into memory unconditionally (`os.ReadFile`) for large inputs | DoS on attacker-controlled size | Stream with `bufio.Scanner` / `io.LimitReader` |
| `http.ListenAndServe(":port", nil)` with default `ServeMux` | Implicit global state; pprof leak if `net/http/pprof` imported anywhere | Build an explicit `*http.ServeMux`, pass it in |
| `net/http` server without explicit timeouts | Slowloris-class DoS | Set `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout` |
| `tls.Config{InsecureSkipVerify: true}` in production | MITM | Real CA verification; pin only when needed |
| `context.Background()` deep inside library code | No cancellation, no deadline | Accept `ctx context.Context` as the first parameter |
| `os.Setenv` at runtime | Race with other goroutines reading env | Configure at startup before goroutines fan out |
| Hardcoded secrets in `.go` source | Leaks in binary + git history | `os.Getenv`, file path, secret manager |

## 2. Recommended idioms

- **`context.Context` as the first parameter** of any function that may block, do I/O, or fan out goroutines. Propagate it; never construct a fresh `Background()` mid-call.
- **Errors wrap with `%w`** so callers can `errors.Is`/`errors.As`. Each layer adds context.
- **Define error sentinels** (`var ErrNotFound = errors.New("not found")`) for `errors.Is`. Don't `==` on error strings.
- **Small interfaces at the consumer**, big concrete types at the producer. (Discover the interface from usage, don't pre-design it.)
- **`defer` for cleanup** at the top of the function, right after acquiring the resource. Reading the function top-to-bottom you see what gets released.
- **Struct field tags on input types**: `validate:"required,max=64"` (with `go-playground/validator` or similar) at the request boundary.
- **`sync.Once` for one-shot initialization**; `sync.Pool` for hot-path allocations under pressure (measure first).
- **`testing.T.Cleanup()`** over `defer` in tests — runs after subtests, can be re-ordered.

## 3. Concurrency safety

- **Run `go test -race ./...` in CI.** The race detector is cheap and finds real bugs.
- **One goroutine owns a value** at a time. Hand ownership through a channel, or wrap with a mutex held briefly.
- **Channel direction in signatures**: `chan<- T` (send-only), `<-chan T` (receive-only). Documents intent and is checked.
- **`select` with `<-ctx.Done()`** in any receive loop, so cancellation propagates.
- **`errgroup.Group`** (from `golang.org/x/sync/errgroup`) for fan-out with first-error cancel — cleaner than ad-hoc waitgroups.

## 4. Secrets handling

```go
// DO — read at startup, fail loud, keep them in []byte you control
apiKey, ok := os.LookupEnv("STRIPE_API_KEY")
if !ok { log.Fatal("missing STRIPE_API_KEY") }
```

- **Don't put a secret in a `string`.** Strings are immutable and can be interned/reallocated — you can't reliably wipe them. Use `[]byte` for anything you intend to zero.
- **Wrap secrets in a type with a redacting `String()` / `MarshalJSON`** so they don't leak through structured logs:

```go
type Secret []byte
func (s Secret) String() string             { return "[REDACTED]" }
func (s Secret) MarshalJSON() ([]byte, error) { return []byte(`"[REDACTED]"`), nil }
```

- **Don't pass secrets through process arguments** (visible in `/proc/PID/cmdline`). Use env vars or a file descriptor.
- **Pin secret-bearing pages out of swap** with `syscall.Mlock` if the OS supports it (Linux). Be aware of the rlimit (`RLIMIT_MEMLOCK`).
- **Constant-time comparison**: `subtle.ConstantTimeCompare(received, expected) == 1`.

## 5. Secure deletion

```go
import "crypto/subtle"

secret := readSecret()
// … use it …
for i := range secret { secret[i] = 0 }
secret = nil   // remove the reference
```

- **`for i := range b { b[i] = 0 }`** is the standard wipe. The Go compiler currently does **not** dead-store-eliminate stores through a slice header, but rely on the byte-zero plus `runtime.KeepAlive` if you want to be defensive:

```go
for i := range secret { secret[i] = 0 }
runtime.KeepAlive(secret)
```

- **For high-stakes secrets**, consider `github.com/awnumar/memguard` — locks pages, prevents core dumps, provides `LockedBuffer` with explicit destroy.
- **For files**, there is no portable secure-delete on modern filesystems. Encrypt the file with a per-file key (`crypto/aes` + GCM, or `golang.org/x/crypto/chacha20poly1305`), then discard the key.

## 6. Tooling — wire into `make lint` / `make review`

| Tool | What it catches |
|------|-----------------|
| `go vet ./...` | Built-in correctness checks |
| `staticcheck ./...` | Deeper static analysis (`SA*`, `ST*`, `S*` checks) |
| `golangci-lint run` | Aggregator: govet, staticcheck, errcheck, ineffassign, gosec, revive, etc. |
| `gosec ./...` | Security AST scan (G104 errcheck, G201 SQL, G401 weak crypto, …) |
| `govulncheck ./...` | Go-specific CVE scan (uses pkg.go.dev/vuln/db) |
| `go test -race -count=1 ./...` | Race detector |
| `go test -cpu=1,2,4 ./...` | Reveal scheduler-dependent races |
| `go test -fuzz=. -fuzztime=30s ./...` | Built-in fuzzing for parsers / decoders |

`make review` Step 0 (deps audit) should run `govulncheck`. Step 6 should run `golangci-lint` + `gosec` and treat HIGH severity as blocking.
