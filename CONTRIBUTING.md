# Contributing to autonavi-maps-flutter

Thank you for your interest in contributing!

## Development Setup

1. Fork and clone the repository
2. Run `dart pub get` to install Melos (declared in the root `pubspec.yaml`)
3. Run `dart run melos bootstrap` to link packages and install dependencies

## Project Structure

```
autonavi-maps-flutter/
├── packages/
│   ├── autonavi_maps_flutter/     # Map rendering package
│   ├── autonavi_location_flutter/ # Location services package
│   └── autonavi_search_flutter/   # Search services package
├── example/                       # Example app demonstrating all packages
└── melos.yaml                     # Monorepo configuration
```

## Making Changes

1. Create a feature branch from `main`
2. Make your changes
3. Run `dart run melos run analyze` to check for issues
4. Run `dart run melos run test` to run tests
5. Run `dart run melos run format` to format code
6. Submit a pull request

## Commit Messages

Use clear, descriptive commit messages:
- `feat(maps): add polyline dash pattern support`
- `fix(location): handle null address fields`
- `docs: update README with iOS setup steps`

## Reporting Issues

Please use [GitHub Issues](https://github.com/walkunvs/autonavi-maps-flutter/issues) to report bugs or request features. Include:
- Platform (Android/iOS) and version
- Flutter/Dart SDK version
- Minimal reproduction case
- Expected vs actual behavior

## Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for formatting (enforced by CI)
- Add tests for new functionality
- Keep native code consistent with existing patterns

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
