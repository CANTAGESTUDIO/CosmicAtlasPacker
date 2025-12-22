# Project Rules

> This document is a rule index for AI coding assistants.
> Each detailed rule is managed in separate files within the `.factory/rules/` directory.

## CRITICAL: Always respond in Korean

AI must always respond to the user in Korean, regardless of the language used in documentation.

## 🖥️ Flutter Desktop Project

This is a **Flutter Desktop** project for cross-platform desktop applications (macOS, Windows, Linux).

### Key Technologies
- **Framework**: Flutter (Dart)
- **Window Management**: window_manager, desktop_multi_window
- **State Management**: flutter_riverpod / flutter_bloc
- **Architecture**: Clean Architecture (Presentation → Domain → Data)
- **Navigation**: go_router with NoTransitionPage
- **Menu/Tray**: PlatformMenuBar, system_tray
- **File Operations**: file_picker, desktop_drop

### Desktop-Specific Patterns
- **Window Manager**: Custom title bar, window controls, multi-window
- **Native Menu Bar**: PlatformMenuBar with keyboard shortcuts
- **System Tray**: Background operation with tray icon and notifications
- **File System**: File dialogs, drag-drop, file watchers
- **Keyboard Shortcuts**: Shortcuts widget with Actions pattern
- **Platform Channels**: Native code integration (Swift/Kotlin/C++)
- **Responsive Layout**: Adaptive layouts for resizable windows

### Platform Build Commands
| Platform | Build Command |
|----------|---------------|
| macOS | `flutter build macos` |
| Windows | `flutter build windows` |
| Linux | `flutter build linux` |

## 📑 Separated Rule Files

<!-- FORMAT_LOCK: Do not change table structure -->
| Document | Description | Path |
|----------|-------------|------|
| 📋 Rule Index | Project rules list | [.factory/rules/rule-index.md](.factory/rules/rule-index.md) |
| 🔧 Pattern Index | Flutter Desktop implementation patterns | [.factory/rules/pattern-index.md](.factory/rules/pattern-index.md) |
| 🏷️ Labeling System | UI/Architecture labeling rules | [.factory/rules/labeling.md](.factory/rules/labeling.md) |
| 📋 Task Management | Task management and multi-branch development | [.factory/rules/task-management.md](.factory/rules/task-management.md) |
| 📜 History System | Work completion logging rules | [.factory/rules/history.md](.factory/rules/history.md) |
| 📝 Spec Management | Spec document update enforcement | [.factory/rules/spec-management.md](.factory/rules/spec-management.md) |
| 🏛️ Architecture Management | Architecture document update enforcement | [.factory/rules/architecture-management.md](.factory/rules/architecture-management.md) |
| 🎨 UX Design | UX documents by UX Architect agent | [Docs/Index/UX_DESIGN.md](Docs/Index/UX_DESIGN.md) |

## 🎨 UX Documents

> UX 설계 문서는 `Docs/UX/` 폴더에서 관리됩니다.

### Core UX Documents
| Document | Description | Path |
|----------|-------------|------|
| 📐 정보 아키텍처 | 화면 계층 구조, 네비게이션, 메뉴 구조 | [Docs/UX/IA.md](Docs/UX/IA.md) |
| 🔄 사용자 플로우 | 10개 주요 워크플로우 다이어그램 | [Docs/UX/UserFlows.md](Docs/UX/UserFlows.md) |
| 📝 와이어프레임 | 메인 에디터 + 다이얼로그 ASCII 다이어그램 | [Docs/UX/Wireframes/Overview.md](Docs/UX/Wireframes/Overview.md) |
| ⚡ 인터랙션 시퀀스 | 핵심 인터랙션 시퀀스 다이어그램 | [Docs/UX/Sequences/CoreInteractions.md](Docs/UX/Sequences/CoreInteractions.md) |
| 📋 변경 이력 | UX 설계 변경 이력 | [Docs/UX/Changelog.md](Docs/UX/Changelog.md) |

