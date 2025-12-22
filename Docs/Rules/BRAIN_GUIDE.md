# Brain Guide

> ⛔ MANDATORY workflow for Archon Brain canvas system. AI MUST follow EXACTLY or canvas will NOT work.

---

## 🚫 STOP! READ BEFORE ANY FILE OPERATIONS

**DO NOT CREATE ANY FILES until you have:**
1. ✅ Read and understood the Blocking Rules below
2. ✅ Calculated the exact `fileName` from canvas name
3. ✅ Verified ALL folder names will match `fileName`
4. ✅ Planned node positions using Grid Layout (no overlap!)

**If you skip these steps, the canvas WILL BE BROKEN and show "0 nodes" in Archon app.**

---

## ⛔ BLOCKING RULE #1: fileName (ZERO TOLERANCE)

**If canvas `name:` value and folder names don't match, Archon app CANNOT load nodes!**

### fileName Generation Algorithm (Archon App Internal Logic)

```
1. Replace spaces with hyphens: "My Canvas" → "My-Canvas"
2. Convert to lowercase: "My-Canvas" → "my-canvas"
3. Keep only letters, numbers, hyphens: "Pattern: V2" → "pattern-v2"
```

**Transformation Examples:**

| `name:` value | Generated fileName |
|---------------|-------------------|
| `"My Canvas"` | `my-canvas` |
| `"Aesthetic Canvas: Minimal Diary"` | `aesthetic-canvas-minimal-diary` |
| `"UI Design (v2)"` | `ui-design-v2` |

### Folder Naming Rule (MUST MATCH fileName)

```
Canvas file:    {fileName}.md
Nodes folder:   {fileName}_Nodes/
Connections:    {fileName}_Connections/
Datasheet:      {fileName}_Datasheet/
```

### ✅ CORRECT Example

```yaml
# Canvas file: aesthetic-minimal-diary.md
name: "Aesthetic Minimal Diary"  # fileName = aesthetic-minimal-diary
```
```
Docs/Brain/
├── aesthetic-minimal-diary.md
├── aesthetic-minimal-diary_Nodes/      ✅ MATCH
├── aesthetic-minimal-diary_Connections/
└── aesthetic-minimal-diary_Datasheet/
```

### ❌ WRONG Example (App shows 0 nodes)

```yaml
# Canvas file: aesthetic-minimal-diary-brain.md
name: "Aesthetic Canvas: Minimal Diary Brain"
# fileName = aesthetic-canvas-minimal-diary-brain (colon removed!)
```
```
Docs/Brain/
├── aesthetic-minimal-diary-brain.md
├── aesthetic-minimal-diary-brain_Nodes/  ❌ MISMATCH!
│   # App looks for: aesthetic-canvas-minimal-diary-brain_Nodes
```

### Pre-Creation Checklist (MANDATORY)

**Before creating ANY files:**

1. [ ] Calculate fileName from `name:` value
2. [ ] Canvas file = `{fileName}.md`
3. [ ] Nodes folder = `{fileName}_Nodes/`
4. [ ] Connections folder = `{fileName}_Connections/`
5. [ ] Datasheet folder = `{fileName}_Datasheet/`
6. [ ] **ALL folder names EXACTLY match the calculated fileName**

---

## ⛔ BLOCKING RULE #2: Node Positioning (NO OVERLAP)

**Nodes MUST be placed on grid. Overlapping nodes = unusable canvas.**

```
Position X = COLUMN × 350
Position Y = ROW × 250
```

**Before creating nodes, assign grid positions:**
```
Node 1: Col 0, Row 0 → position: { x: 0, y: 0 }
Node 2: Col 1, Row 0 → position: { x: 350, y: 0 }
Node 3: Col 0, Row 1 → position: { x: 0, y: 250 }
Node 4: Col 1, Row 1 → position: { x: 350, y: 250 }
```

---

## ⛔ BLOCKING RULE #3: Mandatory Validation

**After creating ALL files, AI MUST verify:**

