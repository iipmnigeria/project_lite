# ProjectLite

ProjectLite is a lightweight collaborative project controls workspace for integrated scope, schedule, cost, team and change management.

## Live application

[Open ProjectLite](https://iipmnigeria.github.io/project_lite/)

## MVP capabilities

- Workspace registration and sign-in experience
- Project dashboard and delivery indicators
- Hierarchical scope and WBS register
- WBS item creation and removal
- Gantt-style integrated schedule
- FS, SS, FF and SF dependencies with lead/lag
- Critical Path Method forward and backward calculations
- Early/late dates, total float and critical activity identification
- Interactive Gantt, activity-on-node network diagram and CPM analysis table
- Cost baseline, actual expenditure and variance tracking
- Team structure, invitations and role controls
- Project collaboration feed and file interface
- Change request assessment and approval workflow
- Responsive desktop and mobile layouts
- Browser-based persistence for demonstration data
- Supabase authentication and persistent multi-project workspaces

## Run locally

### One-click Windows launcher

1. Download or clone this repository.
2. Open the project folder.
3. Double-click `RUN_PROJECTLITE.bat`.
4. Keep the launcher window open while using the application.

The launcher checks for Node.js, installs missing requirements, starts ProjectLite and opens the application in your browser.

### Command line

```bash
npm install
npm run dev
```

Then open `http://localhost:5173`.

## Demonstration sign-in

```text
Email: demo@projectlite.app
Password: project123
```

## Production build

```bash
npm run build
```

The deployable output is generated in `dist/`.

Every push to `main` automatically builds and deploys the application through GitHub Actions. In the repository settings, GitHub Pages must use **GitHub Actions** as its source.

## Current MVP limitation

This release connects to Supabase for authentication, workspaces, projects, invitations and persistent project controls data. File uploads and automatic invitation emails remain planned enhancements.

## Supabase database setup

1. Open the Supabase project SQL Editor.
2. Copy and run the complete [`supabase/schema.sql`](supabase/schema.sql) script once.
3. Under Authentication URL Configuration, set the Site URL to `https://iipmnigeria.github.io/project_lite/`.
4. Add `https://iipmnigeria.github.io/project_lite/` to Redirect URLs.

The schema enables Row Level Security. Authenticated users can access only workspaces where they hold membership.

## Recommended backend stage

- PostgreSQL/Supabase multi-tenant database
- Supabase Auth or Auth.js
- Row-level workspace security
- Real-time project collaboration
- Document storage
- Audit events and approval history
- Paystack, Flutterwave and Stripe subscriptions
