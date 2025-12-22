# 🧭 Flutter Desktop Navigation Pattern

> go_router with desktop-specific layouts and navigation

---

## Overview

Navigation patterns optimized for desktop applications with sidebar, tabs, and multiple panes.

---

## Dependencies

```yaml
dependencies:
  go_router: ^13.2.0
```

---

## Implementation

### 1. Router Configuration

```dart
// core/navigation/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return DesktopShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/documents',
            name: 'documents',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DocumentsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'document-detail',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: DocumentDetailScreen(id: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'general',
                name: 'settings-general',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const GeneralSettingsScreen(),
                ),
              ),
              GoRoute(
                path: 'appearance',
                name: 'settings-appearance',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AppearanceSettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

### 2. Desktop Shell with Sidebar

```dart
// widgets/desktop_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;

  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: 240,
          child: NavigationSidebar(),
        ),
        // Main content
        Expanded(child: child),
      ],
    );
  }
}

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Navigation items
          NavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: currentPath == '/home',
            onTap: () => context.go('/home'),
          ),
          NavItem(
            icon: Icons.folder,
            label: 'Documents',
            isSelected: currentPath.startsWith('/documents'),
            onTap: () => context.go('/documents'),
          ),
          const Spacer(),
          NavItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: currentPath.startsWith('/settings'),
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
```

### 3. Tabbed Navigation

```dart
// widgets/tabbed_view.dart
class TabbedDocumentView extends ConsumerWidget {
  const TabbedDocumentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openDocuments = ref.watch(openDocumentsProvider);
    final activeDocumentId = ref.watch(activeDocumentIdProvider);

    return Column(
      children: [
        // Tab bar
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openDocuments.length,
            itemBuilder: (context, index) {
              final doc = openDocuments[index];
              final isActive = doc.id == activeDocumentId;

              return DocumentTab(
                document: doc,
                isActive: isActive,
                onTap: () => ref.read(activeDocumentIdProvider.notifier)
                    .setActive(doc.id),
                onClose: () => ref.read(openDocumentsProvider.notifier)
                    .close(doc.id),
              );
            },
          ),
        ),
        // Content
        Expanded(
          child: activeDocumentId != null
              ? DocumentEditor(documentId: activeDocumentId)
              : const EmptyState(),
        ),
      ],
    );
  }
}
```

---

## Best Practices

1. **No Transitions**: Use NoTransitionPage for instant navigation
2. **Persistent Sidebar**: Keep navigation visible
3. **Breadcrumbs**: Show current location in hierarchy
4. **Tab Management**: Support multiple open documents
5. **Deep Linking**: Support direct URL navigation

---

*Generated by Archon*