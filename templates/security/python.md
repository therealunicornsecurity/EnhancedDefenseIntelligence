# Security Patterns — Python

Language-specific extension of `RULES.md §5`. The universal rules apply; this file adds Python-specific forbidden patterns, recommended idioms, secrets handling, and tooling. Tier 1 — force-synced from the kit.

## 1. Forbidden patterns

| Forbidden | Why | Use instead |
|-----------|-----|-------------|
| `eval(x)`, `exec(x)` with any user input | Arbitrary code execution | `ast.literal_eval()` for literals, or refuse the input |
| `pickle.loads()`, `pickle.load()` on untrusted data | Arbitrary code execution on deserialize | `json`, `msgpack`, `cbor2`, or signed pickle via `hmac` |
| `yaml.load(s)` without `Loader=yaml.SafeLoader` | Same as pickle — arbitrary code | `yaml.safe_load(s)` |
| `subprocess.run(..., shell=True)` with concatenated user input | Command injection | `shell=False` + list args: `["cmd", "--flag", user_value]` |
| `os.system(s)` with any dynamic content | Command injection | `subprocess.run([...], shell=False)` |
| `xml.etree.ElementTree` on untrusted XML | XXE / billion-laughs | `defusedxml.ElementTree` |
| `random.random()`, `random.choice()` for tokens, IDs, passwords | Predictable PRNG | `secrets.token_*` |
| `hashlib.md5()`, `hashlib.sha1()` for security purposes | Broken / collision-prone | `hashlib.sha256()` or `hashlib.blake2b()`; for password hashing use `argon2-cffi` or `bcrypt` |
| `==` to compare tokens / HMACs | Timing leak | `hmac.compare_digest(a, b)` |
| f-strings or `%` formatting in SQL queries | SQL injection | Parameterized: `cursor.execute("SELECT … WHERE id = %s", (id,))` |
| `print()` for application logging | No level, no timestamps, no rotation | `logging` module, configured via `logging.config.dictConfig` |
| `assert` for security checks | `python -O` strips asserts | Raise an explicit `ValueError`/`PermissionError` |
| `tempfile.mktemp()` (deprecated) | Race condition between name and create | `tempfile.NamedTemporaryFile`, `mkstemp` |
| `os.path.join(base, user_path)` without normalization | Path traversal via `../../etc/passwd` | Resolve and check: `Path(base).resolve() in Path(base, p).resolve().parents` |
| Hardcoded secrets in source | Leaks via git history | `os.environ`, a `.env` outside the repo, secret manager |
| Unverified TLS: `verify=False` / `ssl.CERT_NONE` in production | MITM | Use real CAs; pin only when needed and document |
| `Flask(__name__)` with `DEBUG=True` in prod | Werkzeug debugger = RCE on exception | `DEBUG=False`; gate behind env var |

## 2. Recommended idioms

- **Input validation at the boundary.** Use `pydantic` v2 models or `attrs` + validators on every external input (HTTP body, CLI flags, file contents). The rest of the code can then trust the type.
- **Type hints + `mypy --strict`.** Catches a class of bugs at lint time.
- **`pathlib.Path` over string paths.** Less concatenation, fewer traversal mistakes.
- **Context managers for resources.** `with open(...)`, `with sqlite3.connect(...)`, custom `__enter__`/`__exit__` for sockets/locks.
- **Dataclasses are immutable by default with `frozen=True`** when data shouldn't change after construction.
- **Explicit exception types** in `except` blocks — never bare `except:`.
- **Constant-time crypto comparisons** with `hmac.compare_digest`.

## 3. Secrets handling

```python
# DO — load at startup, never write to disk
import os
api_key = os.environ["STRIPE_API_KEY"]   # KeyError fails loud at boot

# DO — pass by reference, not by value, into subprocesses
# (the consumer reads the file path; the secret never enters Python's memory)
subprocess.run(["./worker", "--secret-file", "/etc/myapp/secret"], shell=False)
```

- **Never print, log, or include in exception messages.** Wrap sensitive values in a class whose `__repr__`/`__str__` returns `<redacted>`. The `attrs` ecosystem has `attr.Factory` patterns; `pydantic.SecretStr` does this out of the box.
- **Don't commit `.env`.** Top-level `.gitignore` covers it; verify with `git check-ignore -v .env`.
- **Rotate at a known frequency** — secrets that live forever are a vulnerability.

## 4. Secure deletion

Python's garbage collector is **not** under your control, and `str` is immutable, so you cannot reliably wipe a Python `str` after creation. The practical guidance:

- **Minimize lifetime.** Read the secret, use it, drop the reference. Don't keep it in a long-lived structure.
- **Use `bytearray` for mutable secrets** so you can zero them: `for i in range(len(buf)): buf[i] = 0`. Note: in CPython, immutable types (`str`, `bytes`) may have copies floating in the interning table — `bytearray` is the only type you can truly overwrite.
- **For high-stakes secrets**, use `ctypes` to allocate / wipe directly, or shell out to a process that handles them and uses `explicit_bzero`. Pure-Python wipe of a `str` is not enforceable.
- **For files**, `os.remove` does not erase content from the filesystem. If you need data-at-rest erasure, encrypt the file at rest with a per-file key, then discard the key (the file becomes unrecoverable when the key is gone).

## 5. Tooling — wire these into `make lint` / `make review`

| Tool | What it catches | Suggested invocation |
|------|-----------------|----------------------|
| `ruff check --select=E,F,B,S,SIM` | Style, bugs, **bandit-equivalent security (S)**, common simplifications | `ruff check src/ tests/` |
| `mypy --strict` | Type errors | `mypy src/` |
| `bandit -r src/` | Security AST scan (overlaps with `ruff S`) | use one or the other |
| `pip-audit` | CVEs in installed packages | `pip-audit` |
| `safety check` | Alternative CVE source | optional |
| `pytest --cov=src --cov-fail-under=80` | Test coverage gate | in `make test` |

`make review` Step 6 should run `ruff check --select=S` (or `bandit`) and treat MEDIUM+ as blocking.
