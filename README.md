# ProjectLite

ProjectLite is a lightweight collaborative project controls workspace for integrated scope, schedule, cost, team and change management.

## MVP capabilities

- Workspace registration and sign-in experience
- Project dashboard and delivery indicators
- Hierarchical scope and WBS register
- WBS item creation and removal
- Gantt-style integrated schedule
- Cost baseline, actual expenditure and variance tracking
- Team structure, invitations and role controls
- Project collaboration feed and file interface
- Change request assessment and approval workflow
- Responsive desktop and mobile layouts
- Browser-based persistence for demonstration data

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

## Current MVP limitation

This release is a functional front-end MVP. Demonstration data is saved in browser storage and is therefore local to each browser. Production multi-user collaboration requires the planned authentication, database, file storage, real-time events and workspace-level access-control backend.

## Recommended backend stage

- PostgreSQL/Supabase multi-tenant database
- Supabase Auth or Auth.js
- Row-level workspace security
- Real-time project collaboration
- Document storage
- Audit events and approval history
- Paystack, Flutterwave and Stripe subscriptions