### Design System
| Document | Description | Path |
|----------|-------------|------|
| 🎨 메인 | 디자인 시스템 개요 | [Docs/UX/DesignSystem/DesignSystem_Main.md](Docs/UX/DesignSystem/DesignSystem_Main.md) |
| 🌈 색상 시스템 | 색상 팔레트 및 시맨틱 컬러 | [Docs/UX/DesignSystem/ColorSystem.md](Docs/UX/DesignSystem/ColorSystem.md) |
| ✏️ 타이포그래피 | 폰트 스케일 및 텍스트 스타일 | [Docs/UX/DesignSystem/Typography.md](Docs/UX/DesignSystem/Typography.md) |
| 📏 스페이싱 | 간격 시스템 | [Docs/UX/DesignSystem/Spacing.md](Docs/UX/DesignSystem/Spacing.md) |
| 📐 레이아웃 | 레이아웃 그리드 및 패널 구조 | [Docs/UX/DesignSystem/Layout.md](Docs/UX/DesignSystem/Layout.md) |
| 🧩 컴포넌트 | UI 컴포넌트 정의 | [Docs/UX/DesignSystem/Components.md](Docs/UX/DesignSystem/Components.md) |
| 🎬 모션 | 애니메이션 및 트랜지션 | [Docs/UX/DesignSystem/Motion.md](Docs/UX/DesignSystem/Motion.md) |
| 🌓 테마 | 다크/라이트 테마 | [Docs/UX/DesignSystem/Theming.md](Docs/UX/DesignSystem/Theming.md) |
| ♿ 접근성 | 접근성 가이드라인 | [Docs/UX/DesignSystem/Accessibility.md](Docs/UX/DesignSystem/Accessibility.md) |

## Quick Reference

Each rule file is separated into `.factory/rules/` for Droid to quickly load context.

**Pattern documents are in `Docs/Patterns/` with Flutter Desktop-specific implementations.**

## 📚 Documentation Skills

> AI can reference these skills for quick documentation lookup without web search.

### Development Skills
| Skill | Description | Path |
|-------|-------------|------|
| ⚡ flutter-performance-docs | Flutter performance best practices (build cost, rendering, lists) | [.factory/skills/flutter-performance-docs/SKILL.md](.factory/skills/flutter-performance-docs/SKILL.md) |
| 📦 flutter-pub | pub.dev package search (find, info, version, dependencies) | [.factory/skills/flutter-pub/SKILL.md](.factory/skills/flutter-pub/SKILL.md) |

### Planning Skills
| Skill | Description | Path |
|-------|-------------|------|
| 🌳 best-practice-core | Extract best practices as minimal tree (use when writing subtasks) | [.factory/skills/best-practice-core/SKILL.md](.factory/skills/best-practice-core/SKILL.md) |

### Deploy Skills
| Skill | Description | Path |
|-------|-------------|------|
| 🔒 flutter-obfuscate-docs | Code obfuscation guide (use when deploying release builds) | [.factory/skills/flutter-obfuscate-docs/SKILL.md](.factory/skills/flutter-obfuscate-docs/SKILL.md) |

---
*Generated by Archon*
## 📜 Project Rules Reference

> Additional rules are located in `Docs/Rules/` directory.

| Document | Description | Path |
|----------|-------------|------|
| 📝 Spec Rules | Spec document update enforcement | [Docs/Rules/SPEC_RULES.md](Docs/Rules/SPEC_RULES.md) |
| 🏛️ Architecture Rules | Architecture document update enforcement | [Docs/Rules/ARCHITECTURE_RULES.md](Docs/Rules/ARCHITECTURE_RULES.md) |
| 📋 Task Rules | Task document format enforcement | [Docs/Rules/TASK_RULES.md](Docs/Rules/TASK_RULES.md) |
| 🧠 Brain Guide | Brain canvas usage guide | [Docs/Rules/BRAIN_GUIDE.md](Docs/Rules/BRAIN_GUIDE.md) |
