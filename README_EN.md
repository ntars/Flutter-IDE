[简体中文](README.md) | [English](README_EN.md)

# Flutter-IDE

**A source-first visual IDE for Flutter: drag on a canvas, edit in panels, and always get clean, readable Dart you can maintain without the tool.**

![Status](https://img.shields.io/badge/status-skeleton-8957e5?style=flat-square)
[![Version](https://img.shields.io/badge/version-0.1.0-fb8500.svg?style=flat-square)](#)
[![GitHub license](https://img.shields.io/github/license/ntars/Flutter-IDE?style=flat-square)](./LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.14+-0175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-desktop-02569B.svg?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)

> **Not affiliated with or endorsed by Google.** `Flutter` is a trademark of Google; this project is unrelated to it. "Flutter-IDE" is only the repository's technical identifier, while the product name and trademark are registered separately (see [TRADEMARK.md](TRADEMARK.md)).

---

## 1. Name and Positioning

**Name**: Flutter-IDE (product name Fide). The repository keeps the technical identifier; product name and trademark are registered separately.

**One-line positioning**: a Flutter desktop IDE that binds canvas editing to readable source code — delete it and the project still runs `flutter run`.

**Repository description**: `源码优先的 Flutter 可视化搭建 IDE：画布拖拽与属性面板改值，产出可脱离工具维护的 Dart 代码 | Source-first visual IDE for Flutter: canvas drag, panel edits, and clean Dart you can maintain without the tool.`

**Topics** (20, English only): `flutter`, `flutter-desktop`, `dart`, `ide`, `visual-editor`, `gui-builder`, `code-generation`, `codegen`, `ast`, `design-tokens`, `layout-engine`, `material-design`, `responsive-design`, `accessibility`, `cross-platform`, `desktop-app`, `developer-tools`, `intent-driven`, `source-first`, `open-source`

| Item | Value |
|---|---|
| Version | 0.1.0 |
| Status | Skeleton stage: structure, signatures and contracts are fixed; implementation follows milestones |
| Repository | <https://github.com/ntars/Flutter-IDE> |
| License | Apache-2.0 / MIT (layered by directory) |

---

## 2. Overview

### 2.1 Background

Visual builders usually end at "generated code, no way back": the output is unreadable and unmaintainable, so the project is locked to the platform forever.

### 2.2 The problem

Make visual editing produce code **as if a person wrote it** — code that can be taken over, reviewed, and understood line by line in a `git diff`.

### 2.3 Approach

The single test of whether this project should exist:

> Delete Flutter-IDE: can the project still `flutter run` and still be taken over by someone else?

If yes, the project is valid. If not, it is another private-Schema platform. The repository therefore contains **no project structure that exists only inside the tool** — intent outlines, overlays and design tokens are all plain files in git.

### 2.4 Suitable for

- Teams that need a fast Flutter UI skeleton without being locked into a tool;
- Teams that want one source of truth for design tokens and breakpoints;
- Projects that need UI constraints checkable in CI (leaves own no layout, tokens must exist).

### 2.5 Not suitable for

| Not doing | Reason |
|---|---|
| Visual logic programming | Business flows, state management and request layers are hand-written Dart. Visual logic graphs cost more to maintain than code |
| Platform back end | No hosted database, auth or cloud functions. Binding a back end repeats the "generated code, no way back" failure |
| Runtime AI | No path that calls a model while a page is open. AI acts at generation time only; output goes into git |
| Full automation | Information-architecture migration and density tiers must be declared by a person. The more automation, the more silent the errors |

### 2.6 Strengths and limitations

| Strength | Evidence |
|---|---|
| No private Schema | Intent, overlay and tokens are plain files; deleting the tool does not affect builds |
| Core separated from UI | `ide_core` has no Flutter dependency, so `dart test` and CI work |
| One change, one diff | The overlay is flattened to a single `nodeId/breakpoint/path` key |
| Deterministic output | No runtime AI; the same input generates the same result twice |

| Limitation | Scope | Mitigation |
|---|---|---|
| Skeleton stage | Canvas, write-back and point-and-click are not implemented | Follow the roadmap; status is stated honestly |
| Desktop only | No web or mobile IDE | Generated projects are cross-platform; only the tool is desktop |
| Three block types | text / button / card | Third parties can write blocks against `material_sdk` |
| No performance data | Not benchmarked | Benchmarks are on the roadmap; no estimates given |

---

## 3. Core Features

| Feature | Trigger | Result |
|---|---|---|
| Canvas editing | Drag a widget on the canvas | Edits the intent outline, not the source layout |
| Property editing | Change a value in the property panel | Writes an overlay delta keyed by `nodeId/breakpoint/path` |
| Intent validation | Save, or `fide validate` in CI | Five hard rules: leaves own no layout, `foldTo` required, unique id, priority range, token exists |
| Block inspection | `fide blocks` | Lists the block library and parses seven property types from `spec.yaml` |
| Code generation | codegen (signature stage) | `output = base + delta`, keeping both sides of a conflict |
| Sync metrics | Open the sync panel | Counts auto / patch / orphan |
| Point-and-click | Click a widget in the running app | Prefers `creationLocation`; writes back via `Semantics(identifier:)` |

---

## 4. Core Characteristics

### 4.1 Source is the only source of truth

Designer, property panel and canvas are views over source code, never owners of it. Any tool state can be rebuilt from disk.

### 4.2 Intent is a first-class citizen

A widget says "what I am, how important I am, where I go on narrow screens", never "which row and column I sit in". Containers own layout; leaves own identity.

### 4.3 Decide at generation time, never at runtime

Human declares intent → generator produces layout → validator and golden tests gate it → human reviews the diff → commit. Zero runtime AI, purely static, fully reproducible.

### 4.4 Dual anchors

`creationLocation` is precise but absent in release builds; `Semantics(identifier:)` is a stable string written into source and survives refactors. One is for selecting, the other for writing back.

### 4.5 Three sync states

Most tools offer "synced / detached". This one needs three: auto (follows base), patch (manual override), orphan (source widget deleted, awaiting action).

---

## 5. Design Details and Engineering Trade-offs

```text
┌──────────────────────────────────────────────┐
│  ide_app (Flutter desktop shell)             │
│  ├─ canvas         ├─ outline panel          │
│  ├─ properties     ├─ conflict arbitration   │
│  └─ sync ratio                               │
├──────────────────────────────────────────────┤
│  ide_core (pure Dart, runnable from CLI)     │
│  ├─ project_model   intent / delta / tokens  │
│  ├─ codegen         intent+delta → Dart      │
│  ├─ ast_writer      analyzer + range writes  │
│  ├─ vm_bridge       VM Service select/reload │
│  ├─ validator       five hard rules          │
│  └─ metrics         auto / patch / orphan    │
├──────────────────────────────────────────────┤
│  material_sdk (block protocol) + design      │
├──────────────────────────────────────────────┤
│  cli (CI entry point)                        │
└──────────────────────────────────────────────┘
```

**Why base + delta instead of a fork.** `output = base + delta` makes "synced" the default behaviour, so only real conflicts need a human — and the conflict panel must show both sides rather than force a blind choice.

**Why the formatter version is pinned.** `dart_style` 3.7's tall style is incompatible with 2.x, so the same code diffs at whole-file level across versions. Beyond three formatting rules, the formatter version must be pinned in the lock file or CI and local machines overwrite each other.

**Why the UI layer has a single exit.** Flutter 3.50 marks `package:flutter/material.dart` as deprecated in favour of `package:material_ui`. The skeleton keeps the former (all ecosystem docs are written against it) but every UI file imports from `packages/ide_app/lib/app/ui.dart`, so switching is a one-line export change. The deprecation warning is deliberately not suppressed.

**Why breakpoints only read container width.** `classify()` takes `LayoutBuilder`'s `constraints.maxWidth`, not the screen width. A widget only cares how wide its slot is, so moving it to a sidebar works automatically. The parameter is named `containerWidth`; no alias for screen width is offered.

**Why the core has no Flutter dependency.** The core can run `dart test`, run in CI, and survive a desktop crash. `packages/cli/` proves it by performing validation and block inspection independently.

---

## 6. Technology Stack and Dependencies

| Layer | Technology | Version constraint |
|---|---|---|
| Language | Dart | ^3.14.0 (local and CI baseline) |
| Workspace | Dart pub workspaces | One `pubspec.lock`, one `dart pub get` |
| UI | Flutter desktop | Provided by the SDK |
| Parsing and write-back | `package:analyzer` | Constrained by the Dart SDK |
| Selection and hot reload | VM Service | Constrained by the Flutter SDK |
| Tests | `dart test` / golden tests | Constrained by the SDK |

Melos is deliberately not used: four packages need no release scripting. Full third-party disclosure is in [NOTICE](NOTICE).

---

## 7. Installation and Deployment

### 7.1 Requirements

| Item | Requirement |
|---|---|
| Flutter SDK | 3.32+ (includes Dart 3.14+) |
| OS | macOS / Windows / Linux |
| Optional | Xcode (macOS builds), Visual Studio (Windows builds) |

### 7.2 Install

```sh
git clone https://github.com/ntars/Flutter-IDE.git
cd Flutter-IDE
dart pub get
```

### 7.3 Verify

```sh
dart run packages/cli/bin/fide.dart validate --project templates/starter_app
```

Exit code `0` means the environment is ready.

### 7.4 Upgrade and uninstall

Upgrade: `git pull && dart pub get`. Uninstall: delete the directory — nothing is installed system-wide and no global command is registered.

### 7.5 Containerisation

A desktop IDE is not containerised; `packages/cli/` runs in any image with a Dart SDK for CI validation.

---

## 8. Quick Start

```sh
dart pub get

# Validate the intent outline of a template project
dart run packages/cli/bin/fide.dart validate --project templates/starter_app

# List the block library
dart run packages/cli/bin/fide.dart blocks --project .

# Desktop shell (skeleton: five panels with sample data)
cd packages/ide_app && flutter run -d macos
```

Exit codes (relied on by CI): `0` pass / `1` blocking errors / `2` project cannot open / `70` not implemented.

Expected result: the desktop shell opens with five panels. Empty states honestly show "not connected" instead of a fake canvas.

---

## 9. Configuration

| Item | Location | Type | Default | Purpose |
|---|---|---|---|---|
| Design tokens | `design/lib/tokens.dart` | Dart constants | 47 entries | Colour, radius, spacing, weight |
| Breakpoints | `design/` (breakpoint table) | Dart constants | 4 tiers | Material 3 window size class |
| Block declarations | `blocks/<name>/spec.yaml` | YAML | — | Seven property types and defaults |
| Intent outline | `<project>/intent/*.yaml` | YAML | — | Identity, priority, fold target |
| Overlay | `<project>/overlay/*.json` | JSON | empty | Single-key deltas |

No runtime config file, no environment variables, no hot-update switch: everything is a plain file in git, and changing configuration is a commit.

---

## 10. API and Module Reference

| Package | Responsibility | Public entry |
|---|---|---|
| `packages/ide_core` | Intent model, codegen, AST write-back, validation, metrics | `FideCodegen.resolve`, five validator rules |
| `packages/material_sdk` | Block protocol and `spec.yaml` parsing | Seven property types |
| `packages/ide_app` | Flutter desktop shell with five panels | `packages/ide_app/lib/app/ui.dart` |
| `packages/cli` | CI entry, command `fide` | `validate` / `blocks` / `build` (pending codegen) |

CLI exit codes are in chapter 8; `build` becomes available once codegen lands and currently returns `70`.

---

## 11. Repository Layout

```text
Flutter-IDE/
├── LICENSE               Apache-2.0 (core/SDK/blocks)
├── LICENSE-MIT           MIT (UI/templates/docs)
├── LICENSING.md          Routing table
├── NOTICE                Third parties + generated-code exemption
├── CONTRIBUTING.md       DCO
├── TRADEMARK.md          Brand usage rules
│
├── packages/
│   ├── ide_core/         Pure Dart core, no Flutter dependency
│   ├── ide_app/          Flutter desktop shell (five panels)
│   ├── material_sdk/     Block protocol
│   └── cli/              `fide` command line for CI
│
├── blocks/               Official blocks (text / button / card)
├── design/               Tokens + breakpoints (single source)
├── templates/            Templates (MIT): starter_app, admin_dashboard
└── docs/                 Contract documents
```

---

## 12. Performance

**Not benchmarked**, so no frame rates, generation timings or memory figures are given. Known facts at skeleton stage:

| Item | Status |
|---|---|
| Deterministic output | Same input, same output (design goal; enters tests once codegen lands) |
| Validation cost | Five static checks, no rendering involved |
| Desktop shell | Five panels with sample data, no real project loaded |

Benchmarks are on the roadmap; before then any performance number would be speculation and is not documented.

---

## 13. Security and Privacy

- **Fully local**: no network access, no telemetry, no model endpoints. Zero runtime AI is a design constraint, not a setting.
- **No accounts**: no user identity is collected.
- **File access**: only the project directory the user opens, plus the workspace lock file.
- **Generated code ownership**: code produced with this tool belongs to the user and is not covered by this project's licence.
- **Reporting**: see [SECURITY.md](SECURITY.md).

---

## 14. Compatibility

| Item | Supported | Note |
|---|---|---|
| Dart | ^3.14.0 | One baseline for the workspace and all packages |
| Flutter | 3.32+ | `material.dart` is deprecated in 3.50; isolated behind a single export |
| OS | macOS / Windows / Linux | Desktop; macOS is the primary development environment |
| Web / mobile | No | Generated projects are cross-platform; the tool is desktop-only |
| Templates | `starter_app`, `admin_dashboard` | Bundled |

---

## 15. Known Issues and Limitations

### 15.1 Current implementation status

| Module | Status | Note |
|---|---|---|
| design (tokens + breakpoints) | Done | 47 tokens, 4 tiers; the validator checks token refs against them |
| material_sdk | Done | Seven property types; `spec.yaml` parsing implemented |
| ide_core validator | Done | Leaf layout ban / required foldTo / unique id / priority range / token exists |
| ide_core base+delta | Done | `FideCodegen.resolve`: delta wins, both values kept for the conflict panel |
| ide_core codegen | Signature | Order: leaf → container → breakpoint → delta |
| ide_core ast_writer | Signature | Range location plus post-write syntax check; recursive visitor pending |
| ide_core vm_bridge | Signature | Property panel shows runtime values only, never guesses from source |
| cli | validate / blocks available | build waits for codegen |
| ide_app | Five-panel shell runs | Empty states say "not connected" instead of faking a canvas |

### 15.2 Unimplemented features

| Feature | Why not yet | Status |
|---|---|---|
| Codegen and AST write-back | Needs the `ast_writer` recursive visitor | Planned |
| Point-and-click at runtime | Needs a complete `vm_bridge` | Planned |
| Conflict arbitration panel | Needs both values from codegen | Planned |
| Information-architecture migration | Must be human-declared, never inferred | Unscheduled |
| Benchmarks | Only meaningful after codegen | Planned |

Every `TODO(skeleton)` records its implementation order so that no step is skipped and diff noise does not enter at step one.

---

## 16. Changelog

Follows Keep a Changelog and semantic versioning.

### [0.1.0] - 2026-11-18

- Added: workspace skeleton (`ide_core` / `material_sdk` / `ide_app` / `cli`) using Dart pub workspaces.
- Added: 47 design tokens and a four-tier breakpoint table.
- Added: seven block property types and `spec.yaml` parsing.
- Added: five-rule validator and base + delta composition.
- Added: `fide validate` / `fide blocks` commands with exit-code contract.

---

## 17. Roadmap

| Item | Target version | Status |
|---|---|---|
| `ast_writer` recursive visitor and syntax check | 0.2.0 | Planned |
| codegen: leaf → container → breakpoint → delta | 0.3.0 | Planned |
| `vm_bridge` selection and runtime values | 0.4.0 | Planned |
| Conflict and sync panels on real data | 0.5.0 | Planned |
| Benchmarks and full golden-test coverage | 0.6.0 | Planned |

All non-commitments, adjusted as needed.

---

## 18. Contributing

- Environment: Flutter 3.32+ / Dart 3.14+; `dart pub get` is all you need.
- Branches: `main` stays buildable; work happens on `feat/` or `fix/`.
- Commit messages: `<type>(<scope>): <subject>`, scope from (`core` / `sdk` / `app` / `cli` / `design`).
- Contributors sign the DCO (Developer Certificate of Origin) with `git commit -s`.
- Full process in [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 19. Copyright and License

Copyright © 2026 ntars and contributors. Licensed under Apache-2.0 / MIT.

Licensed by directory, using only Apache License 2.0 and MIT. Full text in [LICENSE](LICENSE) (Apache-2.0) and [LICENSE-MIT](LICENSE-MIT) (MIT); routing in [LICENSING.md](LICENSING.md).

| Path | License |
|---|---|
| `packages/ide_core/` `material_sdk/` `cli/` `design/` `blocks/` | Apache-2.0 |
| `packages/ide_app/` `templates/` `docs/` `.github/` | MIT |

**Why Apache-2.0 for the core**: it adds an explicit patent grant (section 3) and NOTICE retention (section 4d) over MIT. Block authors care most about patent risk, and this removes it.

**Generated-code exemption**: all code generated with Flutter-IDE belongs to the user and is not restricted by this project's licence.

**Trademark**: "Fide" and its marks belong to ntars; the code licence grants no trademark rights. See [TRADEMARK.md](TRADEMARK.md).

**No copyleft components** (GPL / LGPL / AGPL / MPL): permissive licences cannot absorb copyleft. See [NOTICE](NOTICE).

---

## 20. NOTICE and Open-Source Compliance

Third-party summary:

| Component | Purpose | License |
|---|---|---|
| `package:analyzer` | AST parsing and range write-back | BSD-3-Clause |
| Flutter SDK / Dart SDK | UI and runtime | BSD-3-Clause |
| Remaining dev dependencies | Tests and lint | See each `pubspec.yaml` |

Full inventory and the generated-code exemption are in [NOTICE](NOTICE).
