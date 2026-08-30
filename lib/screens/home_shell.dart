import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'feed_screen.dart';
import 'garage_screen.dart';
import 'crew_screen.dart';
import 'notifications_screen.dart';

/// Hosts the four "home base" tabs — Feed / Garage / Crew / Notifications —
/// behind a single persistent Scaffold + AppBottomNav.
///
/// Previously each tab was its own route, and AppBottomNav switched tabs
/// with Navigator.pushReplacementNamed. That tore down and rebuilt the
/// entire screen (including the nav bar itself) on every tap, which is
/// what read as a "flash". Here, all four screens are built once and kept
/// alive in an IndexedStack; tapping a tab just changes which one is
/// visible, so the nav bar — and everything else — never rebuilds.
///
/// Wire your app's root/login flow to push/show this shell instead of
/// pushing the feed/garage/crew/notifications routes directly. If other
/// screens still need to navigate to a specific tab (e.g. after sending
/// a crew invite, jump to Crew), either:
///   - pass an `initialIndex` when you first build HomeShell, or
///   - expose a static `HomeShell.of(context)?.goToTab(index)` helper
///     backed by an InheritedWidget/controller, if you need to jump tabs
///     from deep inside the tree after the shell is already showing.
class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  // const so Flutter never rebuilds these unless their own internal state
  // changes — IndexedStack just toggles which one is laid out/painted.
  static const _tabs = [
    FeedScreen(),
    GarageScreen(),
    CrewScreen(),
    NotificationsScreen(),
  ];

  void _onTabTapped(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _onTabTapped,
      ),
    );
  }
}
