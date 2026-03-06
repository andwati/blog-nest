# Blog Nest

A modern full-stack blog platform built with TypeScript, featuring a NestJS backend API, Next.js web frontend, and Expo mobile app.

## Tech Stack

### Backend (API)
- **NestJS** 11.0.1 - Progressive Node.js framework
- **Prisma ORM** 7.4.2 - Type-safe database access
- **PostgreSQL** 17 - Primary database
- **Redis** 7 - Caching layer
- **TypeScript** 5.7.3 - Static typing
- **Jest** 30.0.0 - Testing framework

### Frontend (Web)
- **Next.js** 16.1.6 - React framework with App Router
- **React** 19.2.3 - UI library
- **Tailwind CSS** 4 - Utility-first CSS
- **TypeScript** 5 - Static typing
- **Jest** 30.2.0 - Testing framework

### Mobile (App)
- **Expo** 55.0.5 - React Native framework
- **Expo Router** - File-based routing
- **React Native** 0.83.2 - Mobile framework
- **React** 19.2.0 - UI library
- **TypeScript** - Static typing

### Tooling
- **Turbo** 2.8.13 - Monorepo orchestration
- **pnpm** 10.30.3 - Package manager
- **Biome** 2.4.6 - Linting & formatting
- **Lefthook** 2.1.2 - Git hooks
- **Docker** - Containerization
- **Nginx** - Reverse proxy (production)

## Prerequisites

- **Node.js** v24.14.0 (use `.nvmrc` for version management)
- **pnpm** 10.30.3 or higher
- **Docker** & Docker Compose
- **Git**

## Quick Start

### 1. Clone the repository
```bash
git clone <repository-url>
cd blog-nest
```

### 2. Install dependencies
```bash
pnpm install
```

### 3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 4. Start development database
```bash
pnpm docker:dev
```

### 5. Run database migrations
```bash
pnpm --filter api run prisma:migrate:dev
```

### 6. Start development servers
```bash
pnpm dev
```

This starts all apps in parallel:
- **API**: http://localhost:3001
- **Frontend**: http://localhost:3000
- **Mobile**: Expo DevTools (follow terminal instructions)

## Project Structure

```
blog-nest/
├── apps/
│   ├── api/              # NestJS backend API
│   │   ├── prisma/       # Prisma schema & migrations
│   │   ├── src/          # Source code
│   │   └── test/         # E2E tests
│   ├── frontend/         # Next.js web application
│   │   └── src/          # Source code
│   └── mobile/           # Expo mobile application
│       ├── assets/       # Static assets
│       └── src/          # Source code
├── infra/                # Infrastructure configuration
│   ├── docker-compose.yml
│   └── nginx.conf
├── .github/              # GitHub configuration
├── package.json          # Root package.json
├── pnpm-workspace.yaml   # pnpm workspace config
├── turbo.json            # Turbo configuration
├── biome.json            # Biome linting config
└── lefthook.yml          # Git hooks configuration
```

## Development

### Available Commands

#### Root Level (affects all apps)
```bash
pnpm dev              # Start all apps in development mode
pnpm build            # Build all apps
pnpm test             # Run tests in all apps
pnpm lint             # Lint all apps
pnpm clean            # Clean build artifacts
pnpm check-types      # Type-check all apps
```

#### Workspace-Specific Commands

**Backend (API)**
```bash
pnpm --filter api dev                        # Start dev server
pnpm --filter api build                      # Build for production
pnpm --filter api test                       # Run unit tests
pnpm --filter api run test:cov               # Run tests with coverage
pnpm --filter api run test:e2e               # Run E2E tests
pnpm --filter api run prisma:generate        # Generate Prisma Client
pnpm --filter api run prisma:migrate:dev     # Run migrations (dev)
pnpm --filter api run prisma:migrate:deploy  # Run migrations (prod)
pnpm --filter api run prisma:studio          # Open Prisma Studio
```

**Frontend (Web)**
```bash
pnpm --filter frontend dev         # Start dev server
pnpm --filter frontend build       # Build for production
pnpm --filter frontend start       # Start production server
pnpm --filter frontend test        # Run tests
pnpm --filter frontend lint        # Lint code
```

**Mobile (App)**
```bash
pnpm --filter mobile dev       # Start Expo DevTools
pnpm --filter mobile android   # Run on Android
pnpm --filter mobile ios       # Run on iOS
pnpm --filter mobile web       # Run on web
pnpm --filter mobile test      # Run tests
```

