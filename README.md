# 🦞 ClawForge

**An autonomous multi-agent development pipeline built on [OpenClaw](https://github.com/openclaw/openclaw).**

One prompt in. Working software out. Plan → Build → Review → Test → Deploy — fully autonomous.

```
You: "Build me a URL shortener with click analytics"
                    │
        ┌───────────▼───────────┐
        │  🧠 Architect Agent   │  Plans stack, schema, endpoints
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │  💻 Coder Agent       │  Implements full project (11 files)
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │  🔍 Reviewer Agent    │  Security audit, code quality gate
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │  🧪 Tester Agent      │  Writes & runs test suite
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │  🚀 Deployer Agent    │  Git init, GitHub push, deploy
        └───────────┬───────────┘
                    │
            ✅ Live URL + Repo
```

## What It Does

ClawForge is a [skill](skills/clawforge/SKILL.md) for OpenClaw that orchestrates five specialized agents to take a project from idea to production:

| Agent | Role | Output |
|-------|------|--------|
| 🧠 **Architect** | Stack selection, schema design, API planning | `clawforge-state.json` with full plan |
| 💻 **Coder** | Full implementation in TypeScript/whatever fits | Production-ready source files |
| 🔍 **Reviewer** | Security audit, code quality, best practices | Pass/fail with specific issues |
| 🧪 **Tester** | Write and run test suite | Test results + coverage report |
| 🚀 **Deployer** | Git setup, GitHub push, live deployment | Repo URL + live URL |

All agents communicate through a shared state file (`clawforge-state.json`). If review or tests fail, the pipeline loops back to the Coder with specific fix instructions — up to 2 retries per stage.

## How to Use

From any OpenClaw chat (Telegram, Discord, CLI):

```
Build me a URL shortener with click analytics
```

Or explicitly:

```
ClawForge: Create a habit tracking API with user auth
```

That's it. ClawForge handles the rest.

## Project Structure

```
clawforge/
├── clawforge.sh                          # State manager (shared by all agents)
├── clawforge-state.json                  # Runtime state (agent communication)
├── skills/clawforge/
│   ├── SKILL.md                          # Orchestrator instructions
│   └── scripts/
│       └── plan.sh                       # Stage 1: Architect entry point
├── agents/
│   ├── architect/IDENTITY.md             # 🧠 Plans the project
│   ├── coder/IDENTITY.md                 # 💻 Builds the project
│   ├── reviewer/IDENTITY.md              # 🔍 Audits the code
│   ├── tester/IDENTITY.md                # 🧪 Tests the project
│   └── deployer/IDENTITY.md              # 🚀 Ships the project
└── projects/
    └── url-shortener/                    # Example: built by ClawForge
```

## State Machine

```
initialized → architect → coder → reviewer → tester → deployer → complete
                  ↑          ↑        ↑
                  └──────────┴────────┘  (retry on failure, max 2x)
```

Each stage updates `clawforge-state.json`. The orchestrator reads the state to determine what happens next.

## Commands

```bash
# Initialize state for a new project
bash clawforge.sh init "Build a REST API"

# Check current pipeline status
bash clawforge.sh status

# Update any field in state
bash clawforge.sh update .plan.stack.language "TypeScript"

# Record results from each stage
bash clawforge.sh stage architect plan_complete
bash clawforge.sh review-result true ""
bash clawforge.sh test-result 10 8 2
bash clawforge.sh deploy-result https://live-url.com https://github.com/...
```

## Demo: URL Shortener

The first project built by ClawForge — a full URL shortener with click analytics:

- **Stack:** TypeScript, Express.js, SQLite, nanoid
- **Files:** 11 source files, fully typed
- **Tests:** 10 tests, all passing
- **Features:** Short URLs, custom codes, click tracking, analytics dashboard

→ [Live Demo](https://e97a84bc1795856b-8-219-194-199.serveousercontent.com)  
→ [Source Code](projects/url-shortener/)  
→ [Audit Report](AUDIT_REPORT.md) (21 issues found and documented)

## Built With

- **[OpenClaw](https://github.com/openclaw/openclaw)** — The AI agent platform
- **5 specialized agents** — Each with a focused identity and checklist
- **1 Telegram message** — The only human input

## License

MIT
