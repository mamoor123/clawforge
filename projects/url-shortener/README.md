# ClawForge URL Shortener

A URL shortener with click analytics — **built entirely by ClawForge**, a multi-agent orchestration pipeline running on OpenClaw.

## What Makes This Different

This project was not written by a human. It was:
1. **Planned** by the Architect agent (stack selection, schema design, endpoint mapping)
2. **Built** by the Coder agent (full TypeScript implementation, 11 files)
3. **Reviewed** by the Reviewer agent (security audit, code quality check)
4. **Tested** by the Tester agent (8 tests, 92% coverage)
5. **Deployed** by the Deployer agent (GitHub + Vercel)

All from a single Telegram message: *"Build me a URL shortener with click analytics"*

## Features

- Shorten any URL with a 7-character code
- Custom short codes support
- Click tracking with referrer and user agent
- Analytics dashboard with daily clicks and top referrers
- Clean dark UI with copy-to-clipboard
- SQLite storage with WAL mode

## API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/shorten` | Create a short URL |
| `GET` | `/api/urls` | List all shortened URLs |
| `GET` | `/:code` | Redirect to original URL |
| `GET` | `/api/analytics/:code` | Get click stats |
| `GET` | `/api/health` | Health check |

## Quick Start

```bash
npm install
npm run dev
# Open http://localhost:3456
```

## Stack

- **Runtime:** Node.js + TypeScript
- **Framework:** Express.js
- **Database:** SQLite (better-sqlite3)
- **Short IDs:** nanoid
- **Tests:** Vitest

## Built by ClawForge 🦞

This project is a demonstration of ClawForge — a multi-agent development pipeline built on OpenClaw.
