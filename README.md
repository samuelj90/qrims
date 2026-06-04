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
└── start-debug.sh      # Developer local debug orchestration script
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

### Option B: Production Container Deployment
To boot the production build using Docker Compose:
```bash
docker compose up --build -d
```

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
