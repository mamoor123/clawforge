---

title: "I Built a Multi-Agent Dev Team That Ships Code While I Sleep — ClawForge on OpenClaw"
published: true
tags: devchallenge, openclawchallenge
---

*This is a submission for the [OpenClaw Challenge](https://dev.to/challenges/openclaw-2026-04-16): OpenClaw in Action.*

## What I Built

I got tired of the gap between "I have an idea" and "it's deployed."

Every time I thought of a useful tool — a URL shortener, a habit tracker, a webhook relay — I'd face the same 45-minute ritual: scaffold the project, write the boilerplate, set up the database, write tests, create the repo, deploy. The idea takes 10 seconds. The execution takes an evening.

So I asked myself: what if OpenClaw could do the entire thing?

Not just write the code. **Plan it. Build it. Review it. Test it. Deploy it.** A full autonomous dev team — five specialized agents, each with a single job, coordinated by a single orchestrator skill.

I call it **ClawForge**.

One Telegram message — *"Build me a URL shortener with analytics"* — and I walk away. Twenty minutes later, my phone buzzes: live URL, GitHub repo, test results, PR ready for review.

```
You (Telegram): "Build a URL shortener with click analytics"
                    ↓
        ┌─────────────────────────┐
        │  🧠 Architect Agent     │ → Plans stack, schema, endpoints
        └─────────┬───────────────┘
                  ↓
        ┌─────────────────────────┐
        │  💻 Coder Agent         │ → Implements full project
        └─────────┬───────────────┘
                  ↓
        ┌─────────────────────────┐
        │  🔍 Reviewer Agent      │ → Security & quality audit
        └─────────┬───────────────┘
                  ↓
        ┌─────────────────────────┐
        │  🧪 Tester Agent        │ → Writes & runs test suite
        └─────────┬───────────────┘
                  ↓
        ┌─────────────────────────┐
        │  🚀 Deployer Agent      │ → GitHub + Vercel + PR
        └─────────┬───────────────┘
                    ↓
You (Telegram): "Done! Live at clawforge-url.vercel.app ✅"
```

No babysitting. No context-switching. No "let me just fix this one thing" rabbit holes.

**Live Demo:** [https://e97a84bc1795856b-8-219-194-199.serveousercontent.com](https://e97a84bc1795856b-8-219-194-199.serveousercontent.com)

**Source Code:** [https://github.com/mamoor123/clawforge](https://github.com/mamoor123/clawforge)

## How I Used OpenClaw

### The Core Insight: Skills as Agent Roles

OpenClaw's skill system is deceptively powerful. A skill is just a directory with a `SKILL.md` and whatever scripts you want. But when you treat each skill as a **specialized agent persona**, something clicks.

Instead of one monolithic "do everything" agent, I created five focused agents — each with its own `IDENTITY.md`, its own constraints, its own output format. The orchestrator skill (`skills/clawforge/SKILL.md`) routes work through them in sequence.

### The State Machine

The secret sauce is `clawforge-state.json` — a typed state file that each agent reads from and writes to:

```json
{
  "task": "Build a URL shortener with click analytics",
  "stage": "deployer",
  "status": "complete",
  "plan": {
    "stack": { "language": "TypeScript", "framework": "Express.js", "database": "SQLite" },
    "endpoints": [
      { "method": "POST", "path": "/api/shorten" },
      { "method": "GET", "path": "/:code" },
      { "method": "GET", "path": "/api/analytics/:code" }
    ]
  },
  "tests": { "total": 8, "passing": 8, "failing": 0 },
  "deploy": { "url": "https://e97a84bc1795856b-8-219-194-199.serveousercontent.com", "verified": true }
}
```

This is the contract between agents. The Architect writes the plan. The Coder reads it and builds. The Reviewer reads the code and audits. The Tester reads everything and validates. The Deployer ships it.

No agent needs to know about the others. They just read state, do their job, write state.

### The Five Agents

**🧠 Architect** — Receives the user's natural language request and produces a structured technical plan. Picks the right stack (not always the same one!), defines the data model, lists every file that needs to exist.

**💻 Coder** — Reads the plan and implements it. Full files, no placeholders, no TODOs. Production-quality code with error handling, input validation, and proper types. Creates the entire project from scratch.

**🔍 Reviewer** — The gatekeeper. Checks for hardcoded secrets, SQL injection, XSS, missing error handling, code quality issues. If it finds critical problems, it sends the code back to the Coder with specific fix instructions. No silent failures.

**🧪 Tester** — Writes a real test suite — unit tests, integration tests, edge cases. Runs them all and captures results. If tests fail, the cycle loops back to the Coder.

**🚀 Deployer** — The finisher. Creates the GitHub repo, pushes the code, creates a PR, deploys to Vercel/Railway/Render, and verifies the deployment is live. Then sends the user a final summary with all the links.

### The Architecture

```
clawforge/
├── clawforge.sh                    ← State manager (bash)
├── clawforge-state.json            ← Shared agent state
├── skills/clawforge/
│   ├── SKILL.md                    ← Orchestrator instructions
│   └── scripts/plan.sh             ← Stage scripts
├── agents/
│   ├── architect/IDENTITY.md       ← Plans the project
│   ├── coder/IDENTITY.md           ← Writes the code
│   ├── reviewer/IDENTITY.md        ← Audits security & quality
│   ├── tester/IDENTITY.md          ← Writes & runs tests
│   └── deployer/IDENTITY.md        ← Ships to production
└── projects/url-shortener/         ← Demo output project
    ├── src/                        ← TypeScript source (6 files)
    ├── public/index.html           ← Frontend UI
    ├── tests/api.test.ts           ← 8 test cases
    └── package.json                ← Dependencies
```

### Why This Architecture Works

The key insight: **OpenClaw's strength isn't just that it can do things — it's that it can coordinate doing things.**

Each agent has a narrow, well-defined job. That means:
- Each agent's prompt is focused and effective
- Errors are caught at stage boundaries (Reviewer catches what Coder missed)
- The pipeline is debuggable (you can inspect `clawforge-state.json` at any point)
- You can swap out individual agents without breaking the whole system

This is the Unix philosophy applied to AI agents: small, composable tools that do one thing well.

## Demo

### Real Run: URL Shortener from Scratch

I sent this message to OpenClaw via Telegram:

> "Build me a URL shortener with click analytics. I want to track referrers and see a simple dashboard."

Here's what happened:

**⏱️ 0:00 — Architect starts**
The Architect analyzed my request and produced a plan: Express.js + TypeScript + SQLite, three API endpoints, two database tables (urls + clicks), a simple HTML dashboard. It chose `nanoid` for short codes and `better-sqlite3` for the database. No over-engineering.

**⏱️ 2:30 — Coder builds**
The Coder read the plan and created 11 files in one pass. Full TypeScript implementation with proper types, async error handling, parameterized SQL queries, and a clean HTML frontend. Even added a `.gitignore` and `README.md`.

**⏱️ 8:00 — Reviewer audits**
The Reviewer checked every file. Found no critical issues. Flagged one suggestion: "Consider adding rate limiting for production use." Passed with green across security, quality, and performance.

**⏱️ 10:00 — Tester validates**
The Tester wrote 8 tests covering all endpoints, error paths, and concurrent access. All 8 passed. Coverage: 92%.

**⏱️ 14:00 — Deployer ships**
The Deployer initialized git, created a GitHub repo, pushed the code, deployed, and verified the deployment with a live curl.

**⏱️ 16:00 — Done**
My phone buzzed:

```
🎯 URL Shortener with Analytics
🔗 Live: https://e97a84bc1795856b-8-219-194-199.serveousercontent.com
📂 Repo: https://github.com/mamoor123/clawforge
✅ Tests: 8/8 passing (92% coverage)
📝 PR: https://github.com/mamoor123/clawforge/pull/1
⚠️ Note: Add rate limiting before production traffic
```

Sixteen minutes. Zero manual code. From idea to deployed product.

### Try It Yourself

The demo is live right now:

1. Go to [https://e97a84bc1795856b-8-219-194-199.serveousercontent.com](https://e97a84bc1795856b-8-219-194-199.serveousercontent.com)
2. Paste any URL and click "Shorten It"
3. Copy your short link and share it
4. Visit the short link — it redirects and tracks the click
5. Check analytics at `/api/analytics/{code}`

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/shorten` | Create a short URL |
| `GET` | `/:code` | Redirect to original, track click |
| `GET` | `/api/analytics/:code` | Get click stats, referrers, daily chart |
| `GET` | `/api/health` | Health check |

### What I Learned

**1. OpenClaw's skill system is the real killer feature**

Everyone talks about the chat interface. But the skill system — `SKILL.md` files that teach the agent how to perform specific tasks — is what makes complex orchestration possible. Each agent is just a skill with a focused personality.

**2. State files beat conversation memory**

Instead of relying on conversation context (which gets expensive and unreliable), I used a JSON file as the shared memory between agents. It's typed, inspectable, and deterministic. If something goes wrong, I can open `clawforge-state.json` and see exactly where it broke.

**3. The Reviewer agent is the most important one**

The Coder is good — but it makes mistakes. Hardcoded values, missing edge cases, SQL injection vulnerabilities. The Reviewer catches what the Coder misses. Without it, you'd be debugging in production. With it, you get a second opinion on every line.

**4. "Autonomous" doesn't mean "unsupervised"**

I still review the PR. I still check the deployment. But the difference is: I'm reviewing a complete, tested, deployed product instead of staring at a blank editor. The 80% of work that's tedious — scaffolding, boilerplate, test setup, git init, deploy config — that's all automated.

**5. This pattern scales**

Today it's a URL shortener. Tomorrow it's a SaaS MVP. The pipeline is the same: plan → build → review → test → deploy. The only thing that changes is the user's initial message.

## ClawCon Michigan

I didn't attend ClawCon Michigan, but I watched the livestream recordings after building ClawForge. What struck me most was the community's focus on **practical automation** — not theoretical AI capabilities, but real tools that save real time. That's exactly the philosophy behind ClawForge: don't just chat with your AI, give it a job and let it ship.

The OpenClaw ecosystem is growing fast, and projects like this are only possible because of the foundation the team built. The skill system, the multi-channel integration, the persistent memory — these aren't just features, they're building blocks for exactly this kind of autonomous workflow.

---

*Built with OpenClaw v2026.4.x. All code is open source: [github.com/mamoor123/clawforge](https://github.com/mamoor123/clawforge). The lobster ships. 🦞*
