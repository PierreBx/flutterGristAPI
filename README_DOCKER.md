# Flutter Grist Widgets - Docker Setup

This document explains how to test and develop the Flutter Grist Widgets library using Docker.

## Prerequisites

- Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- Docker Compose installed (usually comes with Docker Desktop)

## Quick Start

### 1. Build the Docker Image

```bash
docker-compose build
```

Or use the helper script:

```bash
./docker-test.sh build
```

### 2. Run Tests

**Run all tests:**
```bash
./docker-test.sh all
```

**Run only unit tests:**
```bash
./docker-test.sh test
```

**Run only code analysis:**
```bash
./docker-test.sh analyze
```

## Available Commands

### Using the Helper Script

```bash
./docker-test.sh <command>
```

**Commands:**
- `test` - Run unit tests
- `analyze` - Run Flutter analyzer (check for errors)
- `shell` - Open interactive bash shell in container
- `all` - Run both analyze and test
- `build` - Build the Docker image
- `clean` - Remove Docker containers and volumes

### Using Docker Compose Directly

**Run tests:**
```bash
docker-compose run --rm flutter-test
```

**Run analysis:**
```bash
docker-compose run --rm flutter-analyze
```

**Interactive shell:**
```bash
docker-compose run --rm flutter-shell /bin/bash
```

## Manual Testing Inside Container

Open an interactive shell:

```bash
./docker-test.sh shell
```

Then run commands manually:

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run specific test file
flutter test test/utils/validators_test.dart

# Run analysis
flutter analyze

# Check Flutter installation
flutter doctor

# Run tests with verbose output
flutter test --reporter expanded

# Format code
dart format .

# Check for outdated packages
flutter pub outdated
```

## Expected Output

### Successful Test Run

```
✓ All tests passed!
```

### Test Details

The test suite includes:
- **46 tests** for field validators
- **24 tests** for expression evaluator
- **7 tests** for password hashing
- **Total: 77 unit tests**

### Successful Analysis

```
Analyzing flutter_grist_widgets...
No issues found!
```

## Troubleshooting

### Docker Build Issues

**Problem:** Build fails or takes too long

**Solution:**
```bash
# Clean everything and rebuild
./docker-test.sh clean
docker-compose build --no-cache
```

### Permission Issues

**Problem:** Permission denied errors

**Solution:**
```bash
chmod +x docker-test.sh
sudo chown -R $USER:$USER .
```

### Dependency Issues

**Problem:** Package resolution errors

**Solution:**
```bash
# Open shell and update dependencies
./docker-test.sh shell

# Inside container:
flutter pub get
flutter pub upgrade
```

### Memory Issues

**Problem:** Container runs out of memory

**Solution:**
Increase Docker memory limit in Docker Desktop settings (recommend 4GB+)

## Testing Individual Features

### Test Validators

```bash
docker-compose run --rm flutter-shell flutter test test/utils/validators_test.dart
```

### Test Expression Evaluator

```bash
docker-compose run --rm flutter-shell flutter test test/utils/expression_evaluator_test.dart
```

### Test Password Hashing

```bash
docker-compose run --rm flutter-shell flutter test test/services/grist_service_test.dart
```

## Development Workflow

### 1. Make Code Changes

Edit files locally on your host machine.

### 2. Run Tests

```bash
./docker-test.sh all
```

### 3. Fix Issues

If tests fail, fix the code and re-run tests.

### 4. Commit Changes

```bash
git add .
git commit -m "Your message"
git push
```

## Volumes

The Docker setup uses volumes for:
- **Code:** Mounted from host to `/app` in container
- **Pub cache:** Persisted to avoid re-downloading packages

## Environment Variables

Available environment variables:
- `FLUTTER_ROOT=/opt/flutter` - Flutter SDK location
- `FLUTTER_VERSION=3.16.0` - Flutter version (configurable in Dockerfile)

## Cleaning Up

Remove all Docker resources:

```bash
./docker-test.sh clean
```

Or manually:

```bash
docker-compose down -v
docker system prune -f
```

## Next Steps

1. **Run the tests:** `./docker-test.sh all`
2. **Fix any errors** that appear
3. **Test new features** by adding more test files
4. **Create example app** to manually test widgets

## Known Limitations

- **No GUI:** Can't run `flutter run` (no graphical environment)
- **Tests only:** Suitable for unit/widget tests, not integration tests
- **Web/Mobile:** Can't test on actual devices or browsers

## Alternative: Testing with GUI

If you need to test the actual UI:

1. Install Flutter locally on your host machine
2. Run `flutter run -d chrome` for web testing
3. Or connect a device/emulator and run `flutter run`

## Support

If you encounter issues:
1. Check the error messages carefully
2. Ensure Docker is running
3. Try rebuilding: `docker-compose build --no-cache`
4. Check Docker logs: `docker-compose logs`

## Summary

**Quick test workflow:**
```bash
# First time
docker-compose build

# Every time you make changes
./docker-test.sh all
```

This will verify your code compiles and passes all tests! 🎉