```
✓ VALIDATION CHECKLIST (AI must print this)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Canvas name:     "{name value}"
Calculated fileName: "{result}"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Canvas file:   {fileName}.md
✓ Nodes folder:  {fileName}_Nodes/ (contains {N} files)
✓ Connections:   {fileName}_Connections/ (if applicable)
✓ Datasheet:     {fileName}_Datasheet/ (if applicable)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Node positions verified: No overlaps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If validation fails, FIX IMMEDIATELY before reporting completion.**

---

## About Brain Organizer

The Brain Organizer is a systematic workflow for using Archon's Brain canvas system. Brain canvases are visual knowledge organization tools that help structure research, references, and complex concepts.

**Key Capabilities:**
- Create and manage visual canvases for organizing information
- Support multiple node types (Heading, Text, Image, Memo, Data-Sheet)
- Group related nodes with color coding
- Connect nodes to show relationships

## When to Use (AUTOMATIC)

**⚠️ AI MUST automatically follow this guide when:**
- ANY file operation in `Docs/Brain/` directory
- User mentions "Brain", "canvas", "nodes", "캔버스", "브레인"
- Creating visual research output
- Organizing aesthetic references
- Any task requiring structured information visualization

**Trigger Phrases:**
- "Create a Brain canvas for {topic}"
- "Organize {info} in Brain"
- "Add nodes to Brain canvas"
- "Brain-organize {research results}"
- "브레인 캔버스 만들어줘"
- "정보 정리해서 브레인에"

**Use Cases:**
- Aesthetic research output organization
- Visual reference collection
- Pattern library creation
- Cultural reference mapping
- Complex concept visualization

## Directory Structure

**⚠️ All folder names MUST use `{fileName}` calculated from canvas `name:` value!**

```
Docs/Brain/
├── {fileName}.md                      # Main canvas file
├── {fileName}_Nodes/                  # Node files directory
│   ├── Node_Heading-Text_{UUID}.md
│   ├── Node_Body-Text_{UUID}.md
│   ├── Node_Post-It_{UUID}.md
│   ├── Node_Image_{UUID}.md
│   ├── Node_Memo_{UUID}.md
│   └── Node_Data-Sheet_{UUID}.md
├── {fileName}_Connections/            # Connection files directory
│   ├── Connection_Arrow_{UUID}.md
│   └── Connection_Normal_{UUID}.md
└── {fileName}_Datasheet/              # Datasheet files directory
    ├── Datasheet_{UUID}.csv
    └── {UUID}.styles.json
```

## Workflow

### Phase 1: Canvas Planning

1. **Canvas Purpose**: Determine type (aesthetic, technical, conceptual)
2. **Canvas Name**: Choose name, then calculate fileName
   - Recommended: Use kebab-case directly (e.g., `my-research`)
   - Alternative: Human-readable → calculate fileName
3. **Node Types**: Plan Heading-Text, Image, Memo, Data-Sheet nodes

### Phase 2: Canvas Creation

**File**: `Docs/Brain/{fileName}.md`

**Required YAML Metadata:**
```yaml
---
id: "{UUID}"
name: "{Name}"
viewport_offset: { x: 0, y: 0 }
zoom_level: 1.0
created_at: "{ISO8601}"
updated_at: "{ISO8601}"
node_ids: []
connections: []
groups: []
---
```

### Phase 3: Node Creation

**Directory**: `Docs/Brain/{fileName}_Nodes/`

| Information Type | Node Type | File Format |
|------------------|-----------|-------------|
| Category label | Heading-Text | `Node_Heading-Text_{UUID}.md` |
| Detailed analysis | Body-Text | `Node_Body-Text_{UUID}.md` |
| Quick note | Post-It | `Node_Post-It_{UUID}.md` |
| Visual reference | Image | `Node_Image_{UUID}.md` |
| Critical observation | Memo | `Node_Memo_{UUID}.md` |
| Comparison table | Data-Sheet | `Node_Data-Sheet_{UUID}.md` |

### Phase 4: Grouping

Group 3+ related nodes with color coding:
- Red `#FF6B6B`: Primary category
- Teal `#4ECDC4`: Secondary category
- Yellow `#F7DC6F`: Highlights
- Green `#98D8C8`: Completed/validated

### Phase 5: Connections

**Directory**: `Docs/Brain/{fileName}_Connections/`

- `arrow`: Directional (cause → effect)
- `normal`: Bi-directional (association)
- Positions: `top`, `bottom`, `left`, `right`

### Phase 6: Finalization

1. **Verify fileName match** (CRITICAL)
2. Update canvas metadata with all node_ids
3. Verify directory structure
4. Output summary with fileName verification

## Integration with Aesthetic Skills

| Aesthetic Skill | Brain Output |
|-----------------|--------------|
| `aesthetic-cultural-research` | Image + Memo nodes |
| `aesthetic-critic-historian` | Memo nodes |
| `aesthetic-form-composition` | Memo nodes |
| `aesthetic-motion-temporal` | Memo nodes |
| `aesthetic-pattern-miner` | Data-Sheet nodes |

## Positioning Strategy (⚠️ Prevent Node Overlap)

**Grid-Based Layout - Use this formula:**
```
Position X = COLUMN × 350
Position Y = ROW × 250
```

**Example:**
```yaml
Node 1: position: { x: 0, y: 0 }
Node 2: position: { x: 350, y: 0 }
Node 3: position: { x: 0, y: 250 }
```

## Best Practices

- Max 50 nodes per canvas for performance
- Use kebab-case for canvas names (safest approach)
- Always create nodes in `Docs/Brain/` directory
- Use proper UUID format for node identification

## Relationship to Claude Code

In Claude Code, this workflow is available as the `brain-organizer` skill which can be invoked directly. For other AI tools, follow this guide manually when organizing information in Brain canvases.

---

## 🚨 FINAL REMINDER: 3 BLOCKING RULES

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ RULE #1: fileName MUST match folder names                   ┃
┃ RULE #2: Nodes MUST use grid positions (X=COL×350, Y=ROW×250)┃
┃ RULE #3: MUST print validation checklist after completion   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

VIOLATION = BROKEN CANVAS (0 nodes, overlapping nodes, unusable)
```

---
*Generated by Archon*