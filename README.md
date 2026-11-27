# NailBook

Online booking website for a nail artist: services, availability calendar, bookings and an admin panel.

> **Status:** under construction (Phase 0: foundations). This is a portfolio project and the business is fictional.

## Planned stack

- **Frontend:** Next.js 16 (React, TypeScript), Tailwind CSS
- **Backend:** ASP.NET Core Web API (.NET 10 LTS), layered architecture
- **Database:** PostgreSQL
- **Tooling:** Docker Compose, GitHub Actions

## Repository structure

| Folder | Contents |
|---|---|
| `web/` | Next.js frontend |
| `api/` | ASP.NET Core backend |
| `docs/` | Project documents (architecture, security, conventions) |

## Requirements

- .NET SDK 10 (pinned in `api/global.json`)
- Node.js 24 LTS (pinned in `web/.nvmrc`)
- Docker Desktop
- Git

## Getting started

Setup instructions will be added as the project grows.

1. Copy `.env.example` to `.env` and adjust the values.
2. Never commit `.env` or any real secret.

## License

To be defined.