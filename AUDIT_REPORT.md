# ClawForge Multi-Agent Audit Report

**Date:** 2026-04-23  
**Audited by:** 4 parallel sub-agents + consolidated analysis  
**Files:** `clawforge.sh`, `skills/clawforge/scripts/plan.sh`, `projects/url-shortener/*`, `skills/clawforge/SKILL.md`, `agents/*/IDENTITY.md`

---

## Agent 1: Security Audit

### 🔴 S1 — Heredoc Command Expansion (clawforge.sh:28-40)

The `init` heredoc uses unquoted `<< EOF`. This means `$(...)` inside `$TASK` is **executed**.

```bash
clawforge.sh init '$(whoami)'
# Result: "task": "$(whoami)" — the command runs, output embedded in JSON
```

The sed escaping on line 24 does NOT prevent command substitution — it only escapes `\`, `"`, and `\t`. A `$(rm -rf /)` payload would execute before the sed even runs.

**Fix:** Use a quoted heredoc `<< "EOF"` and inject variables separately, or switch to jq for JSON generation:
```bash
TASK_JSON=$(printf '%s' "$TASK" | jq -Rs .)
```

### 🔴 S2 — JSON Injection via Newlines (clawforge.sh:24)

```bash
ESCAPED_TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
```

Handles `\`, `"`, and `\t` — but **not literal newlines**. A task with embedded newlines produces broken JSON.

**Fix:** Add `| tr '\n' ' '` or use `jq -Rs .` for proper encoding.

### 🟡 S3 — Path Traversal via CLAWFORGE_STATE

`CLAWFORGE_STATE` can point to any writable path. No validation that it's inside the workspace.

```bash
CLAWFORGE_STATE=/etc/crontab bash clawforge.sh init "evil"
```

**Fix:** Validate the path is within an allowed directory.

### 🟡 S4 — No File Locking (0 flock calls)

Two agents running simultaneously can race on read-modify-write of `clawforge-state.json`. Last writer wins silently.

**Fix:** Add `flock` advisory locking.

### 🟡 S5 — IP Addresses Stored in Plaintext (redirect.ts:36)

```typescript
const ip = req.ip || req.socket.remoteAddress || null;
```

IPs stored in `clicks` table — GDPR/privacy concern for production use.

---

## Agent 2: Correctness & Logic Audit

### 🔴 C1 — Empty FIELD in `update` Destroys State (clawforge.sh:73-78)

```bash
jq --arg field "" --arg value "boom" \
  'setpath($field | split(".") | map(select(. != "")); $value)' state.json
```

When `$FIELD` is empty: `split(".")` → `[""]` → filtered to `[]` → `setpath([]; "boom")` → **entire state file becomes the string `"boom"`**.

**Confirmed:** `clawforge.sh update '' 'boom'` → state file = `"boom"` (all data lost).

**Fix:**
```bash
if [ -z "$FIELD" ]; then echo "❌ Field path required" >&2; exit 1; fi
```

### 🔴 C2 — Trailing Newline in plan.sh Task (plan.sh:22)

```bash
TASK_JSON=$(echo "$REQUEST" | jq -Rs .)
```

`echo` appends `\n`, `jq -Rs` preserves it. Every task ends with `\n`.

**Confirmed:** task = `'Build API\n'` — breaks string comparisons.

**Fix:** `printf '%s' "$REQUEST"` instead of `echo`.

### 🟡 C3 — No State File Check for 5 Commands

`stage`, `update`, `review-result`, `test-result`, `deploy-result` all pass a missing file to jq, producing raw `jq: error: Could not open file`.

Only `status` checks `[ -f "$STATE_FILE" ]`.

**Fix:** Add existence check to each command.

### 🟡 C4 — Schema Mismatch: init vs plan.sh

| Field | clawforge.sh init | plan.sh |
|-------|-------------------|---------|
| plan | `{}` | `null` |
| files | `{"created":[],"modified":[]}` | `null` |
| review | `{"passed":false,"issues":[]}` | `null` |
| tests | `{"total":0,...}` | `null` |
| deploy | `{"url":"",...}` | `null` |

Downstream `jq '.plan.stack'` works on `{}` but **crashes on `null`**.

**Fix:** Use consistent defaults in plan.sh.

### 🟡 C5 — test-result Accepts Non-Numeric Values

`clawforge.sh test-result abc 8 2` → jq `tonumber` fails with raw error. No input validation.

### 🟢 C6 — init Still Writes Non-Atomically

`cat > "$STATE_FILE" << EOF` — no temp+mv. Low risk since `mkdir -p` ensures directory exists.

---

