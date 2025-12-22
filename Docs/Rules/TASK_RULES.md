# Task Management Rules

> Task management rules that AI agents must automatically perform during workflow.

## Adding New Tasks

| Trigger | Action |
|---------|--------|
| User requests new feature/fix | Add task to Backlog in `Docs/Task/{Step}_Task.md` |
| Discovering bug during work | Add task to Backlog |
| Breaking down large task | Add subtasks under parent task |
| Identifying follow-up work | Add task to Backlog |

## ⚠️ Development First Principle

**Development tasks are ALWAYS the top priority. Non-development tasks (deployment, monitoring, marketing, community) can only be considered from MMP phase onwards.**

### Task Type by Phase

| Phase | Allowed Task Types |
|-------|-------------------|
| **POC ~ PILOT** | 🔧 **Development ONLY** (features, bugs, refactoring, tests, architecture) |
| **MMP onwards** | 🔧 **Development first** + Operations/Marketing can be considered |

### What Counts as Development Task

✅ **Development Tasks (All phases):**
- Feature implementation (UI, Logic, API, Database)
- Bug fixes and debugging
- Refactoring and code cleanup
- Test writing and coverage
- Performance optimization
- Architecture improvements

⚠️ **Non-Development Tasks (MMP onwards only):**
- Deployment pipeline and CI/CD setup
- Monitoring and logging infrastructure
- Marketing strategy and campaigns
- Community management and support
- User-facing documentation

### System Development vs Non-Dev Tasks

**Building a system FOR marketing/operations = Development task**
**Doing marketing/operations work itself = Non-development task**

| Task | Type | When Allowed |
|------|------|--------------|
| Implement analytics tracking code | Development | Any phase |
| Create marketing analytics report | Non-dev | MMP onwards |
| Build notification service | Development | Any phase |
| Plan notification marketing campaign | Non-dev | MMP onwards |

### Enforcement Rule

**When creating tasks in POC, MVP, or PILOT phases:**
1. **Check task type** - Is this a development task?
2. **If non-dev task** - Do NOT add to current phase
3. **If system needed for non-dev goal** - Add the SYSTEM DEVELOPMENT task instead
4. **Defer non-dev tasks** - Add to MMP or later phase task document

## ⛔ CRITICAL: Subtask Segmentation is MANDATORY

**AI MUST ALWAYS create subtasks when adding any new task. A task without subtasks is INCOMPLETE and FORBIDDEN.**

### Zero Tolerance Rule

❌ **FORBIDDEN - Tasks without subtasks:**
```markdown
- [ ] Implement login feature #auth !high
```

✅ **REQUIRED - Tasks MUST have subtasks:**
```markdown
- [ ] Implement login feature #auth !high
  - [ ] Design login UI layout
  - [ ] Create LoginView component
  - [ ] Implement form validation logic
  - [ ] Add API integration for authentication
  - [ ] Handle error states and messages
```

### Subtask Requirements

| Requirement | Rule |
|-------------|------|
| **Minimum Count** | Every task MUST have **at least 3 subtasks** |
| **Granularity** | Each subtask completable in 1-2 hours |
| **Specificity** | Use action verbs: Create, Implement, Add, Design, Configure |
| **Independence** | Each subtask independently verifiable |

### Subtask Generation by Task Type

| Task Type | Required Subtasks |
|-----------|-------------------|
| New Feature | UI 설계, 컴포넌트 생성, 로직 구현, API 연동, 에러 처리 |
| Bug Fix | 원인 분석, 수정 코드 작성, 엣지 케이스 확인, 테스트 검증 |
| Refactoring | 기존 코드 분석, 새 구조 설계, 마이그레이션, 테스트 |
| Documentation | 구조 파악, 내용 작성, 예제 추가 |

## Moving Tasks Between Sections

**AI Allowed Actions:**
| Trigger | Target Section | Checkbox |
|---------|----------------|----------|
| Assigned to Agent 1 | Move to `## Worker1` | `- [ ]` |
| Assigned to Agent 2 | Move to `## Worker2` | `- [ ]` |
| Assigned to Agent 3 | Move to `## Worker3` | `- [ ]` |
| **AI finished work** | Move to `## Review` | `- [ ]` |

**User/Reviewer Only Actions (AI FORBIDDEN):**
| Trigger | Target Section | Checkbox | Who |
|---------|----------------|----------|-----|
| User verified task | Move to `## Done` | `- [x]` | User/Reviewer ONLY |
| User defers task | Move to `## Backlog` | `- [ ]` | User ONLY |

**Task Document Sections:** `## Backlog` → `## Worker1` / `## Worker2` / `## Worker3` → `## Review` → `## Done`

## ⛔ CRITICAL: AI FORBIDDEN ACTIONS

**AI MUST NEVER perform these actions:**
```
❌ AI CANNOT move Review → Done
❌ AI CANNOT move Review → Backlog
❌ AI CANNOT move Worker → Done directly
❌ AI CANNOT move Worker → Backlog directly

✅ AI CAN: Backlog → Worker (when starting work)
✅ AI CAN: Worker → Review (when completing work)
```

## Movement Rules
- When moving to Done: change `- [ ]` to `- [x]`
- When moving from Done: change `- [x]` to `- [ ]`
- Subtasks move with parent task
- Preserve all metadata (#tags, !priority, Deadline)

## Task Format

```
- [ ] TaskTitle #tag !priority Deadline(yyyy:mm:dd)
```

**Examples:**
- `- [ ] Implement login feature #auth #frontend !high Deadline(2025:01:15)`
- `- [ ] Write API documentation #docs !medium Deadline(2025:01:20)`
- `- [x] Design DB schema #backend !low` (completed task)

## Priority Reference

| Priority | Use Case | Examples |
|----------|----------|----------|
| `!high` | Urgent, blocker | Build failure, crash, critical bug |
| `!medium` | Normal priority | General feature development (default) |
| `!low` | Nice to have | Refactoring, documentation, code cleanup |

## ⛔ CRITICAL: Task Document Format Enforcement

**AI MUST maintain EXACT format when moving tasks between sections. Format violations will break Kanban board parsing.**

### Format Violation Examples

❌ **FORBIDDEN - These will cause format breakage:**
- `### Subtasks` or `#### Phase 1` headers between tasks
- 4-space or tab indentation for subtasks
- Nested subtasks (grand-children with 4+ spaces)

✅ **REQUIRED - Correct format:**
```markdown
## Worker1
- [ ] Parent Task #tag !high
  - [ ] Subtask 1
  - [ ] Subtask 2
```

### Zero Tolerance Format Rules

**1. Subtask Indentation**: EXACTLY 2 spaces (NO tabs, NO 4 spaces)
**2. No Intermediate Headers**: ONLY `## Section` headers allowed
**3. Flat Hierarchy Only**: Parent → Subtasks (2 spaces) ONLY

### Pre-Move Checklist

Before moving any task, AI MUST:
1. Capture Full Block (Parent + ALL subtasks)
2. Preserve EXACTLY 2-space indentation
3. Keep ALL metadata (#tags, !priority, Deadline)
4. Update checkbox (`- [x]` for Done, `- [ ]` otherwise)
5. NO format changes

### Quick Reference

| Element | Format | Example |
|---------|--------|---------|
| Section header | `## Name` | `## Worker1` |
| Parent task | `- [ ] Title` | `- [ ] Login #auth` |
| Subtask | `··- [ ] Title` | `  - [ ] Create UI` |

---
*Generated by Archon*