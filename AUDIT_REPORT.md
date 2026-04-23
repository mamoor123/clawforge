# ClawForge Shell Script Audit Report

**Date:** 2026-04-23  
**Audited files:** `clawforge.sh`, `skills/clawforge/scripts/plan.sh`  
**Methods:** Manual review, ShellCheck v0.10.0, bash -x xtrace, fuzz testing (13 payloads), taint analysis, control flow audit, TOCTOU analysis, dependency analysis, jq logic testing, schema consistency audit, set -u/set -e interaction analysis

---

## Already Fixed (commit ef32fa3)

The following bugs were found and have been resolved:

- ✅ JSON injection in `init` heredoc — now uses sed escaping
- ✅ jq availability — `require_jq()` function added to all commands
- ✅ Temp file leak — `cleanup()` trap added
- ✅ Directory validation — `mkdir -p` for state file directory
- ✅ `build.sh` reference removed — now points to `clawforge.sh stage`
- ✅ `plan.sh` atomic write — uses temp+mv pattern
- ✅ Dead `ARCHITECT_IDENTITY` variable removed
- ✅ Help text indentation fixed

---

## Remaining Bugs

### 🔴 HIGH — `plan.sh:22` — Trailing newline in every task value

**Code:**
```bash
TASK_JSON=$(echo "$REQUEST" | jq -Rs .)
```

`echo` appends `\n`. `jq -Rs` preserves it. Every task stored in state ends with `\n`.

**Proof:** `echo "Build API" | jq -Rs .` → `"Build API\n"`

**Impact:** Breaks any downstream string comparison. Task display shows trailing blank line.

**Fix:**
```bash
TASK_JSON=$(printf '%s' "$REQUEST" | jq -Rs .)
```

---

### 🔴 HIGH — `clawforge.sh:73-78` — Empty FIELD in `update` destroys entire state file

**Code:**
```bash
FIELD="${2:-}"
VALUE="${3:-}"
jq --arg field "$FIELD" --arg value "$VALUE" \
  'setpath($field | split(".") | map(select(. != "")); $value)' "$STATE_FILE"
```

When `$FIELD` is empty: `split(".")` → `[""]` → `map(select(. != ""))` → `[]` → `setpath([]; "test")` → **replaces entire JSON with the string value**.

**Proof:** `clawforge.sh update '' 'boom'` → state file becomes just `"boom"`.

**Fix:**
```bash
if [ -z "$FIELD" ]; then
  echo "❌ Field path required (e.g. .plan.stack.language)" >&2
  exit 1
fi
```

---

### 🟡 MEDIUM — `clawforge.sh` — No state file existence check for 6 commands

Only `status` checks `[ -f "$STATE_FILE" ]`. The commands `stage`, `update`, `plan`, `review-result`, `test-result`, and `deploy-result` pass the missing file directly to jq, producing:

```
jq: error: Could not open file /path/to/state.json: No such file or directory
```

**Fix:** Add to each command (or create a shared function):
```bash
if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No state file. Run: clawforge.sh init \"your task\"" >&2
  exit 1
fi
```

---

### 🟡 MEDIUM — Both scripts — Schema mismatch between `init` and `plan.sh`

`clawforge.sh init` creates structured defaults:
```json
"plan": {}, "files": {"created":[],"modified":[]}, "review": {"passed":false,"issues":[]}, ...
```

`plan.sh` creates nulls:
```json
"plan": null, "files": null, "review": null, "tests": null, "deploy": null
```

Downstream `jq '.plan.stack'` works on `{}` but crashes on `null` with `null is not defined`.

**Fix:** Use consistent defaults in `plan.sh` (copy the structure from `init`).

---

### 🟡 MEDIUM — `clawforge.sh:20-23` — `init` still writes state non-atomically

```bash
cat > "$STATE_FILE" << EOF
```

All other commands use `mktemp → jq > TMP → mv`. The `init` command does a direct `cat >` write. Interruption mid-write corrupts the file.

**Fix:**
```bash
TMP=$(mktemp)
cat > "$TMP" << EOF
...
EOF
mv "$TMP" "$STATE_FILE"
```

---

### 🟡 MEDIUM — Both scripts — No file locking for multi-agent access

ClawForge is a multi-agent state manager. Two agents calling `stage` or `update` simultaneously can race: both read the same state, both write, last writer's changes silently overwrite the first's.

**Fix:** Add advisory locking:
```bash
exec 9>"$STATE_FILE.lock"
flock -x 9
# ... critical section ...
flock -u 9
```

---

### 🟡 MEDIUM — `clawforge.sh:22` — sed escaping incomplete (no newline handling)

```bash
ESCAPED_TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
```

Handles `\`, `"`, and `\t` — but does **not** handle literal newlines in `$TASK`. A task containing an actual newline produces broken JSON.

**Fix:** Add newline escaping:
```bash
ESCAPED_TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
```

Or better yet, just use jq for encoding:
```bash
TASK_JSON=$(printf '%s' "$TASK" | jq -Rs .)
```

---

### 🟢 LOW — `clawforge.sh` — SC2312: Command substitution masks return values

ShellCheck `--enable=all` flags `$(date -u ...)` inside heredocs. If `date` fails, the error is masked.

---

## Summary

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | 🔴 High | plan.sh:22 | Trailing `\n` in every task (echo vs printf) |
| 2 | 🔴 High | clawforge.sh:73 | Empty FIELD destroys entire state file |
| 3 | 🟡 Med | clawforge.sh | No state file check for 6 commands |
| 4 | 🟡 Med | both | Schema mismatch (dicts vs nulls) |
| 5 | 🟡 Med | clawforge.sh:20 | `init` writes non-atomically |
| 6 | 🟡 Med | both | No file locking for multi-agent races |
| 7 | 🟡 Med | clawforge.sh:22 | sed escaping incomplete (no newlines) |
| 8 | 🟢 Low | clawforge.sh | SC2312 masked return values |

**8 remaining issues** (2 High, 5 Medium, 1 Low).
