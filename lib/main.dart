import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vol_hub/core/theme.dart';
import 'package:vol_hub/router.dart';

void main() {
  runApp(const ProviderScope(child: VolHubApp()));
}

class VolHubApp extends StatelessWidget {
  const VolHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VolHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // Basic adaptive layout
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Bottom Navigation Bar (using NavigationBar for M3)
          return Scaffold(
            body: child,
            bottomNavigationBar: VolHubBottomBar(child: child),
          );
        } else {
          // Tablet/Desktop: Navigation Rail (Sidebar)
          return Scaffold(
            body: Row(
              children: [
                VolHubNavRail(child: child),
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }
}

class VolHubBottomBar extends StatelessWidget {
  final Widget child;
  const VolHubBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    int getIndex() {
       if (location == '/') return 0;
       if (location.startsWith('/teams')) return 1;
       if (location.startsWith('/recruit')) return 2;
       if (location.startsWith('/messages')) return 3;
       if (location.startsWith('/profile')) return 4;
       return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/teams'); break;
        case 2: context.go('/recruit'); break;
        case 3: context.go('/messages'); break;
        case 4: context.go('/profile'); break;
      }
    }

    // Material 3 NavigationBar
    return NavigationBar(
      selectedIndex: getIndex() > 4 ? 0 : getIndex(), // Handle overflow safely
      onDestinationSelected: onItemTapped,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dash'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Teams'),
        NavigationDestination(icon: Icon(Icons.person_search_outlined), label: 'Recruit'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class VolHubNavRail extends StatelessWidget {
  final Widget child;
  const VolHubNavRail({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    int getIndex() {
       if (location == '/') return 0;
       if (location.startsWith('/teams')) return 1;
       if (location.startsWith('/recruit')) return 2;
       if (location.startsWith('/marketplace')) return 3;
       if (location.startsWith('/proposals')) return 4;
       if (location.startsWith('/messages')) return 5;
       if (location.startsWith('/portfolio')) return 6;
       if (location.startsWith('/profile')) return 7;
       return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0: context.go('/'); break;
        case 1: context.go('/teams'); break;
        case 2: context.go('/recruit'); break;
        case 3: context.go('/marketplace'); break;
        case 4: context.go('/proposals'); break;
        case 5: context.go('/messages'); break;
        case 6: context.go('/portfolio'); break;
        case 7: context.go('/profile'); break;
      }
    }

    return NavigationRail(
      selectedIndex: getIndex(),
      onDestinationSelected: onItemTapped,
      labelType: NavigationRailLabelType.all,
      extended: false, // Could be collapsible
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.groups_outlined), label: Text('Teams')),
        NavigationRailDestination(icon: Icon(Icons.person_search_outlined), label: Text('Recruit')),
        NavigationRailDestination(icon: Icon(Icons.storefront_outlined), label: Text('Market')),
        NavigationRailDestination(icon: Icon(Icons.description_outlined), label: Text('Proposals')),
        NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Messages')),
        NavigationRailDestination(icon: Icon(Icons.work_outline), label: Text('Portfolio')),
        NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
      ],
    );
  }
}
