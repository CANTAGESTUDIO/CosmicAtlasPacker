# Components

> UI component specifications, variants, and usage guidelines.

---

## Global Design Tokens

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-none` | 0px | No rounding |
| `radius-sm` | 2px | Tags, badges |
| `radius-md` | 4px | Buttons, inputs, cards, dialogs |
| `radius-lg` | 6px | Panels, modals (legacy) |

**Note**: 대부분의 UI 요소는 `4px` radius를 사용. 과도한 라운딩 지양.

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4px | Tight spacing |
| `space-2` | 8px | Default gap |
| `space-3` | 12px | Section gap |
| `space-4` | 16px | Large gap |
| `space-5` | 20px | Panel padding |

---

## Button

### Variants

| Variant | Background | Text | Border | Usage |
|---------|------------|------|--------|-------|
| Primary (Filled) | `primary` | White | None | Main actions (Export, Apply) |
| Secondary (Text) | Transparent | `iconDefault` | None | Cancel, secondary actions |
| Ghost | Transparent | `iconDisabled` | None | Subtle actions |

### Sizes

| Size | Height | Padding | Font Size | Border Radius |
|------|--------|---------|-----------|---------------|
| Small | 28px | 8px 12px | 11px | 4px |
| Medium | 32px | 10px 16px | 12px | 4px |

### Button Style Code

```dart
// Primary (Filled) Button
FilledButton.styleFrom(
  padding: EdgeInsets.symmetric(horizontal: 16),
  minimumSize: Size(0, 32),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
  ),
)

