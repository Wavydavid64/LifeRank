# LifeRank — Product and Technical Design Specification

## 1. Product Vision

LifeRank is a personal iOS application that turns real-world self-improvement
into an RPG-style progression system.

The user begins at F Rank and progresses through increasingly difficult ranks by
developing real skills and attributes.

The core loop is:

```
Train → Log/Import Activity → Earn XP → Improve Skills and Attributes
      → Meet Promotion Requirements → Complete Rank Trial → Rank Up
```

The application should feel like a character sheet for real life, not a
conventional habit tracker with RPG graphics added to it.

The fundamental design principle is:

**The app rewards becoming more capable, not using the app.**

Opening the app, checking in, maintaining login streaks, or pressing buttons
should never generate XP. Real-world activity generates progression.

## 2. Platform and Technology

LifeRank is initially a personal iPhone application.

Use:

- Swift
- SwiftUI
- SwiftData
- HealthKit
- UserNotifications where appropriate
- Native Apple frameworks wherever practical
- Swift Testing or XCTest for automated testing
- Git for version control

Do not introduce third-party dependencies without a compelling technical reason.

Do not introduce: React Native, Firebase, Supabase, backend servers, user
authentication, direct Garmin API integration, direct Hevy API integration,
Strava integration, Android, web frontend.

The application should be local-first.

Garmin and Hevy already synchronize workouts into Apple Health. LifeRank should
consume supported fitness data through HealthKit.

```
Garmin ──┐
         │
Hevy ────┴──► Apple Health
                    │
                    ▼
                 HealthKit
                    │
                    ▼
                 LifeRank
Manual Activities ─► LifeRank
```

## 3. Product Philosophy

### 3.1 Capability over engagement

XP should represent actual training and accomplishment. Do not award XP for:
opening LifeRank, logging into LifeRank, maintaining an arbitrary app-use
streak, viewing statistics, checking quests, or other engagement metrics.

### 3.2 Permanent accomplishments

Ranks and earned XP should not decay. If the user reaches C Rank, taking a
vacation should not demote them to D Rank.

### 3.3 Progression should become increasingly difficult

Early progression should happen relatively quickly. Advanced progression should
require significantly more investment and demonstrated competence.

### 3.4 Rank is earned, not automatically granted

Reaching an XP threshold makes the user *eligible* for promotion. It does not
automatically promote them. Rank advancement also requires appropriate
skill/attribute development and completion of a promotion trial.

## 4. Overall Rank System

Initial ranks: `F → E → D → C → B → A → S`

The architecture should allow ranks beyond S to be added later without major
refactoring. Possible future ranks might include S+, SS, and SSS, but these are
not part of the initial implementation.

The user starts at **F Rank**.

Overall rank represents broad personal development. It must not simply be the
user's overall XP level.

Promotion can depend on:

1. Total XP
2. Skill ranks
3. Attribute levels
4. Completion of a promotion trial

Rank requirements must be configuration-driven. Do not scatter rank thresholds
throughout UI code.

## 5. Attributes

LifeRank initially contains eight attributes:

Strength, Endurance, Dexterity, Mobility, Knowledge, Creativity, Discipline,
Exploration.

These represent broad dimensions of development. Attributes should have
accumulated XP, a calculated level, and progression toward the next level.

Attribute levels should become progressively more expensive. Do not use a
constant amount of XP for every level. For example, an early level might require
approximately 100 XP while substantially higher levels require much more. The
exact progression curve should be configurable and easy to tune.

## 6. Radar / Spider Chart

The Character screen should prominently display the eight attributes using a
radar/spider chart. The chart should immediately communicate the user's current
"build."

```
Strength       38
Endurance      64
Dexterity      57
Mobility       24
Knowledge      51
Creativity     68
Discipline     61
Exploration    43
```

This would visually reveal strong Creativity/Endurance and comparatively weak
Mobility.

Implement the radar chart natively using SwiftUI drawing APIs such as `Canvas`,
`Path`, or `Shape`. Do not add a third-party chart dependency solely for the
radar chart. The chart should support animation later, but correctness comes
before animation.

