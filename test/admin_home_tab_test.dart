import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/presentation/admin/pages/admin_home_tab.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => const UserEntity(
    id: 'admin-1',
    email: 'admin@casppa.dev',
    name: 'Ada Okoro',
    role: UserRole.admin,
  );
}

void main() {
  testWidgets('renders the overview grid without layout errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          adminOverviewProvider.overrideWith(
            (ref) async => const AdminOverviewEntity(
              subjectCount: 5,
              classCount: 12,
              studentCount: 340,
              teacherCount: 18,
            ),
          ),
        ],
        child: MaterialApp(
          home: AdminHomeTab(onNavigateToTab: (_) {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
  });

  testWidgets('renders the loading skeleton without layout errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          adminOverviewProvider.overrideWith(
            (ref) => Completer<AdminOverviewEntity>().future,
          ),
        ],
        child: MaterialApp(
          home: AdminHomeTab(onNavigateToTab: (_) {}),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
