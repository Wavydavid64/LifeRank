# LifeRank

Personal, local-first iOS RPG-style skill and hobby progression app. Real-world
activities generate XP; the user climbs F → E → D → C → B → A → S.

**`DESIGN.md` is the specification.** Read it before making architectural
decisions. It is the single source of truth for ranks, attributes, skills,
skill-to-attribute weights, XP rules, rank requirements, screens, and staged
scope. Do not restate its values here — two copies drift and produce bugs.

## Always-on rules

- Implement only the feature currently requested. Do not build future stages.
- Progression logic is pure Swift: no SwiftUI, SwiftData, or HealthKit imports
  in the domain layer. HealthKit types never leak into domain models.
- No XP or rank calculation inside SwiftUI views.
- Game-balance constants stay centralized, never inline in views.
- No third-party dependencies without asking. No React Native, Firebase,
  Supabase, backend, auth, or direct Garmin/Hevy/Strava integrations.
- Prefer simple native Apple APIs. Do not overengineer.
- Add or update tests when changing progression logic.
- Imported workouts must never award XP twice.
- Leave the project buildable; run the tests after meaningful changes.
- If a requirement is ambiguous and materially affects architecture or stored
  data, ask before choosing.

## Testing

```
xcodebuild test -project LifeRank.xcodeproj -scheme LifeRank \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

`LifeRankTests` is a logic-only bundle (no `TEST_HOST`) — it runs the pure
domain layer without launching the app.

## Current state

Stage 1 (domain foundation) per `DESIGN.md` §41. Built: `Rank`, `Attribute`,
`Skill`, `Activity`, `XPEvent`, `ProgressionEngine`, `SeedData`, tests.
No UI yet — `ContentView` is still the Xcode template.