## 7. Skills

Attributes are broad characteristics. Skills represent specific real-world
abilities.

Initial skills: Running, Strength Training, Hiking, Chinese Calligraphy,
Western Calligraphy.

The system must make adding new skills easy. A Skill should have: identifier,
name, XP, calculated level if useful, skill rank, attribute contribution
weights, progression/challenge configuration.

Skills have their own ranks using the same broad rank vocabulary:
`F → E → D → C → B → A → S`

This allows a character profile such as:

```
OVERALL                 D
Running                 C
Hiking                  C
Strength Training       D
Chinese Calligraphy     F
Western Calligraphy     E
```

A user can therefore be advanced overall while remaining a beginner in a newly
started skill.

## 8. Skill-to-Attribute Relationships

Skills contribute XP to one or more attributes. These relationships must be
configurable rather than hardcoded into progression functions.

| Skill | Weights |
|---|---|
| Running | Endurance 70%, Discipline 20%, Exploration 10% |
| Strength Training | Strength 75%, Discipline 20%, Mobility 5% |
| Hiking | Endurance 50%, Exploration 35%, Discipline 15% |
| Chinese Calligraphy | Dexterity 55%, Creativity 30%, Discipline 15% |
| Western Calligraphy | Dexterity 55%, Creativity 30%, Discipline 15% |

These numbers are initial tuning values, not permanent game-balance decisions.
The architecture must make them easy to modify.

## 9. Activities

An Activity represents something the user actually did. Examples: 5-mile run,
60-minute strength workout, 3-hour hike, 30-minute Chinese calligraphy session.

Activities can originate from `manual` or `healthKit`.

A conceptual Activity model should support fields such as: `id`, `source`,
`skill`, `startDate`, `duration`, `distance`, `activeCalories`,
`averageHeartRate`, `externalIdentifier`, `notes`.

Not every activity requires every field. Calligraphy might contain only skill,
duration, and source; running might additionally carry distance.

The domain model must not depend directly on HealthKit types. HealthKit workouts
should be normalized into LifeRank's own Activity representation.

## 10. XP Ledger

Activities and XP awards are different concepts. An Activity represents what
happened. An XPEvent represents progression resulting from that activity.

Treat XPEvents conceptually like an accounting ledger.

```
ACTIVITY                 XP EVENTS
Morning Run              Running          +80 XP
5.1 miles                Endurance        +56 XP
42 minutes               Discipline       +16 XP
                         Exploration       +8 XP
```

XPEvents should allow the application to determine exactly where XP originated.
Avoid making mutable cached totals the only source of truth. The system should
be able to derive progression reliably from the XP ledger or maintain caches
that can be reconstructed from it.

Deleting or correcting an activity must not leave unexplained XP behind.

## 11. XP Calculation

XP should not simply be `1 minute = 1 XP`. Duration matters, but the
architecture should support additional factors: duration, distance,
workout/activity type, intensity, achievement, difficulty.

The MVP can start with relatively simple formulas. The important requirement is
that XP calculation lives in a dedicated progression/domain layer and is
configurable.

```
Activity → XP Calculation → Skill XP → Attribute Distribution
```

Do not calculate XP inside SwiftUI views. Do not make the first formulas
unnecessarily sophisticated — we will tune them through actual usage.

## 12. Attribute XP Distribution

Once an activity's XP is calculated, appropriate XP should be distributed
according to the skill's attribute weights.

A Running activity producing 80 XP distributes as Endurance +56, Discipline +16,
Exploration +8.

**Rounding must be deterministic and must not silently lose XP.** Automated
tests should cover this behavior.

## 13. Skill Challenges

XP alone should not determine skill rank. Skill advancement should eventually
require demonstrated milestones.

Configurable examples for Running:

- F → E: Complete a continuous 5K
- E → D: Run a sub-30-minute 5K
- D → C: Run a sub-25-minute 5K

For less quantitative skills such as Chinese Calligraphy:

