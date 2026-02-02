# DevCo Service Management

A Jira-style service management app with a modern, clean dark UI. Built with Rails 8 API + React + TypeScript.

## Architecture

- **Backend:** Rails 8 API-only (port 4000)
- **Frontend:** React + TypeScript + Vite (port 5173 in dev)
- **Database:** Shares `devco_platform_development` PostgreSQL database
- **Source of truth:** JSON files in `data/` directory
- **DB is a read-optimized index** — files always win

## Quick Start

```bash
# Install dependencies
bundle install
cd client && npm install && cd ..

# Run migrations
bin/rails db:migrate

# Seed from JSON files
bin/rails db:seed

# Start both servers
bin/dev
```

- **API:** http://localhost:4000
- **Frontend:** http://localhost:5173

## Data Model

All work items are stored as JSON files in `data/`:

```
data/
  projects/TAB.json       # Project metadata
  issues/TAB-1.json       # Individual work items
  boards/TAB-board.json   # Board/column config
```

### File-First Workflow

1. **Create/Update:** Write JSON file → sync to DB
2. **Delete:** Remove references from linked files → delete file → delete from DB
3. **Repair:** Nuke all `sm_` tables → rebuild from JSON files

## API Endpoints

All endpoints are under `/api/v1`:

| Method | Path | Description |
|--------|------|-------------|
| GET | /projects | List all projects |
| POST | /projects | Create project |
| GET | /projects/:key | Get project details |
| PUT | /projects/:key | Update project |
| DELETE | /projects/:key | Delete project |
| GET | /projects/:key/issues | List project issues |
| POST | /projects/:key/issues | Create issue |
| GET | /projects/:key/board | Get kanban board |
| GET | /issues/:tracking_id | Get issue details |
| PUT | /issues/:tracking_id | Update issue |
| DELETE | /issues/:tracking_id | Delete issue |
| POST | /issues/:tracking_id/transitions | Change status |
| POST | /issues/:tracking_id/comments | Add comment |
| POST | /repair | Rebuild DB from files |
| GET | /me | Current user |

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| N | Create new issue |
| / | Focus search |
| Esc | Close panel/modal |

## Database Tables

All tables use `sm_` prefix to avoid conflicts with the platform:

- `sm_projects` — Project metadata
- `sm_issues` — Work items
- `sm_issue_links` — Issue relationships
- `sm_boards` — Kanban board config
- `sm_comments` — Issue comments
- `sm_transitions` — Status change history
