---
name: perf_benchmark
description: Profile and benchmark before/after for Procedure B Step 8 (OPTIMIZE)
version: 1.0.0
tags: [performance, benchmark, profiling, optimize]
---

# /perf_benchmark

Capture a performance baseline before optimization and verify improvement after.
Required at Procedure B Step 8 (OPTIMIZE). Never skip.

## Usage

Run before any optimization change:
```
/perf_benchmark before
```

Run after optimization change:
```
/perf_benchmark after
```

## What to Measure

### Execution Time
- Wall-clock time for the critical path (main function, hot loop, or endpoint)
- Use language-native benchmarks: `pytest-benchmark`, `go test -bench`, `cargo bench`, `hyperfine`

### Memory
- Peak RSS or heap allocation during benchmark run
- Flag allocations inside hot loops

### I/O
- File reads/writes count and bytes during benchmark
- DB query count (N+1 detection)

### Concurrency
- Identify sync operations that block (disk I/O, network) in a single-threaded path

## Output Format

```
## Benchmark: <target> — <before|after>
### Timing
- <function/path>: <Xms> median, <Xms> p99
### Memory
- Peak RSS: <X MB>
- Notable allocations: list
### I/O
- File ops: <N reads, N writes>
- DB queries: <N>
### Delta (after only)
- Time: <+X%/-X%> vs baseline
- Memory: <+X%/-X%> vs baseline
```

## Rules
- A regression (after > before by >5%) blocks the optimization step
- Benchmark must use the same dataset/input as the baseline
- Results are saved to `tests/data/bench_<target>_<before|after>.txt`
