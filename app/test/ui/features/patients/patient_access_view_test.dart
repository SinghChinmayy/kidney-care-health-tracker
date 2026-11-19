import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:app/ui/features/patients/views/patient_access_view.dart';
import 'package:app/ui/features/vitals/widgets/recorded_by_note.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_patient_access_remote.dart';

void main() {
  late AppDatabase db;
  late FakePatientAccessRemote remote;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakePatientAccessRemote(me: 'me')
      ..usernames.addAll({
        'me': 'mia',
        'gran': 'gran',
        'carer': 'carl',
        'newbie': 'nina',
      });
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, PatientRole myRole) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final patient = AccessiblePatient(
      patient: const Patient(id: 'p-1', firstName: 'Gran'),
      role: myRole,
      isSelf: false,
    );
    await tester.pumpWidget(
      Provider<SharingRepository>.value(
        value: SharingRepository(
          db: db,
          remote: remote,
          currentAuthUserId: () => 'me',
        ),
        child: MaterialApp(home: PatientAccessView(patient: patient)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('owner sees members, grants by username, edits roles',
      (tester) async {
    remote.addMember('p-1', 'gran', PatientRole.owner, isPatient: true);
    remote.addMember('p-1', 'me', PatientRole.owner);
    remote.addMember('p-1', 'carer', PatientRole.viewer);
    await pump(tester, PatientRole.owner);

    expect(find.text('@mia'), findsWidgets);
    expect(find.text('@carl'), findsOneWidget);
    expect(find.text('ADD PERSON'), findsOneWidget);
    // The patient's own account and the owner themself are not editable.
    expect(find.byType(PopupMenuButton<Object>), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('grant-username')), 'NINA');
    await tester.tap(find.text('Viewer').last);
    await tester.ensureVisible(find.byKey(const ValueKey('grant-submit')));
    await tester.tap(find.byKey(const ValueKey('grant-submit')));
    await tester.pumpAndSettle();
    expect(remote.calls, contains('grant:p-1:nina:viewer'));
    expect(find.text('@nina'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('grant-username')), 'ghost');
    await tester.tap(find.byKey(const ValueKey('grant-submit')));
    await tester.pumpAndSettle();
    expect(find.text('No one has that username.'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<Object>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caregiver').last);
    await tester.pumpAndSettle();
    expect(remote.calls, contains('change:p-1:carer:caregiver'));
  });

  testWidgets('viewer sees a read-only list and can leave', (tester) async {
    remote.addMember('p-1', 'gran', PatientRole.owner, isPatient: true);
    remote.addMember('p-1', 'me', PatientRole.viewer);
    await pump(tester, PatientRole.viewer);

    expect(find.text('ADD PERSON'), findsNothing);
    expect(find.byType(PopupMenuButton<Object>), findsNothing);
    expect(find.textContaining('You have viewer access'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('leave-patient')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(remote.calls, contains('revoke:p-1:me'));
  });

  testWidgets('sole owner of a dependant cannot leave', (tester) async {
    remote.addMember('p-1', 'me', PatientRole.owner);
    await pump(tester, PatientRole.owner);

    expect(find.byKey(const ValueKey('leave-patient')), findsNothing);
  });

  testWidgets('"logged by" resolves another member\'s username',
      (tester) async {
    remote.addMember('p-1', 'me', PatientRole.caregiver);
    remote.addMember('p-1', 'carer', PatientRole.caregiver);
    await tester.pumpWidget(
      Provider<SharingRepository>.value(
        value: SharingRepository(
          db: db,
          remote: remote,
          currentAuthUserId: () => 'me',
        ),
        child: const MaterialApp(
          home: Scaffold(
            body: RecordedByNote(
              recordedBy: 'carer',
              currentUserId: 'me',
              patientId: 'p-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Logged by @carl'), findsOneWidget);
  });

  testWidgets('"logged by" works without a sharing provider', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecordedByNote(
            recordedBy: 'carer',
            currentUserId: 'me',
            patientId: 'p-1',
          ),
        ),
      ),
    );
    expect(find.text('Logged by another member'), findsOneWidget);
  });
}
