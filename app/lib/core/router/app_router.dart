import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/checklist/views/checklist_screen.dart';
import '../../features/finance/views/finance_screen.dart';
import '../../features/timeline/views/completed_trip_detail_screen.dart';
import '../../features/timeline/views/timeline_event_detail_screen.dart';
import '../../features/timeline/views/timeline_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// Route paths
const String kChecklistPath = '/checklist';
const String kTimelinePath = '/timeline';
const String kFinancePath = '/finance';
const String kTimelineDetailPath = 'detail/:eventId';
const String kCompletedTripPath = 'completed/:tripId';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: kTimelinePath,
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0 — Checklist (left tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kChecklistPath,
                builder: (context, state) => const ChecklistScreen(),
              ),
            ],
          ),

          // Branch 1 — Timeline (centre tab, default)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kTimelinePath,
                builder: (context, state) => const TimelineScreen(),
                routes: [
                  GoRoute(
                    path: kTimelineDetailPath,
                    builder: (context, state) => TimelineEventDetailScreen(
                      eventId: state.pathParameters['eventId']!,
                    ),
                  ),
                  GoRoute(
                    path: kCompletedTripPath,
                    builder: (context, state) => CompletedTripDetailScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2 — Finance (right tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kFinancePath,
                builder: (context, state) => const FinanceScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
