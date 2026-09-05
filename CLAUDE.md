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
xcodebuild clean test -project LifeRank.xcodeproj -scheme LifeRank \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Use `clean` before claiming a warning count. Incremental builds do not re-emit
warnings for unchanged files, so a warning-free incremental run proves nothing —
a batch of actor-isolation warnings hid behind exactly that for several stages.

137 tests. `LifeRankTests` covers the domain layer plus persistence through
in-memory `ModelContainer`s, so nothing needs the app running.

## Current state

All ten `DESIGN.md` §41 stages are implemented. Tabs: Character, Skills, Log,
Quests, History (§28) — Trials is reached from Character's Next Promotion row.

```
LifeRank/
  Domain/       Models, Progression, Ranks, Skills, Quests, Trials — pure Swift
  Data/         Persistence (SwiftData), Seed (balance config), Backup (JSON)
  Integrations/ HealthKit behind ActivityProvider
  Features/     One folder per screen
  Components/   RadarChart, XPBar, RankBadge
```

12 skills, 11 quests, 72 skill challenges, 6 promotion trials — all in
`Data/Seed/`.

### Actor isolation

The target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which would make
domain value types main-actor-isolated *including their protocol conformances*.
SwiftData and Swift Testing then touch those conformances from nonisolated
contexts — warnings today, errors under the Swift 6 language mode.

Everything in `Domain/`, `Data/Seed/` and the import boundary is therefore
declared `nonisolated`. Keep new domain types that way; it is also what §32
asks for, since progression must run anywhere, not only on the main actor.
`ActivityStore`, `CharacterStore`, `BackupService` and `ActivityImporter` stay
`@MainActor` — they drive a `ModelContext`.

### Things worth knowing before changing balance

- Levels, skill ranks and quest progress are **derived** from the XP ledger.
  Only overall rank, manual objective completions, and ignored-workout
  tombstones are stored. Rebalancing is retroactive and needs no migration.
- Several balance values are coupled, and tests enforce the couplings rather
  than leaving them to be discovered later:
  - `skillRequirementsFitInsideTheirRankXPBudget` — N skills at a rank must be
    affordable within that rank's overall XP.
  - `attributeRequirementsFitTheirRankXPBudget` — same for the attribute
    clause. This is why `RankRequirements` departs from §15's attribute
    minimums, which are unreachable against the level curve.
  - `ceilingLeavesHeadroomAtEachRankThreshold` — radar ceilings vs. real levels.
  - `everyAttributeIsReachableFromSomeSkill` — every attribute needs a skill
    that genuinely feeds it. Knowledge once had none and Mobility only 5% of
    one skill, which made S rank (all 8 attributes at level 20) impossible no
    matter how much was logged.
  Change `AttributeProgression.baseLevelCost` or any threshold and these fail
  loudly instead of shipping an unreachable rank.
- Quest bonus XP is keyed to the activity that crossed the target, so deleting
  or editing that activity moves the bonus with it.
- `ActivityStore.recalculateXP()` rebuilds the ledger by chronological replay,
  and `update(_:)` calls it. Replay rather than a local patch, because an edit
  can change *which* activity crossed a quest target.
- Deleting an imported activity writes an `IgnoredWorkoutRecord` tombstone.
  Without it the next Health sync would simply re-add the workout.
- Schema is pinned by `LifeRankSchemaV1` with a `SchemaMigrationPlan`. Adding a
  model or optional property: extend V1. Anything structural (rename, type
  change, optional → non-optional): add V2 and a `MigrationStage`, or the store
  fails to open and takes real progression with it.

### §20 findings (verified on device)

- Garmin running arrives as `.running` with distance under
  `distanceWalkingRunning`. Running XP works fully.
- Hevy arrives as `.traditionalStrengthTraining` with duration and **no
  distance**, so strength XP is duration-only — an hour of hard lifting and an
  hour of resting between sets currently score the same.
- Both sources provide active energy. Heart rate is read alongside it.
- `activeCalories` and `averageHeartRate` are captured and stored but **not
  used** by the XP formula (§11: tune against real usage). They are recorded
  now so a future intensity term applies to history rather than only to
  sessions logged after it ships.
- Still unverified: the `.cycling`, `.paddleSports`, `.yoga` and `.flexibility`
  mappings. The diagnostic screen answers these — see below.

### Outstanding

- **The view layer is untested.** Tests cover the domain and persistence
  through in-memory containers, but no test exercises a SwiftUI view. A radar
  bug survived several stages because of this: the chart drew from state seeded
  in `onAppear`, rendered empty against real data, and was twice mistaken for
  an empty-state. Screens whose interactive paths have never been run at all:
  the XP award overlay, activity editing, promotion, and backup export/restore.
- Balance numbers are estimates, not measurements — including the per-skill
  `effortMultiplier` values, which encode assumptions about session length and
  frequency. Everything derives from the ledger, so retuning is retroactive.
- `Features/Diagnostics/` and `WorkoutDiagnostic` are marked TEMPORARY. Delete
  them, and collapse `diagnosticReadTypes` back into `readTypes`, once the
  remaining workout-type mappings are confirmed.
