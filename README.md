# Aether Player

A cross-platform Emby media player client built with Flutter and Go.

## Architecture

```
┌────────────────┐     localhost:19800     ┌─────────────┐
│  Flutter App   │ ─── HTTP/REST ───────→ │  Go Backend  │ ───→ Emby Server
│  (app/)        │                         │  (server/)   │
└────────────────┘                         └─────────────┘
```

- **Flutter App** (`app/`) — Cross-platform client (mobile / desktop / web), communicates with the Go backend via REST.
- **Go Backend** (`server/`) — Local proxy that handles authentication, library browsing, and playback requests, forwarding them to the upstream Emby server.

## Tech Stack

| Layer    | Stack                                            |
| -------- | ------------------------------------------------ |
| Frontend | Flutter 3.32+ / Dart, Riverpod, media_kit, Dio  |
| Backend  | Go 1.24, net/http                                |
| CI       | GitHub Actions                                   |

## Getting Started

### Prerequisites

- Flutter 3.32+ (stable channel)
- Go 1.24+
- An accessible Emby server

### Backend (Go)

```bash
cd server

# Run locally
go run ./cmd/api/

# Build binary
go build -o aether-server ./cmd/api/

# Run tests
go test ./...
```

**Environment variables:**

| Variable           | Default                   | Description                |
| ------------------ | ------------------------- | -------------------------- |
| `PORT`             | `19800`                   | HTTP listen port           |
| `CORS_ALLOW_ORIGIN`| *(empty — allows all)*    | Allowed CORS origins       |

### Frontend (Flutter)

```bash
cd app

# Install dependencies
flutter pub get

# Generate i18n files
dart run slang

# Run in development
flutter run

# Build for web
flutter build web --release

# Run tests
flutter test
```

## CI

Every push / PR to `main` or `dev` triggers the GitHub Actions workflow (`.github/workflows/ci.yml`) which runs:

1. **Go Backend** — `go mod download` → `go vet` → `go test` → `go build`
2. **Flutter App** — `flutter pub get` → `slang` (i18n) → `flutter analyze` → `flutter test` → `flutter build web`

## Project Structure

```
Aether-Player/
├── app/                        # Flutter frontend
│   ├── lib/
│   │   ├── models/             # Data models
│   │   ├── screens/            # UI pages (home, player, settings …)
│   │   ├── services/           # API client, settings service
│   │   ├── theme/              # Color & style definitions
│   │   └── widgets/            # Reusable UI components
│   └── test/                   # Flutter unit & widget tests
├── server/                     # Go backend
│   ├── cmd/api/                # Entry point (main.go)
│   └── internal/
│       ├── emby/               # Emby server client
│       ├── handler/            # HTTP handlers (auth, library, playback, proxy)
│       └── middleware/          # CORS, logging middleware
├── docs/                       # Design specs & reference docs
└── .github/workflows/ci.yml   # GitHub Actions CI pipeline
```

## License

This project is licensed under the [MIT License](LICENSE).
