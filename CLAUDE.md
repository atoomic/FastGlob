# CLAUDE.md

## What is FastGlob

A pure-Perl replacement for `CORE::glob()`. Avoids forking a shell, handles large directories
without choking, and works across UNIX, macOS, and Windows. Single module: `lib/FastGlob.pm`.

## Build & Test

```bash
perl Makefile.PL && make test
```

CI runs on Linux (Perl 5.8 through latest + devel), macOS, and Windows (Strawberry Perl).
Tests live in `t/`. The comparison test `t/glob-comparison.t` is the primary correctness
reference — it validates FastGlob output against `CORE::glob` for the same patterns.

## Perl Compatibility

**Minimum: Perl 5.008.** This is enforced by `require 5.008` and CI.

Do NOT use:
- `//=` (defined-or assignment) — requires 5.10
- `say` — requires 5.10
- `//` (defined-or) — requires 5.10
- Any syntax from 5.12+ (`package Name { }`, `...` yada-yada, etc.)

Use `defined() ? ... : ...` ternary instead of `//`.

## Distribution

Uses **Dist::Zilla** (`dist.ini`). `Makefile.PL` is auto-generated — edit `dist.ini` for
build configuration, not `Makefile.PL`. Version is managed by `[Git::NextVersion]`.

## Architecture

`FastGlob::glob()` pipeline:
1. **Brace expansion** — `{a,b,c}` patterns expanded iteratively (inside-out for nesting)
2. **Tilde expansion** — `~` and `~user` via `getpwuid`/`getpwnam`, fallback to `$HOME`/`$USERPROFILE`
3. **Literal pass-through** — patterns without wildcards returned directly
4. **Path splitting** — split by `$dirsep` before regex conversion (critical on Windows where `\` is both separator and escape)
5. **Glob-to-regex conversion** — per-component: escape regex metacharacters, convert `*`→`.*`, `?`→`.`, `[!`→`[^`
6. **Directory traversal** — `recurseglob()` walks the tree, matching each component regex against `readdir()` results

### Key design decisions
- Dotfile hiding happens at `readdir` level, not via regex mangling
- `readdir` results are matched against compiled `qr()` regexes for performance
- Path separator handling splits BEFORE regex escaping to avoid `\` ambiguity on Windows

## Platform variables

```perl
$FastGlob::dirsep        # path separator (/ or \)
$FastGlob::rootpat       # root prefix regex (e.g., [A-Za-z]: on Windows)
$FastGlob::hidedotfiles  # 1 = hide dotfiles (default), 0 = show them
```

These are auto-detected from `$^O` at load time. Tests that change them must restore originals.

## Coding Conventions

- No dependencies beyond core Perl modules (`Exporter`, `Carp`)
- `use strict; use warnings;` always
- Regex patterns: use `(?<!\\)` lookbehind for escaped-character detection, not `(^|[^\\])`
- Never use `/o` flag on regexes with interpolated variables (caches forever)
- `Carp::carp` for user-facing warnings (shows caller's line, not internals)

## Known Gotchas

- `CORE::glob` splits on spaces (treats `"foo bar"` as two patterns). FastGlob does not.
  This is intentional — FastGlob accepts patterns as list arguments instead.
- Glob and regex semantics don't map 1:1. The glob-to-regex conversion is the primary
  source of edge-case bugs. Test new patterns against `CORE::glob` in `t/glob-comparison.t`.
- `[^...]` in POSIX glob is literal `^`, not negation. Only `[!...]` is negation.
  Regex uses `[^...]` for negation. The conversion must handle this asymmetry.
