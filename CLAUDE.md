# CLAUDE.md -- Pockii

Pockii is a Flutter budget management app for FCFA (Central/West African Franc) users. French-first UI, encrypted local database, no backend.

## Build and Run

```bash
# Install dependencies
flutter pub get

# Generate Drift and Riverpod code (required after model/table changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run all tests
flutter test

# Run a specific test file
flutter test test/unit/core/database/daos/transactions_dao_test.dart

# Analyze code
flutter analyze
```

Generated files (`*.g.dart`) are gitignored. Always run `build_runner` after modifying Drift tables, DAOs, or Riverpod annotated providers.

## Architecture

Feature-first structure under `lib/features/`. Each feature has up to three layers:

```
lib/features/<feature>/
  domain/       # Models, enums, service interfaces
  data/         # Repository implementations, DAOs
  presentation/ # Screens, widgets, providers, dialogs
```

Shared infrastructure lives in `lib/core/`:
- `database/` -- Drift database, tables (`tables/`), DAOs (`daos/`)
- `router/` -- GoRouter configuration
- `theme/` -- AppTheme, AppTypography, AppSpacing, BudgetColors
- `services/` -- Background tasks, notifications, pattern analysis
- `constants/` -- App-wide constants
- `exceptions/` -- Custom exception types

Current features: budget, budget_rules, finances, history, home, onboarding, patterns, planned_expenses, savings_projects, settings, shell, splash, streaks, subscriptions, tips, transactions, tutorials.

## Code Style

Strict analysis is enforced via `analysis_options.yaml` (extends `flutter_lints/flutter.yaml`):
- `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`
- `prefer_single_quotes` -- use single quotes for strings
- `prefer_const_constructors` -- use const where possible
- `require_trailing_commas` -- always add trailing commas in argument lists
- `prefer_final_locals` and `prefer_final_in_for_each`
- `avoid_print` -- use proper logging, not print()
- `sort_constructors_first` in class declarations
- `sort_child_properties_last` in widget trees
- Line length is not enforced (80-char rule is disabled)
- Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis

Naming: standard Dart conventions -- `camelCase` for variables/functions, `PascalCase` for types, `snake_case` for file names.

## Database -- Drift + SQLCipher

- Encrypted with SQLCipher (AES-256). Encryption key stored via `flutter_secure_storage`.
- All monetary values are stored as integers (FCFA has no decimal subdivision).
- Current schema version: 6. Migrations are incremental in `app_database.dart` `MigrationStrategy.onUpgrade`.
- Tables: BudgetPeriods, AppSettings, Transactions, Subscriptions, PlannedExpenses, UserStreaks, SavingsProjects, ProjectContributions.
- Each table has a corresponding DAO in `lib/core/database/daos/`.
- For tests, use `AppDatabase.inMemory()` (no encryption).

When adding a new table:
1. Create the table class in `lib/core/database/tables/`
2. Add it to the `@DriftDatabase(tables: [...])` annotation in `app_database.dart`
3. Create a DAO in `lib/core/database/daos/`
4. Increment `schemaVersion` and add migration logic in `onUpgrade`
5. Run `dart run build_runner build --delete-conflicting-outputs`

## State Management -- Riverpod

- Uses `flutter_riverpod: 2.6.1` with `riverpod_annotation: 2.6.1` for code generation.
- Providers live in `presentation/providers/` within each feature.
- Database provider is in `lib/core/database/database_provider.dart`.
- The root widget wraps everything in `ProviderScope`.
- Database initialization is async; the app shows a loading screen while it completes.

## Testing

- Unit tests: `test/unit/` -- mirrors `lib/` structure
- Shared mocks: `test/mocks/` (e.g., `mock_secure_storage.dart`)
- Uses `mocktail` for mocking (not mockito)
- Database tests use `AppDatabase.inMemory()`
- Test matcher: prefer `use_test_throws_matchers` (lint rule enforced)

## Localization and Currency

- Primary locale: `fr_FR`. Date formatting initialized via `initializeDateFormatting('fr_FR', null)`.
- Supported locales: `fr_FR` (primary), `en_US` (secondary).
- FCFA currency: integer amounts, no decimals. Format as `XXX XXX FCFA` (space-separated thousands).
- All user-facing strings are in French by default. UI text examples: "Chargement...", "Erreur d'initialisation".
- Font: Inter (400, 500, 600, 700 weights).