- F → E: Complete foundational practice requirements
- E → D: Complete a defined practice milestone
- D → C: Complete a full calligraphy work

For the MVP, qualitative challenges may be manually marked complete.
**Do not implement AI judging.**

## 14. Overall Promotion Trials

Overall rank advancement requires a promotion trial.

```
C-RANK PROMOTION
XP Requirement             ✓
Skill Requirements         ✓
Attribute Requirements     ✓
Promotion Trial
  Run benchmark            ✓
  Calligraphy challenge    ✓
  Strength benchmark       □
```

Once all required progression conditions and trial conditions are satisfied, the
user may promote. Promotion should be an explicit event. The app should not
silently change the user's rank in the background. This allows promotion to feel
significant.

## 15. Rank Requirements

Use configurable definitions:

```
RankDefinition(
    rank: .c,
    xpRequired: ...,
    requiredSkillRank: ...,
    requiredSkillCount: ...,
    minimumAttributeLevel: ...,
    requiredAttributeCount: ...,
    trial: ...
)
```

Initial balancing values are placeholders. Possible starting structure:

| Rank | Overall XP | Skills | Attributes | Trial |
|---|---|---|---|---|
| E | 1,000 | 2 skills at E | 4 attributes ≥ 10 | E-rank trial |
| D | 5,000 | 3 skills at D | 5 attributes ≥ 20 | D-rank trial |
| C | 15,000 | 3 skills at C | 6 attributes ≥ 30 | C-rank trial |
| B | 40,000 | 2 B skills + additional lower-rank skills | 6 attributes ≥ 40 | B-rank trial |
| A | 100,000 | 2 A skills + additional B skills | 7 attributes ≥ 50 | A-rank trial |
| S | 250,000 | 1 S skill + multiple A skills | broad requirements | S-rank trial |

These numbers are provisional. The application should make balancing changes
inexpensive.

## 16. Quests

Quests provide short-term direction. Initial quest types: Daily, Weekly,
One-time.

Examples: "Practice Chinese Calligraphy 30 minutes", "Run 10 miles this week
(7.3 / 10.0)", "Strength train twice this week (1 / 2)".

Quests may reward bonus XP. However, bonus XP should not overwhelm XP earned
from actually performing the activity.

Quest completion should usually derive automatically from Activity data when
possible. Do not build a complex procedural quest-generation engine for the MVP.
Initial quests can be manually configured.

## 17. Consistency

Do not make traditional streaks a central progression mechanic. Missing one day
should not invalidate months of work.

If consistency statistics are implemented, prefer rolling measures such as:

```
LAST 30 DAYS
Running             73%
Strength Training   81%
Calligraphy         62%
```

Rank and lifetime progression never decrease because the user misses sessions.

## 18. HealthKit Integration

HealthKit is the single fitness-data integration layer for the MVP. Garmin and
Hevy already synchronize with Apple Health. LifeRank should not communicate
directly with Garmin or Hevy.

Initially request only HealthKit permissions that are genuinely useful: workouts,
walking/running distance, active energy, heart rate where useful/available.
Workout routes are not required for MVP.

HealthKit support should be isolated behind a dedicated service/provider:

```swift
protocol ActivityProvider {
    func fetchActivities(since date: Date) async throws -> [ImportedActivity]
}
```

The exact API may differ, but maintain this architectural boundary. HealthKit
types should be converted into internal types before entering the progression
system.

## 19. HealthKit Workout Mapping

Initial mapping: Running → Running skill; Hiking → Hiking skill; Traditional
Strength Training → Strength Training skill.

Mappings should be configurable or centralized. Do not spread HealthKit
workout-type switches throughout the application.

## 20. Garmin and Hevy Data

Do not assume Garmin or Hevy expose every desired metric through Apple Health.
We must test actual HealthKit data from a Garmin-recorded run and a
Hevy-recorded strength workout.

Inspect what is actually available: workout type, duration, distance, active
calories, heart rate, source, other useful metadata.

