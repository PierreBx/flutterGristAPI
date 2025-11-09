# Flutter Grist Widgets

A Flutter library for building complete data-driven applications from Grist using YAML configuration.

## 🗂️ Project Structure

This project is organized into three modules:

```
flutterGristAPI/
├── grist-module/           # Grist server and Docker infrastructure
├── flutter-module/         # Flutter library source code
└── documentation-module/   # Complete documentation
```

### 📦 Modules

| Module | Description | Quick Start |
|--------|-------------|-------------|
| **[grist-module/](grist-module/)** | Grist server, Docker setup, data storage | [grist-module/README.md](grist-module/README.md) |
| **[flutter-module/](flutter-module/)** | Flutter library source code, tests | [flutter-module/README.md](flutter-module/README.md) |
| **[documentation-module/](documentation-module/)** | All documentation and guides | [documentation-module/README.md](documentation-module/README.md) |

## 🚀 Quick Start

### First Time Setup

1. **Read the setup guide:**
   ```bash
   cd documentation-module
   cat QUICKSTART.md
   ```

2. **Start Grist server:**
   ```bash
   cd grist-module
   cp .env.example .env
   # Edit .env and set GRIST_SESSION_SECRET
   ./docker-test.sh grist-start
   ```

3. **Access Grist:** http://localhost:8484

4. **Build and test Flutter:**
   ```bash
   ./docker-test.sh build
   ./docker-test.sh all
   ```

### Daily Development

```bash
# Start Grist
cd grist-module
./docker-test.sh grist-start

# Make code changes in flutter-module/

# Run tests
./docker-test.sh all

# Stop when done
./docker-test.sh stop-all
```

## 📚 Documentation

All documentation is in the **[documentation-module/](documentation-module/)** directory:

### Essential Guides

- **[QUICKSTART.md](documentation-module/QUICKSTART.md)** - First-time setup (15-20 minutes)
- **[DAILY_USAGE.md](documentation-module/DAILY_USAGE.md)** - Daily workflow and commands
- **[README_DOCKER.md](documentation-module/README_DOCKER.md)** - Detailed Docker reference

### Reference Documentation

- **[YAML_SCHEMA.md](documentation-module/YAML_SCHEMA.md)** - Complete YAML configuration reference
- **[IMPLEMENTATION_STATUS.md](documentation-module/IMPLEMENTATION_STATUS.md)** - Feature status
- **[documentation.typ](documentation-module/documentation.typ)** - Comprehensive docs (Typst format)

## ✨ Features

- 📄 **YAML-Driven** - Define entire apps declaratively
- 🔐 **Built-in Authentication** - Bcrypt password hashing, role-based access
- 🗄️ **Auto-Schema Detection** - Discovers table structures from Grist
- 📊 **Multiple View Types** - Tables, forms, detail pages, admin dashboard
- 🔍 **Search & Filter** - Built-in data table search
- ✅ **Validation** - Rich field validators (required, email, regex, ranges)
- 📎 **File Upload** - Drag & drop file upload widget with image preview
- 📄 **Pagination** - Client-side pagination for large datasets
- 🔀 **Sorting** - Type-aware column sorting

## 🏗️ What's in Each Module?

### grist-module/

**Contains:** Docker infrastructure for running Grist server

- docker-compose.yml - Service definitions
- docker-test.sh - Helper script
- grist-data/ - Persistent data storage
- Dockerfile - Flutter test environment
- .env.example - Configuration template

**Purpose:** Provides a self-hosted Grist server with persistent data storage, plus Docker containers for running Flutter tests.

### flutter-module/

**Contains:** Flutter library source code

- lib/ - Library source code
  - src/config/ - Configuration parsers
  - src/services/ - Grist API client
  - src/widgets/ - Reusable widgets
  - src/pages/ - Page types
  - src/providers/ - State management
  - src/utils/ - Validators, helpers
- test/ - Unit tests (77 tests)
- example/ - Example configurations
- pubspec.yaml - Dependencies

**Purpose:** The actual Flutter library that developers import to build Grist-powered apps.

### documentation-module/

**Contains:** All project documentation

- QUICKSTART.md - Getting started guide
- DAILY_USAGE.md - Daily workflow
- README_DOCKER.md - Docker details
- YAML_SCHEMA.md - Configuration reference
- IMPLEMENTATION_STATUS.md - Feature tracking
- documentation.typ - Comprehensive docs

**Purpose:** Complete documentation for users, developers, and contributors.

## 🔧 Common Tasks

| Task | Command | Location |
|------|---------|----------|
| Start Grist | `./docker-test.sh grist-start` | grist-module/ |
| Run tests | `./docker-test.sh all` | grist-module/ |
| View logs | `./docker-test.sh grist-logs` | grist-module/ |
| Edit code | Use your IDE | flutter-module/ |
| Read docs | Open markdown files | documentation-module/ |

## 📊 Version

Current version: **v0.3.0**

### Recent Updates

- **v0.3.0** - File uploads, pagination, sorting
- **v0.2.0** - CRUD operations, enhanced features
- **v0.1.1** - Security fixes, validation, tests
- **v0.1.0** - Initial release

## 🐛 Troubleshooting

**Grist won't start:**
```bash
cd grist-module
./docker-test.sh grist-logs
```

**Tests fail:**
```bash
cd grist-module
./docker-test.sh build
./docker-test.sh all
```

**Need detailed help:**
- See [documentation-module/README_DOCKER.md](documentation-module/README_DOCKER.md)
- See [documentation-module/QUICKSTART.md](documentation-module/QUICKSTART.md)

## 📖 Learning Path

1. **New to the project?**
   - Start with [documentation-module/QUICKSTART.md](documentation-module/QUICKSTART.md)
   - Follow the step-by-step setup

2. **Ready to develop?**
   - Read [documentation-module/DAILY_USAGE.md](documentation-module/DAILY_USAGE.md)
   - Reference the cheat sheet

3. **Building an app?**
   - See examples in [flutter-module/example/](flutter-module/example/)
   - Reference [documentation-module/YAML_SCHEMA.md](documentation-module/YAML_SCHEMA.md)

4. **Contributing code?**
   - Review [flutter-module/README.md](flutter-module/README.md)
   - Run tests before committing
   - Follow conventional commit messages

## 🤝 Contributing

1. Fork the repository
2. Make changes in the appropriate module
3. Run tests: `cd grist-module && ./docker-test.sh all`
4. Update documentation if needed
5. Submit a pull request

## 📝 License

See [flutter-module/LICENSE](flutter-module/LICENSE) for details.

## 🔗 Links

- **Grist API Docs:** https://support.getgrist.com/api/
- **Flutter Docs:** https://flutter.dev/docs
- **Docker Docs:** https://docs.docker.com/

## 💡 Example

```yaml
# example/config.yaml
app:
  name: "My Business App"

grist:
  base_url: "http://localhost:8484"
  document_id: "YOUR_DOC_ID"
  api_key: "YOUR_API_KEY"

pages:
  - id: "home"
    type: "data_master"
    title: "Products"
    config:
      grist:
        table: "Products"
```

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_grist_widgets/flutter_grist_widgets.dart';

void main() async {
  final config = await AppConfig.loadFromYaml('assets/config.yaml');
  runApp(GristApp(config: config));
}
```

---

**Get started now:** [documentation-module/QUICKSTART.md](documentation-module/QUICKSTART.md) 🚀
