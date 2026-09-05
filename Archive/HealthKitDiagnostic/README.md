# HealthKit Diagnostic (archived)

Read-only screen that dumps the 20 most recent HealthKit workouts: activity
type name and **raw enum value**, source name, start, duration, distance (and
which quantity type carried it), active energy, average heart rate, UUID, and
whether `WorkoutMapping` currently claims the type.

Built to answer `DESIGN.md` §20 — what Garmin, Hevy and friends actually put
into Apple Health. It is **not part of the app target**: files under
`LifeRank/` are compiled automatically by the project's synchronized group, so
the only way to keep this out of the binary is to keep it out of that folder.

## What it already answered

- Garmin running → `.running`, distance under `distanceWalkingRunning`.
- Hevy → `.traditionalStrengthTraining`, duration only, no distance.
- Both provide active energy.

## Still unanswered

Whether `.cycling`, `.paddleSports`, `.yoga` and `.flexibility` are what those
sources actually report. Restore this if a workout imports as the wrong skill,
or lands in `unclassified`.

## Restoring

1. Move `WorkoutDiagnostic.swift` into `LifeRank/Integrations/HealthKit/`.
2. Move `HealthKitDiagnosticView.swift` into `LifeRank/Features/Diagnostics/`.
3. Add a link to it — previously a `NavigationLink` in `LogActivityView`'s
   "Apple Health" section.

No other edits needed. `HealthKitDiagnosticService` owns its own `HKHealthStore`
and authorization request rather than reaching into `HealthKitService`,
precisely so restoring is a file move.

## Caveat

Archived code is not compiled and will not be caught by a build or by the test
suite. If `Skill.ID`, `WorkoutMapping` or `HealthKitError` change shape, this
will need fixing when restored.