Design XP formulas around data that reliably exists. Do not create direct Garmin
or Hevy integrations simply to obtain additional information during MVP
development. Strength challenges such as a particular bench-press performance
can be manually completed if Hevy does not expose set/rep/weight information
through HealthKit.

## 21. HealthKit Deduplication

A HealthKit workout must never award XP more than once. Store sufficient external
identification/synchronization information to recognize already imported
workouts. HealthKit UUIDs or another stable identifier should be used where
appropriate.

```
HealthKit Workout
       ↓
Already imported?
   ↙          ↘
 Yes          No
  ↓            ↓
Ignore      Normalize
                ↓
             Activity
                ↓
            XP Engine
```

**Deduplication is a correctness requirement, not an optional enhancement.**

## 22. Manual Activity Logging

Manual logging should be extremely fast:

```
Log Activity → Select Skill → Enter Duration → Optional Metrics/Notes → Save
```

The goal is to make routine manual logging take approximately ten seconds or
less. Do not require unnecessary forms.

## 23. Character Dashboard

The Character screen is the primary screen.

```
LIFERANK
D-RANK
Level 27        [RADAR CHART]

Overall XP
██████████████░░░░
12,840 / 15,000

ATTRIBUTES
Strength        28    Knowledge       31
Endurance       41    Creativity      34
Dexterity       23    Discipline      37
Mobility        19    Exploration     29

NEXT PROMOTION — C-RANK
XP Requirement            12,840 / 15,000
Skill Requirement         2 / 3
Attribute Requirement     5 / 6
Promotion Trial           Locked
```

Exact visual design can evolve. Information hierarchy is more important
initially than decorative styling.

## 24. Skills Screen

Display skills and current rank. Selecting a skill opens its detail screen.

## 25. Skill Detail Screen

```
CHINESE CALLIGRAPHY
F-RANK
340 / 500 XP

NEXT RANK — E-RANK
XP Requirement    340 / 500
Challenge         Complete foundational practice milestone

RECENT ACTIVITY
Sep 4       32 min
Sep 2       24 min
Aug 31      41 min
```

## 26. Activity History

Provide a chronological activity history.

```
TODAY
Morning Run              5.1 mi · 42 min
Garmin via Apple Health           +80 XP

Strength Training                 61 min
Hevy via Apple Health             +65 XP

Chinese Calligraphy               32 min
Manual                            +34 XP
```

Activities should support correction/removal: edit when technically appropriate,
delete, ignore imported workout, recalculate XP.

Correcting an activity must keep the XP ledger consistent.

## 27. Trials Screen

Provide a dedicated place for current and historical promotion trials. The trial
unlocks when progression requirements are complete. Once complete, promotion
requires explicit user action.

## 28. Navigation

Keep navigation simple. Suggested primary tabs: Character, Skills, Log, Quests,
History.

Trials can be accessed from Character/Rank progression rather than requiring
another permanent tab. Avoid excessive navigation depth.

## 29. Data Persistence

Use SwiftData. Persist at minimum: skills, activities, XP events, quests, quest
progress where necessary, skill challenges, rank/trial state, configuration/
settings where appropriate, HealthKit import identifiers/synchronization state.

Avoid storing redundant derived data unless necessary for performance. If
derived state is cached, it should be reconstructable.

## 30. Backup and Export

Before LifeRank becomes a long-term personal record, implement data export to a
versioned JSON representation containing sufficient information to reconstruct
the user's progression: activities, XP events, skill configuration/progression,
quests, completed challenges, rank/trial state, relevant settings.

Eventually provide an import/restore path. Data accumulated over months or years
must not exist solely in an irreplaceable local database.

## 31. Architecture

```
LifeRank/
├── App/
├── Domain/
│   ├── Models/
│   ├── Progression/
│   ├── Ranks/
│   ├── Skills/
│   ├── Quests/
│   └── Trials/
├── Data/
│   ├── Persistence/
│   └── Seed/
├── Integrations/
│   └── HealthKit/
├── Features/
│   ├── Character/
│   ├── Skills/
│   ├── ActivityLog/
│   ├── Quests/
│   ├── History/
│   └── Trials/
├── Components/
│   ├── RadarChart/
│   ├── XPBar/
│   └── RankBadge/
└── Utilities/
```

