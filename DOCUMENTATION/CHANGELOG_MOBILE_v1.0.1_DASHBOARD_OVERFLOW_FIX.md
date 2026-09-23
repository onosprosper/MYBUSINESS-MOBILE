# MYBUSINESS Mobile v1.0.1 — Dashboard Overflow Fix

## Change
- Fixed Android dashboard stat-card overflow on small phones or large display font settings.
- Increased dashboard card height ratio.
- Reduced stat-card padding and font sizes slightly.
- Added safe text scaling with `FittedBox` and ellipsis for labels.

## Files changed
- `lib/screens/home_screen.dart`

## Test
Run:

```bash
flutter pub get
flutter run
```

Expected result: the Products, Customers, Orders, and Unread cards display without red/yellow overflow warnings.
