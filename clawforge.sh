#!/usr/bin/env bash
# ClawForge — State Manager
# Manages the shared state file between agents
set -euo pipefail

STATE_FILE="${CLAWFORGE_STATE:-$HOME/.openclaw/workspace/clawforge-state.json}"
ACTION="${1:-status}"

case "$ACTION" in
  init)
    TASK="${2:-}"
    cat > "$STATE_FILE" << EOF
{
  "task": "$TASK",
  "stage": "architect",
  "status": "initialized",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "plan": {},
  "files": {"created": [], "modified": []},
  "review": {"passed": false, "issues": []},
  "tests": {"total": 0, "passing": 0, "failing": 0, "details": []},
  "deploy": {"url": "", "repo": "", "pr": "", "verified": false}
}
EOF
    echo "✅ State initialized: $STATE_FILE"
    echo "   Task: $TASK"
    ;;

  stage)
    STAGE="${2:-}"
    STATUS="${3:-running}"
    # Update stage and status using jq
    if command -v jq &>/dev/null; then
      TMP=$(mktemp)
      jq --arg stage "$STAGE" --arg status "$STATUS" \
        '.stage = $stage | .status = $status' "$STATE_FILE" > "$TMP"
      mv "$TMP" "$STATE_FILE"
      echo "✅ Stage: $STAGE | Status: $STATUS"
    else
      echo "⚠️  jq not found, using sed fallback"
      sed -i "s/\"stage\": \"[^\"]*\"/\"stage\": \"$STAGE\"/" "$STATE_FILE"
      sed -i "s/\"status\": \"[^\"]*\"/\"status\": \"$STATUS\"/" "$STATE_FILE"
    fi
    ;;

  update)
    # Generic field update: clawforge.sh update .plan.stack.language "TypeScript"
    FIELD="${2:-}"
    VALUE="${3:-}"
    if command -v jq &>/dev/null; then
      TMP=$(mktemp)
      jq --arg field "$FIELD" --arg value "$VALUE" \
        'setpath($field | split(".") | map(select(. != "")); $value)' "$STATE_FILE" > "$TMP"
      mv "$TMP" "$STATE_FILE"
      echo "✅ Updated: $FIELD = $VALUE"
    fi
    ;;

  status)
    if [ -f "$STATE_FILE" ]; then
      echo "📋 ClawForge State:"
      if command -v jq &>/dev/null; then
        jq '{task: .task, stage: .stage, status: .status}' "$STATE_FILE"
      else
        cat "$STATE_FILE"
      fi
    else
      echo "❌ No state file found. Run: clawforge.sh init \"your task\""
    fi
    ;;

  plan)
    # Write a plan to state
    PLAN_FILE="${2:-}"
    if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
      if command -v jq &>/dev/null; then
        PLAN=$(cat "$PLAN_FILE")
        TMP=$(mktemp)
        jq --argjson plan "$PLAN" '.plan = $plan | .stage = "architect" | .status = "plan_complete"' "$STATE_FILE" > "$TMP"
        mv "$TMP" "$STATE_FILE"
        echo "✅ Plan written to state"
      fi
    else
      echo "Usage: clawforge.sh plan <plan-file.json>"
    fi
    ;;

  review-result)
    PASSED="${2:-true}"
    ISSUES="${3:-}"
    if command -v jq &>/dev/null; then
      TMP=$(mktemp)
      jq --arg passed "$PASSED" --arg issues "$ISSUES" \
        '.review.passed = ($passed == "true") | .review.issues = ($issues | split(",")) | .stage = "reviewer" | .status = (if $passed == "true" then "review_passed" else "review_failed" end)' \
        "$STATE_FILE" > "$TMP"
      mv "$TMP" "$STATE_FILE"
      echo "✅ Review result: passed=$PASSED"
    fi
    ;;

  test-result)
    TOTAL="${2:-0}"
    PASSING="${3:-0}"
    FAILING="${4:-0}"
    if command -v jq &>/dev/null; then
      TMP=$(mktemp)
      jq --arg t "$TOTAL" --arg p "$PASSING" --arg f "$FAILING" \
        '.tests.total = ($t|tonumber) | .tests.passing = ($p|tonumber) | .tests.failing = ($f|tonumber) | .stage = "tester" | .status = (if $f == "0" then "tests_passed" else "tests_failed" end)' \
        "$STATE_FILE" > "$TMP"
      mv "$TMP" "$STATE_FILE"
      echo "✅ Test result: $PASSING/$TOTAL passing"
    fi
    ;;

  deploy-result)
    URL="${2:-}"
    REPO="${3:-}"
    if command -v jq &>/dev/null; then
      TMP=$(mktemp)
      jq --arg url "$URL" --arg repo "$REPO" \
        '.deploy.url = $url | .deploy.repo = $repo | .deploy.verified = true | .stage = "deployer" | .status = "complete"' \
        "$STATE_FILE" > "$TMP"
      mv "$TMP" "$STATE_FILE"
      echo "✅ Deployed: $URL"
    fi
    ;;

  *)
    echo "ClawForge State Manager"
    echo ""
    echo "Usage: clawforge.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init <task>              Initialize state with task description"
    echo "  stage <name> <status>    Update current stage"
    echo "  status                   Show current state"
    echo "  plan <file.json>         Write plan to state"
    echo "  review-result <pass>     Record review result"
    echo "  test-result <tot> <pass> Record test results"
    echo "  deploy-result <url>      Record deployment"
  echo "  update <field> <value>   Update a field in state"
    ;;
esac