Exact folder names are flexible. The architectural boundaries are not.

## 32. Domain Layer Rules

Progression logic must be pure Swift wherever practical. The domain/progression
layer must not import SwiftUI. It should not require a live SwiftData context to
calculate XP. It should not know about `HKWorkout`.

```
HealthKit → HealthKitService → ImportedActivity → Activity → ProgressionEngine → XPEvents
```

This makes progression logic deterministic and unit-testable.

## 33. Progression Engine

A dedicated progression engine/service is responsible for: calculating activity
XP, creating skill XP events, distributing attribute XP, calculating attribute
levels, calculating skill progression, evaluating rank requirements, determining
promotion eligibility.

Avoid a giant god object if responsibilities naturally separate. Potential
services: `ActivityXPService`, `AttributeProgressionService`,
`SkillProgressionService`, `RankService`, `QuestService`.

But do not overengineer solely to create abstractions. Prefer the simplest
architecture that maintains clean separation.

## 34. Configuration

Game-balance values will change frequently. Keep these centralized/configurable:
XP formulas, skill attribute weights, attribute level curves, skill rank
thresholds, rank requirements, quest rewards, challenge requirements.

Do not bury balance constants in SwiftUI files. We should be able to rebalance
progression without rewriting application architecture.

## 35. Testing

Progression correctness is important because users need to trust their character
sheet. Automated tests should cover at least:

**XP** — Running activity generates expected skill XP; attribute distribution
matches configured weights; rounding does not silently lose intended distributed
XP; calligraphy distributes XP correctly.

**Levels** — Correct XP produces correct attribute level; level thresholds
increase appropriately; boundary conditions are correct.

**Ranks** — XP alone does not cause promotion; missing skill requirements
prevent eligibility; missing attribute requirements prevent eligibility; missing
trial completion prevents promotion; all requirements produce promotion
eligibility.

**HealthKit imports** — Where practical, test normalization separately from
actual HealthKit queries.

**Deduplication** — The same imported workout cannot award XP twice.

**Deletion/correction** — Removing an activity removes or reverses its
associated progression correctly.

## 36. Error Handling

Do not silently fail when data affects progression.

- HealthKit authorization denied → "Apple Health access is disabled. You can
  continue logging activities manually."
- Imported workout cannot be classified → do not arbitrarily award XP; allow it
  to remain unclassified or ignored until handled.
- XP processing fails → do not save half an activity transaction that creates
  inconsistent progression. Prefer atomic persistence where practical.

## 37. Visual Direction

The app should feel like a sophisticated RPG character interface, not a childish
habit tracker.

Desired: dark or restrained interface, strong typography, prominent rank,
prominent radar chart, clear numerical progression, subtle RPG influence,
restrained animation, high information density without clutter.

Avoid: excessive cartoon imagery, fake currencies, loot boxes, unnecessary
avatars, confetti everywhere, childish gamification, excessive gradients,
cluttered dashboards.

The user's real statistics should be the visual centerpiece.

## 38. Animation and Haptics

Polish comes after correctness. Eventually use animation for XP bar increases,
radar-chart changes, attribute level-ups, quest completion, promotion
eligibility, and rank promotion.

Use haptics selectively for meaningful events. A rank promotion should feel
significant. A normal app tap should not.

## 39. MVP Scope

1. Overall F–S rank system
2. Overall XP
3. Eight attributes
4. Radar chart
5. Skill system
6. Skill ranks
7. Configurable skill-to-attribute relationships
8. Manual activity logging
9. HealthKit workout import
10. Garmin workouts through Apple Health
11. Hevy workouts through Apple Health
12. XP calculation
13. Attribute progression
14. Skill progression
15. Quests
16. Skill challenges
17. Promotion trials
18. Activity history
19. Data correction/deletion
20. JSON backup/export
21. Automated progression tests