// Secondary (Text) Button
TextButton.styleFrom(
  padding: EdgeInsets.symmetric(horizontal: 12),
  minimumSize: Size(0, 32),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
  ),
)
```

---

## Input / TextField

### Variants

| Variant | Border | Background | Usage |
|---------|--------|------------|-------|
| Default | `border` (default), `primary` (focus) | `inputBackground` | Standard inputs |
| Error | `error` | `inputBackground` | Validation errors |

### Sizes

| Size | Height | Font Size | Padding | Usage |
|------|--------|-----------|---------|-------|
| Small | 24px | 11px | 6px horizontal | Compact fields (number inputs) |
| Medium | 28px | 11px | 8px horizontal, 8px vertical | Standard text fields |

### TextField Component Code (EditorTextField)

**중요**: 모든 입력 필드는 이 표준 컴포넌트를 사용해야 합니다.

```dart
/// 에디터 전용 텍스트필드 - 키보드 단축키 충돌 방지 포함
class EditorTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final bool hasError;
  final String? errorText;

  const EditorTextField({
    super.key,
    this.controller,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.keyboardType,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Prevent keyboard shortcuts from intercepting input
      onKeyEvent: (node, event) => KeyEventResult.skipRemainingHandlers,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 11,
          color: EditorColors.iconDefault,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          filled: true,
          fillColor: EditorColors.inputBackground,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(
              color: hasError ? EditorColors.error : EditorColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(
              color: hasError ? EditorColors.error : EditorColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(
              color: hasError ? EditorColors.error : EditorColors.primary,
            ),
          ),
          errorText: errorText,
          errorStyle: const TextStyle(fontSize: 10),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
```

### 핵심 사항

1. **키보드 단축키 충돌 방지**: `Focus` 위젯으로 감싸서 `onKeyEvent`에서 `KeyEventResult.skipRemainingHandlers` 반환
2. **일관된 스타일**: 모든 입력 필드에 동일한 `fontSize: 11`, `contentPadding`, `borderRadius: 3` 적용
3. **포커스 표시**: 포커스 시 `primary` 색상 테두리
4. **에러 상태**: `hasError: true` 시 빨간색 테두리

### 사용 예시

```dart
// 다이얼로그에서 사용
EditorTextField(
  hintText: 'sprite',
  initialValue: _idPrefix,
  onChanged: (value) => _idPrefix = value,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
  ],
)

// 숫자 입력
EditorTextField(
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  onSubmitted: (value) => _onValueChanged(),
)
```

---

## Toggle / Switch

### Specifications

| Property | Value |
|----------|-------|
| Scale | 0.65 (compact) |
| Active thumb | `primary` |
| Active track | `primary` @ 50% |
| Inactive thumb | `iconDisabled` (NOT white) |
| Inactive track | `border` |
| Border | None |

### Switch Style Code

```dart
SizedBox(
  height: 20,
  child: Transform.scale(
    scale: 0.65,
    child: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: EditorColors.primary,
      activeTrackColor: EditorColors.primary.withValues(alpha: 0.5),
      inactiveThumbColor: EditorColors.iconDisabled,
      inactiveTrackColor: EditorColors.border,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  ),
)
```

---

## Slider

### Specifications

| Property | Value |
|----------|-------|
| Track height | 2px |
| Thumb radius | 5px (enabled) |
| Overlay radius | 10px |
| Active color | `primary` |
| Inactive color | `border` |

### Slider Style Code

```dart
SliderTheme(
  data: SliderTheme.of(context).copyWith(
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
    trackHeight: 2,
    activeTrackColor: EditorColors.primary,
    inactiveTrackColor: EditorColors.border,
    thumbColor: EditorColors.primary,
  ),
  child: Slider(...),
)
```

---

## Dialog / Modal

### Specifications

| Property | Value |
|----------|-------|
| Border radius | 4px |
| Background | `surface` |
| Header height | 48px |
| Header background | `panelBackground` |
| Content padding | 16px 20px |
| Action padding | 12px 20px 16px |

### Sizes

| Size | Width | Use Case |
|------|-------|----------|
| Small | 320px | Confirmations |
| Medium | 380px | Settings dialogs |
| Large | 500px | Complex forms |

### Dialog Structure

```
┌────────────────────────────────────┐  <- radius: 4px
│  Header Title                      │  <- height: 48px, bg: panelBackground
├────────────────────────────────────┤
│                                    │
│  Content                           │  <- padding: 16px 20px
│                                    │
├────────────────────────────────────┤
│               [Cancel]  [Apply]    │  <- padding: 12px 20px 16px
└────────────────────────────────────┘
```

### Dialog Style Code

```dart
Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
  ),
  backgroundColor: EditorColors.surface,
  child: Column(
    children: [
      // Header
      Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: EditorColors.panelBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
        child: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Spacer(),
            // Close button (optional)
          ],
        ),
      ),
      // Content
      Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: content,
      ),
      // Actions
      Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(child: Text('취소')),
            SizedBox(width: 8),
            FilledButton(child: Text('적용')),
          ],
        ),
      ),
    ],
  ),
)
```

---

## Color Picker / Swatch

### Specifications

| Property | Value |
|----------|-------|
| Swatch size | 28px |
| Border radius | 3px |
| Selected border | 2px `primary` |
| Unselected border | None (transparent) |

### Color Swatch Code

```dart
Container(
  width: 28,
  height: 28,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(3),
    border: Border.all(
      color: isSelected ? EditorColors.primary : Colors.transparent,
      width: 2,
    ),
  ),
)
```

---

## Option Button (Radio-like)

### Specifications

| Property | Value |
|----------|-------|
| Height | 32px |
| Padding | 12px horizontal, 8px vertical |
| Border radius | 4px |
| Selected background | `primary` @ 15% |
| Unselected background | `inputBackground` |
| Border | None |

### Option Button Code

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: isSelected
        ? EditorColors.primary.withValues(alpha: 0.15)
        : EditorColors.inputBackground,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Row(
    children: [
      Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 14,
        color: isSelected ? EditorColors.primary : EditorColors.iconDisabled,
      ),
      SizedBox(width: 6),
      Text(label),
    ],
  ),
)
```

---

## Section Header

### Specifications

| Property | Value |
|----------|-------|
| Font size | 12px |
| Font weight | w600 |
| Color | `iconDefault` |
| Margin bottom | 8px |

```dart
Text(
  title,
  style: TextStyle(
    fontSize: 12,
    color: EditorColors.iconDefault,
    fontWeight: FontWeight.w600,
  ),
)
```

---

## Card / Panel

### Specifications

| Property | Value |
|----------|-------|
| Border radius | 4px |
| Background | `panelBackground` |
| Border | None (default), 1px `border` (optional) |
| Padding | 12px |

---

*Last updated: 2024-12-23*
