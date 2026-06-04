# QR Inventory Management System (QRIMS)

QRIMS is a modern, enterprise-grade, cross-platform ecosystem designed to replace legacy scanning systems. It provides a highly maintainable, scalable, offline-first solution built with a containerized modular architecture.

---

## 🛠️ Technology Stack

1. **Backend API**: [NestJS](https://nestjs.com/) (Modular Monolith) + [Prisma ORM](https://www.prisma.io/) + [PostgreSQL](https://www.postgresql.org/)
2. **Web Portal**: [Next.js 14](https://nextjs.org/) (App Router) + [Tailwind CSS](https://tailwindcss.com/) + [Shadcn UI](https://ui.shadcn.com/)
3. **Mobile Client**: [Flutter](https://flutter.dev/) (iOS, Android, Tablets, Foldables) + [Riverpod](https://riverpod.dev/) + [Drift SQLite Cache](https://drift.simonbinder.eu/)

---

## 📂 Project Structure

```
├── apps/
│   ├── backend/        # NestJS API Layer (JWT security, Prisma ORM database clients)
│   ├── web/            # Next.js 14 Admin Panel (Bento Grid operations console)
│   └── mobile/         # Flutter responsive client app (Drift offline-first sync cache)
├── .github/
│   └── workflows/      # GitHub Actions CI quality gate pipeline config
├── docker-compose.yml  # Docker multi-container services definition
├── start-debug.sh      # Developer local debug orchestration script
└── build-prod.sh       # Production builds compiler script
```

---

## 🚀 Getting Started

### Prerequisites
* Docker & Docker Compose
* Node.js v18+
* Flutter SDK (3.16.x+)

### Option A: Local Developer Debug Stack
To start the database containers, run schema migrations, generate prisma bindings, and launch the backend and frontend services in watcher/debug mode, run:
```bash
./start-debug.sh
```

### Option B: Compiling Production Builds
To run compiled builds natively (NestJS JS output, Next.js standalone static files, and Flutter Android Release APK/AAB) or bundle the docker containers, run:
```bash
./build-prod.sh
```

* **Backend Output**: `apps/backend/dist/`
* **Web Output**: `apps/web/.next/`
* **Mobile APK Output**: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

### Option C: Production Container Deployment
To boot the production build using Docker Compose:
```bash
docker compose up --build -d
```

---

## 📱 Mobile Architecture & Caching

The Flutter application (`apps/mobile`) features a responsive layout designed for iOS/Android phones, tablets, and larger form factors:
1. **Adaptive Navigation**: Swaps between a Bottom Navigation Bar (on phones), Navigation Rail (on tablets), and full Navigation Sidebar (on desktops).
2. **Local Caching (Drift SQLite)**: Uses a secure, local embedded SQLite database (`drift_database.dart`) containing:
   * `LocalProducts`: Caches the catalog for offline validation.
   * `LocalCartItems`: Tracks cart states to protect data during connection losses.
   * `SyncQueue`: Enqueues checkout payloads during offline states to sync them back once a connection is restored.

---

## 🖨️ Wi-Fi Billing & Printing System

The Flutter application integrates a raw network printing engine (`print_service.dart`) to scan and print receipts on thermal receipt printers over the local network:
1. **Wi-Fi Subnet Scanning**: Probes IP addresses concurrently on the local subnet for port `9100` (the industry standard port for raw network printing).
2. **Raw ESC/POS Commands**: Establishes a direct TCP socket connection and pushes raw printer byte sequences (e.g., paper cutting, alignment centering, and formatting) to automatically generate receipts.
3. **Usage**: Tap the **DISCOVER & PRINT BILL** button on the checkout screen to scan the network, choose a discovered printer, and print the bill.

---

## 🛡️ Security & CVE Remediation Guide

This guide details how to identify, patch, and remediate Common Vulnerabilities and Exposures (CVEs) across the frontend, backend, and container images.

### 1. Node.js Dependency Vulnerabilities (NestJS / Next.js)
Node.js dependencies can contain security alerts. To patch them:

* **Step 1: Check for vulnerabilities**
  Go into either `apps/backend/` or `apps/web/` and run:
  ```bash
  npm audit
  ```
* **Step 2: Automate patching**
  Apply automatic safe patches:
  ```bash
  npm audit fix
  ```
* **Step 3: Force upgrade breaking packages**
  For vulnerabilities that require major upgrades (breaking changes):
  ```bash
  npm audit fix --force
  ```
* **Step 4: Manual overrides (Overriding transitive dependencies)**
  If a nested dependency contains a CVE and the parent package has not updated its package.json, override it in your parent `package.json`:
  ```json
  "overrides": {
    "flawed-transitive-package": "^2.1.4"
  }
}
  ```
  Then run `npm install`.

---

### 2. Docker Container Vulnerabilities
Ecosystem Docker images utilize minimal `alpine` nodes to keep attack surfaces low. To scan and resolve container CVEs:

* **Step 1: Run vulnerability scans**
  Scan images using [Trivy](https://github.com/aquasecurity/trivy) or [Snyk](https://snyk.io/):
  ```bash
  trivy image qrims-backend:latest
  # Or using Docker's native scanner:
  docker scout cves qrims-backend:latest
  ```
* **Step 2: Update base images**
  Most container vulnerabilities are resolved by updating the base OS packages. Update the Dockerfile stages to include the latest minor package security patches:
  ```dockerfile
  FROM node:18-alpine AS builder
  # Add updates to patch OS-level libraries:
  RUN apk update && apk upgrade
  ```
* **Step 3: Rebuild without cache**
  ```bash
  docker compose build --no-cache
  ```

---

### 3. Flutter / Dart Package Security
Ensure Flutter packages are secure by keeping dependencies current:

* **Check for updates**:
  ```bash
  cd apps/mobile
  flutter pub outdated
  ```
* **Perform upgrades**:
  ```bash
  # Upgrade all packages within version constraints:
  flutter pub upgrade
  # Upgrade packages to major versions (resolving major CVEs):
  flutter pub upgrade --major-versions
  ```

---

### 4. CI/CD Automated Patching
To ensure vulnerabilities are caught and patched automatically before they hit production:
1. **GitHub Dependabot**: Enable Dependabot alerts in this repository. Ensure a `.github/dependabot.yml` exists to auto-submit PRs when dependencies contain CVE warnings.
2. **CI Gates**: The project `.github/workflows/ci.yml` pipeline compiles all applications on every pull request, ensuring security patches do not break builds.

---

## 💾 Database Persistence & Production Migrations

This guide explains how to manage PostgreSQL data persistence, execute Prisma schema migrations, and perform safe table alterations in production.

### 1. Database Data Persistence (Local & Host)
By default, `docker-compose.yml` uses a named Docker volume (`pgdata`) to persist PostgreSQL records:
```yaml
volumes:
  pgdata:
```
To map the PostgreSQL database folder directly to a folder on your host machine (e.g., `./data/db` in the project directory), modify the `volumes` mapping for the `postgres` service in `docker-compose.yml`:

1. Update the `postgres` service `volumes` section:
   ```yaml
   services:
     postgres:
       ...
       volumes:
         - ./data/db:/var/lib/postgresql/data
   ```
2. Remove the named volume declaration at the bottom of `docker-compose.yml` (since you are now using a relative host path).
3. Ensure the `data/db` directory exists and has appropriate read/write permissions for the container database user.

---

### 2. How to Run Database Migrations in Production
In production environments (like AWS ECS, Kubernetes, or standalone VM servers), **do not** run `npx prisma migrate dev` as it is interactive and attempts to recreate/reset databases if drifts are detected.

Instead, execute migrations using:
```bash
npx prisma migrate deploy
```
* **What it does**: Applies all pending migrations (from your `prisma/migrations` folder) to the database without resetting any data.
* **Best Practice**: Run this command as a post-build or pre-deployment hook in your release pipeline. In this codebase, the production `Dockerfile` entry point executes `npx prisma migrate deploy` automatically before starting the NestJS application server:
  ```dockerfile
  CMD ["sh", "-c", "cd apps/backend && npx prisma migrate deploy && cd ../.. && node apps/backend/dist/main"]
  ```

---

### 3. Safely Altering Tables (Schema Changes) in Production
When making schema modifications (such as adding/modifying columns, changing types, or setting constraints), follow these steps to prevent database locking, downtime, or data loss:

#### Step 1: Modify the Schema Locally
1. Edit the Prisma schema file: `apps/backend/prisma/schema.prisma`.
2. Generate the migration file by running:
   ```bash
   npx prisma migrate dev --name <migration_name>
   ```
   * *Note: Ensure your local database is running. This creates a new directory in `apps/backend/prisma/migrations/` containing a `migration.sql` script.*
3. Verify the generated SQL statement is correct and efficient.

#### Step 2: Ensure Backward Compatibility (Expand and Contract Pattern)
If you are changing existing columns, avoid breaking active production clients by using the **Expand-and-Contract** pattern:
1. **Expand**: Add the new columns as optional (`?`) in the schema. Deploy this change so the database has both old and new columns.
2. **Migrate**: Run a background data migration script (or script inside the seed/deploy task) to copy/transform data from old columns to new columns.
3. **Contract**: Update the application code to read from the new columns. Once verified, deploy another migration to drop the old columns.

#### Step 3: Deployment Pipeline
1. Commit the `prisma/schema.prisma` and the `prisma/migrations/` folder to Git.
2. Push your changes. The CI/CD pipeline will:
   * Build the updated Docker images.
   * On startup, the container will run `npx prisma migrate deploy`, updating the production tables safely.
   * Start the new version of your application.