## 40. Explicitly Out of Scope

Do NOT implement unless explicitly requested later: seasons, proof/evidence
uploads, activity photos, AI skill judging, social features, friends,
leaderboards, multiplayer, classes/build names, complex skill trees,
achievements, direct Garmin API, direct Hevy API, Strava, Android, web
application, backend, accounts/login, subscriptions, monetization, cloud
synchronization, competitive mechanics.

Do not proactively add these while implementing another feature.

## 41. Development Strategy

Build incrementally. Do not attempt to generate the entire application in one
pass. Every stage should leave the project compiling and preferably tested.

- **Stage 1 — Domain Foundation:** Rank, Attribute, Skill, Activity, XPEvent,
  skill/attribute configuration, ProgressionEngine, seed data, unit tests. No
  significant UI.
- **Stage 2 — First Vertical Slice:** Manual Chinese Calligraphy Activity →
  Persist Activity → Generate XPEvents → Update Character Statistics → Display
  Result. This proves the application's fundamental architecture.
- **Stage 3 — Character Dashboard:** rank, overall XP, attributes, XP progress,
  basic radar chart.
- **Stage 4 — Skills:** skills list, skill details, skill XP, skill ranks.
- **Stage 5 — HealthKit:** authorization, workout retrieval, normalization,
  mapping, deduplication, import. Test with actual Garmin and Hevy workouts.
- **Stage 6 — Quests:** daily, weekly, one-time, automatic progress from
  activities.
- **Stage 7 — Challenges and Rank Trials:** skill challenges, overall promotion
  requirements, trials, explicit promotion.
- **Stage 8 — History and Correction:** activity history, deletion, correction,
  XP recalculation.
- **Stage 9 — Backup:** versioned JSON export, restore/import if practical.
- **Stage 10 — Polish:** animation, haptics, refined visual design, improved
  radar chart, rank-up presentation.

## 42. AI Coding Instructions

1. Read this specification before making architectural decisions.
2. Implement only the feature currently requested.
3. Do not proactively implement future stages.
4. Do not introduce third-party dependencies without approval.
5. Do not silently modify the domain architecture.
6. Preserve working functionality.
7. Add/update tests when modifying progression logic.
8. Compile and run relevant tests after meaningful changes.
9. Fix warnings/errors introduced by your changes.
10. Keep HealthKit isolated from domain logic.
11. Keep SwiftUI free of progression calculations.
12. Keep game-balance values centralized.
13. Prefer simple native Apple APIs.
14. Do not overengineer.
15. If a requirement is ambiguous and materially affects architecture or stored
    data, ask before choosing.
16. Do not rewrite working code merely to impose a different stylistic
    preference.
17. Treat XP and progression integrity as high priority.
18. Ensure imported activities cannot accidentally generate duplicate XP.
19. Keep the project in a buildable state at the end of each task.
20. Explain significant architectural changes before making them.

## 43. Immediate Development Goal

The immediate goal is not to finish LifeRank. The immediate goal is to establish
this reliable workflow:

```
User logs: Chinese Calligraphy, 30 minutes
        ↓
Activity persisted
        ↓
ProgressionEngine processes Activity
        ↓
Chinese Calligraphy XP increases
        ↓
Dexterity / Creativity / Discipline increase
        ↓
Character screen reflects new progression
```

Once this works reliably, implement:

```
Garmin records run → syncs to Apple Health → LifeRank reads workout through
HealthKit → normalized and deduplicated → Running Activity created →
ProgressionEngine processes → Running + Endurance + Discipline + Exploration
increase → Character screen updates
```

Those two workflows validate the core concept. Everything else should build on
top of them.

## 44. Definition of Success

LifeRank succeeds if opening the app gives the user an accurate, motivating
representation of how their real-world abilities have developed.

The desired long-term feeling is:

> "This is the character I have built by actually doing things."

The application is not the game. Real life is the game. LifeRank is the
progression system.