## Agent 3: TypeScript Project Audit

### 🟡 T1 — No Input Length Validation (shorten.ts)

No max length on `url` or `customCode` fields. A multi-GB POST body causes DoS.

**Fix:** Add `if (url.length > 2048) return res.status(400).json({error: 'URL too long'})`.

### 🟡 T2 — No Rate Limiting

No `express-rate-limit` or equivalent. Anyone can spam `POST /api/shorten` to exhaust disk/DB.

### 🟡 T3 — No Security Headers

No `helmet`, no CSP, no HSTS, no X-Frame-Options. The app is vulnerable to clickjacking and other client-side attacks.

**Fix:** `npm install helmet` and `app.use(helmet())`.

### 🟡 T4 — IP Privacy Concern (redirect.ts:36)

IPs stored in plaintext. Should be hashed or anonymized for GDPR compliance.

### 🟢 T5 — Missing Test Coverage

10 tests exist, but missing: `GET /api/urls`, `GET /api/health`, concurrent requests, edge cases (SQL injection attempts, malformed JSON, very long URLs).

### ✅ T6 — SQL Injection: Protected

All queries use parameterized statements (`?` placeholders). No string concatenation in SQL.

### ✅ T7 — Error Messages: Safe

Generic "Database error" returned. No stack traces leaked.

### ✅ T8 — XSS: Safe

404 page uses static HTML. No user input embedded in responses.

---

## Agent 4: Architecture & Cross-File Audit

### ✅ A1 — SKILL.md: Accurate

No references to `build.sh` (removed in ef32fa3). All script paths match actual files.

### ✅ A2 — Agent Identity Files: All Present

All 5 agents (architect, coder, reviewer, tester, deployer) have identity files.

### ✅ A3 — Error Messages: Consistent

Both scripts use `❌` prefix and `>&2` for errors. Consistent style.

### ✅ A4 — State Schema: Matches Expected Keys

`clawforge-state.json` top-level keys match what the code expects.

### 🟢 A5 — Plan.sh Error Message Inconsistency

`clawforge.sh` says: `"❌ jq is required but not installed. Install it with: apt-get install jq"`  
`plan.sh` says: `"❌ jq is required but not installed."`

Minor inconsistency — different messages for the same condition.

---

## Consolidated Summary

| # | ID | Severity | File | Issue |
|---|-----|----------|------|-------|
| 1 | S1 | 🔴 High | clawforge.sh:28 | Heredoc executes `$(...)` in user input |
| 2 | S2 | 🔴 High | clawforge.sh:24 | sed escaping doesn't handle newlines |
| 3 | C1 | 🔴 High | clawforge.sh:73 | Empty FIELD destroys entire state file |
| 4 | C2 | 🔴 High | plan.sh:22 | Trailing `\n` in every task (echo vs printf) |
| 5 | S3 | 🟡 Med | clawforge.sh:6 | Path traversal via CLAWFORGE_STATE |
| 6 | S4 | 🟡 Med | clawforge.sh | No file locking for multi-agent races |
| 7 | C3 | 🟡 Med | clawforge.sh | No state file check for 5 commands |
| 8 | C4 | 🟡 Med | both | Schema mismatch (dicts vs nulls) |
| 9 | C5 | 🟡 Med | clawforge.sh:112 | test-result accepts non-numeric values |
| 10 | T1 | 🟡 Med | shorten.ts | No input length validation (DoS risk) |
| 11 | T2 | 🟡 Med | shorten.ts | No rate limiting |
| 12 | T3 | 🟡 Med | index.ts | No security headers (helmet) |
| 13 | T4 | 🟡 Med | redirect.ts:36 | IP addresses stored in plaintext |
| 14 | S5 | 🟡 Med | redirect.ts:36 | IP privacy (GDPR concern) |
| 15 | C6 | 🟢 Low | clawforge.sh:28 | init writes non-atomically |
| 16 | T5 | 🟢 Low | api.test.ts | Missing test coverage for several endpoints |
| 17 | A5 | 🟢 Low | plan.sh vs clawforge.sh | Inconsistent jq error messages |

**Total: 17 issues** — 4 High, 10 Medium, 3 Low

### Priority Fix Order

1. **S1** — Heredoc command injection (security critical)
2. **C1** — Empty FIELD destroys state (data loss)
3. **C2** — Trailing newline in plan.sh (data corruption)
4. **S2** — Newline escaping gap (data corruption)
5. **T1-T3** — DoS and security headers (production readiness)
6. **C3-C4** — State file checks and schema consistency (reliability)
7. **S3-S4** — Path traversal and locking (hardening)
