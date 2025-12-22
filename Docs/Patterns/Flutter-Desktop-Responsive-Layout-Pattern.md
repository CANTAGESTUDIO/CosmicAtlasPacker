# 📐 Flutter Desktop Responsive Layout Pattern

> Adaptive layouts for different window sizes

---

## Overview

Responsive layout system that adapts to different window sizes and user preferences.

---

## Implementation

### 1. Breakpoint Definitions

```dart
// core/layout/breakpoints.dart
class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
  static const double large = 1600;

  static LayoutType getLayoutType(double width) {
    if (width < compact) return LayoutType.compact;
    if (width < medium) return LayoutType.medium;
    if (width < expanded) return LayoutType.expanded;
    return LayoutType.large;
  }
}

enum LayoutType {
  compact,
  medium,
  expanded,
  large,
}
```

### 2. Responsive Builder

```dart
// widgets/responsive_builder.dart
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, LayoutType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutType = Breakpoints.getLayoutType(constraints.maxWidth);
        return builder(context, layoutType);
      },
    );
  }
}

// Usage
ResponsiveBuilder(
  builder: (context, layoutType) {
    switch (layoutType) {
      case LayoutType.compact:
        return CompactLayout();
      case LayoutType.medium:
        return MediumLayout();
      case LayoutType.expanded:
      case LayoutType.large:
        return ExpandedLayout();
    }
  },
)
```

### 3. Adaptive Scaffold

```dart
// widgets/adaptive_scaffold.dart
class AdaptiveScaffold extends StatelessWidget {
  final Widget? sidebarContent;
  final Widget body;
  final Widget? secondaryBody;
  final double sidebarWidth;
  final double secondaryBodyWidth;

  const AdaptiveScaffold({
    super.key,
    this.sidebarContent,
    required this.body,
    this.secondaryBody,
    this.sidebarWidth = 240,
    this.secondaryBodyWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, layoutType) {
        final showSidebar = layoutType != LayoutType.compact;
        final showSecondary = layoutType == LayoutType.large;

        return Row(
          children: [
            if (showSidebar && sidebarContent != null)
              SizedBox(
                width: sidebarWidth,
                child: sidebarContent,
              ),
            Expanded(child: body),
            if (showSecondary && secondaryBody != null)
              SizedBox(
                width: secondaryBodyWidth,
                child: secondaryBody,
              ),
          ],
        );
      },
    );
  }
}
```

### 4. Master-Detail Layout

```dart
// widgets/master_detail_layout.dart
class MasterDetailLayout<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, bool isSelected) masterBuilder;
  final Widget Function(T item) detailBuilder;
  final Widget emptyDetailBuilder;

  const MasterDetailLayout({
    super.key,
    required this.items,
    required this.masterBuilder,
    required this.detailBuilder,
    required this.emptyDetailBuilder,
  });

  @override
  State<MasterDetailLayout<T>> createState() => _MasterDetailLayoutState<T>();
}

class _MasterDetailLayoutState<T> extends State<MasterDetailLayout<T>> {
  T? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, layoutType) {
        if (layoutType == LayoutType.compact) {
          // Stack navigation on small screens
          if (_selectedItem != null) {
            return WillPopScope(
              onWillPop: () async {
                setState(() => _selectedItem = null);
                return false;
              },
              child: widget.detailBuilder(_selectedItem as T),
            );
          }
          return _buildMasterList();
        }

        // Side-by-side on larger screens
        return Row(
          children: [
            SizedBox(
              width: 320,
              child: _buildMasterList(),
            ),
            Expanded(
              child: _selectedItem != null
                  ? widget.detailBuilder(_selectedItem as T)
                  : widget.emptyDetailBuilder,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasterList() {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedItem = item),
          child: widget.masterBuilder(item, item == _selectedItem),
        );
      },
    );
  }
}
```

---

## Best Practices

1. **Minimum Window Size**: Set appropriate minimum window size
2. **Resizable Panels**: Allow users to resize panels
3. **Collapsible Sidebar**: Support collapsed sidebar state
4. **Persistent Layout**: Remember user's layout preferences
5. **Smooth Transitions**: Animate layout changes

---

*Generated by Archon*