### Docker Commands

```bash
# Development
pnpm docker:dev         # Start PostgreSQL & Redis
pnpm docker:down        # Stop all containers

# Production
pnpm docker:prod        # Start all services (production)
pnpm docker:prod:down   # Stop production containers
```

## Database Management

### Prisma Workflow

1. **Update schema**: Edit `apps/api/prisma/schema.prisma`
2. **Create migration**: 
   ```bash
   pnpm --filter api run prisma:migrate:dev --name <migration_name>
   ```
3. **Apply to production**:
   ```bash
   pnpm --filter api run prisma:migrate:deploy
   ```
4. **Explore data**:
   ```bash
   pnpm --filter api run prisma:studio
   ```

### Configuration

Prisma v7 uses `apps/api/prisma.config.ts` for configuration:
- Connection URL loaded from root `.env` file
- Schema location: `apps/api/prisma/schema.prisma`
- Migrations stored in: `apps/api/prisma/migrations/`

## Testing

### Running Tests

```bash
# All apps
pnpm test

# Specific app
pnpm --filter api test
pnpm --filter frontend test
pnpm --filter mobile test

# With coverage
pnpm --filter api run test:cov

# Watch mode
pnpm --filter api run test:watch
```

### Test Structure

- **Unit tests**: `*.spec.ts` or `*.spec.tsx`
- **E2E tests**: `test/*.e2e-spec.ts` (backend only)
- **Coverage target**: ≥90% for backend code

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Database
DATABASE_URL=postgresql://blog:postgres@localhost:5432/blog_dev
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=blog_dev
DATABASE_USER=blog
DATABASE_PASSWORD=postgres

# API
API_PORT=3001

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:3001

# Mobile
EXPO_PUBLIC_API_URL=http://localhost:3001
```

## Deployment

### Production Deployment

See [DEPLOY_VPS.md](DEPLOY_VPS.md) for complete VPS deployment guide including:
- Docker Compose setup
- Nginx reverse proxy configuration
- SSL/TLS with Let's Encrypt
- Database backup strategies
- Monitoring setup

### Quick Production Build

```bash
# Build all apps
pnpm build

# Start production services
pnpm docker:prod
```

## Code Quality

### Linting & Formatting

This project uses **Biome** for linting and formatting:

```bash
# Lint all code
pnpm lint

# Auto-fix issues
pnpm lint --write

# Check specific app
pnpm --filter api lint
```

### Git Hooks

**Lefthook** runs pre-commit checks:
- Linting staged files
- Type checking
- Running relevant tests

Hooks are automatically installed when you run `pnpm install`.

## Architecture Decisions

### Monorepo Strategy
- **Tool**: Turbo + pnpm workspaces
- **Benefits**: Shared TypeScript configs, parallel task execution, efficient caching
- **Workspace isolation**: Each app has its own dependencies and configuration

### Prisma v7
- Configuration moved from schema to `prisma.config.ts`
- Environment variables loaded from root `.env`
- Improved TypeScript integration and migration workflows

### Next.js App Router
- Server Components by default
- Client Components only when needed
- Optimized for performance and SEO

### Expo Router
- File-based routing for mobile app
- Seamless navigation between screens
- Web compatibility built-in

## Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Make your changes
3. Run quality checks: `pnpm lint && pnpm test`
4. Commit following [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat(api): add user authentication
   fix(frontend): resolve navigation bug
   ```
5. Push and create a Pull Request

### Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `refactor`, `test`, `chore`, `perf`, `docs`

## Additional Documentation

- [API Documentation](apps/api/README.md)
- [Frontend Documentation](apps/frontend/README.md)
- [Mobile Documentation](apps/mobile/README.md)
- [Infrastructure Guide](infra/README.md)
- [Deployment Guide](DEPLOY_VPS.md)
- [Copilot Instructions](.github/.copilot-instructions.md)

## Troubleshooting

### Common Issues

**Port already in use**
```bash
# Kill processes on specific ports
pkill -f "next dev"
pkill -f "nest start"
```

**Stale dependencies**
```bash
pnpm clean
rm -rf node_modules
pnpm install
```

**Database connection issues**
```bash
# Restart database container
pnpm docker:down
pnpm docker:dev
```

**Prisma Client out of sync**
```bash
pnpm --filter api run prisma:generate
```

## License

[License Type] - See LICENSE file for details

## Team

- [Your Name/Team]
- [Contact Information]

---

Built with TypeScript
