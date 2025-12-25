# Project Rules

> This document is a rule index for AI coding assistants.
> Each detailed rule is managed in separate files within the `.claude/rules/` directory.

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

### Smart Rules Integration

> AI는 작업 시작 전 `smart-rules` 스킬을 자동으로 호출하여 관련 규칙 문서를 로드합니다.

**자동 호출 상황:**
- `TodoWrite` 도구 사용 직후 (todo 내용 분석 → 관련 규칙 로드)
- 구현/버그수정/리팩토링 요청 시

**수동 명령어:**
| Command | Description |
|---------|-------------|
| `smart-rules init` | 프로젝트 스캔 후 설정 파일 생성 |
| `smart-rules` | 현재 컨텍스트 기반 문서 로드 |
| `smart-rules [category]` | 특정 카테고리 문서만 로드 |

## 📑 Separated Rule Files

<!-- FORMAT_LOCK: Do not change table structure -->
| Document | Description | Path |
|----------|-------------|------|
| 📋 Rule Index | Project rules list | [.claude/rules/rule-index.md](.claude/rules/rule-index.md) |
| 🔧 Pattern Index | Flutter Desktop implementation patterns | [.claude/rules/pattern-index.md](.claude/rules/pattern-index.md) |
| 🏷️ Labeling System | UI/Architecture labeling rules | [.claude/rules/labeling.md](.claude/rules/labeling.md) |
| 📋 Task Management | Task management and multi-branch development | [.claude/rules/task-management.md](.claude/rules/task-management.md) |
| 📜 History System | Work completion logging rules | [.claude/rules/history.md](.claude/rules/history.md) |
| 📝 Spec Management | Spec document update enforcement | [.claude/rules/spec-management.md](.claude/rules/spec-management.md) |
| 🏛️ Architecture Management | Architecture document update enforcement | [.claude/rules/architecture-management.md](.claude/rules/architecture-management.md) |
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

Each rule file is separated into `.claude/rules/` for Claude Code to quickly load context.

**Pattern documents are in `Docs/Patterns/` with Flutter Desktop-specific implementations.**

## 📚 Documentation Skills

> AI can reference these skills for quick documentation lookup without web search.

### Development Skills
| Skill | Description | Path |
|-------|-------------|------|
| ⚡ flutter-performance-docs | Flutter performance best practices (build cost, rendering, lists) | [.claude/skills/flutter-performance-docs/SKILL.md](.claude/skills/flutter-performance-docs/SKILL.md) |
| 📦 flutter-pub | pub.dev package search (find, info, version, dependencies) | [.claude/skills/flutter-pub/SKILL.md](.claude/skills/flutter-pub/SKILL.md) |

### Planning Skills
| Skill | Description | Path |
|-------|-------------|------|
| 🌳 best-practice-core | Extract best practices as minimal tree (use when writing subtasks) | [.claude/skills/best-practice-core/SKILL.md](.claude/skills/best-practice-core/SKILL.md) |

### Deploy Skills
| Skill | Description | Path |
|-------|-------------|------|
| 🔒 flutter-obfuscate-docs | Code obfuscation guide (use when deploying release builds) | [.claude/skills/flutter-obfuscate-docs/SKILL.md](.claude/skills/flutter-obfuscate-docs/SKILL.md) |

---
*Generated by Archon*