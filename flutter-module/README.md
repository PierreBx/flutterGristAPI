# Flutter Grist Widgets

A Flutter library for building complete data-driven applications from Grist using YAML configuration.

## Overview

This module contains the Flutter library source code for `flutter_grist_widgets` - a declarative app generator that creates full-featured Flutter applications from simple YAML configuration files.

## Contents

- **lib/** - Library source code
  - **src/config/** - Configuration models and parsers
  - **src/models/** - Data models (User, etc.)
  - **src/pages/** - Page widgets (DataMaster, DataDetail, etc.)
  - **src/providers/** - State management (AuthProvider)
  - **src/services/** - Grist API service
  - **src/utils/** - Validators, expression evaluators
  - **src/widgets/** - Reusable widgets (GristTable, FileUpload, etc.)
- **test/** - Unit tests (77 tests)
- **example/** - Example app configurations
- **pubspec.yaml** - Package dependencies
- **analysis_options.yaml** - Linter configuration

## Features

- 📄 **YAML-Driven** - Define entire apps declaratively
- 🔐 **Built-in Authentication** - Bcrypt password hashing, role-based access
- 🗄️ **Auto-Schema Detection** - Discovers table structures from Grist
- 📊 **Multiple View Types** - Tables, forms, detail pages, admin dashboard
- 🎨 **Themeable** - Customize colors via YAML
- 🔍 **Search & Filter** - Built-in data table search
- ✅ **Validation** - Rich field validators (required, email, regex, ranges)
- 📎 **File Upload** - Drag & drop file upload widget with image preview
- 📄 **Pagination** - Client-side pagination for large datasets
- 🔀 **Sorting** - Type-aware column sorting

## Version History

- **v0.3.0** - File uploads, pagination, enhanced tables
- **v0.2.0** - Full CRUD operations, enhanced features
- **v0.1.1** - Security fixes, validation system, 77 unit tests
- **v0.1.0** - Initial release

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_grist_widgets: ^0.3.0
```

## Quick Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_grist_widgets/flutter_grist_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load YAML configuration
  final config = await AppConfig.loadFromYaml('assets/config.yaml');

  runApp(GristApp(config: config));
}
```

## Development

### Running Tests

```bash
# From grist-module directory (using Docker)
cd ../grist-module
./docker-test.sh test

# Or run specific test
./docker-test.sh shell
flutter test test/utils/validators_test.dart
```

### Running Analysis

```bash
cd ../grist-module
./docker-test.sh analyze
```

### Adding Dependencies

```bash
# Edit pubspec.yaml, then:
cd ../grist-module
./docker-test.sh shell
flutter pub get
```

## Architecture

### Key Components

**Services**
- `GristService` - Main API client for Grist CRUD operations

**Providers**
- `AuthProvider` - Authentication state management with session timeout

**Widgets**
- `GristTableWidget` - Data table with sorting, pagination
- `FileUploadWidget` - Drag & drop file upload with preview
- `GristApp` - Main app widget with navigation

**Pages**
- `DataMasterPage` - Tabular data view with search
- `DataDetailPage` - Detail/edit form view
- `DataCreatePage` - Create new record form
- `LoginPage` - Authentication page
- `AdminDashboardPage` - System monitoring

**Utils**
- `FieldValidator` - Form validation system
- `ExpressionEvaluator` - Conditional visibility logic

## Testing

The module includes 77 unit tests:

- **Validators** (46 tests) - Field validation logic
- **Expression Evaluator** (24 tests) - Conditional expressions
- **Grist Service** (7 tests) - Password hashing and authentication

Run all tests:
```bash
cd ../grist-module
./docker-test.sh all
```

## Security

### Password Hashing

Uses bcrypt with salt for production-ready security:

```dart
import 'package:flutter_grist_widgets/flutter_grist_widgets.dart';

// Hash a password (for storing in Grist)
final hash = GristService.hashPassword('mypassword');

// Authentication automatically uses bcrypt.checkpw()
```

### Session Management

Built-in session timeout with configurable duration:

```yaml
auth:
  session:
    timeout_minutes: 30
    auto_logout_on_timeout: true
```

## Example Configuration

See `example/` directory for complete YAML configurations:

```yaml
app:
  name: "My Business App"
  version: "1.0.0"

grist:
  base_url: "http://localhost:8484"
  document_id: "YOUR_DOCUMENT_ID"
  api_key: "YOUR_API_KEY"
  users_table: "Users"

auth:
  enabled: true
  users_table: "Users"
  users_table_schema:
    email_field: "email"
    password_field: "password_hash"
    role_field: "role"
    active_field: "active"

pages:
  - id: "home"
    type: "data_master"
    title: "Home"
    config:
      grist:
        table: "Products"
        columns:
          - name: "name"
            label: "Product Name"
          - name: "price"
            label: "Price"
            type: "currency"
```

## Documentation

For complete documentation, see:
- **../documentation-module/README.md** - Library overview
- **../documentation-module/QUICKSTART.md** - Getting started
- **../documentation-module/DAILY_USAGE.md** - Development workflow
- **../documentation-module/YAML_SCHEMA.md** - YAML configuration reference

## License

See LICENSE file for details.
