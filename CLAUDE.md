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
  Change `AttributeProgression.baseLevelCost` or any threshold and these fail
  loudly instead of shipping an unreachable rank.
- Quest bonus XP is keyed to the activity that crossed the target, so deleting
  that activity reverses the bonus too.
- `ActivityStore.recalculateXP()` rebuilds the ledger by chronological replay.
  Run it after changing the XP formula.

### Outstanding

- **§20 is unverified.** The HealthKit import path has never seen a real
  `HKWorkout` — it is tested only against synthetic `ImportedActivity` values.
  On a device, check whether Garmin runs carry `distanceWalkingRunning`, and
  whether Hevy reports `.traditionalStrengthTraining` or
  `.functionalStrengthTraining` (the latter maps to nothing today).
- Editing logged activities is not implemented; delete and re-log instead.
