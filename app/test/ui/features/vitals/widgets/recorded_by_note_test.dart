import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:app/ui/features/vitals/widgets/recorded_by_note.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_forms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recorded-by label distinguishes self, named member, unknown', () {
    expect(
      RecordedByNote.labelFor(recordedBy: null, currentUserId: 'me'),
      isNull,
    );
    expect(
      RecordedByNote.labelFor(recordedBy: 'me', currentUserId: 'me'),
      'Logged by you',
    );
    expect(
      RecordedByNote.labelFor(
        recordedBy: 'other',
        currentUserId: 'me',
        memberName: '@carol',
      ),
      'Logged by @carol',
    );
    expect(
      RecordedByNote.labelFor(recordedBy: 'other', currentUserId: 'me'),
      'Logged by another member',
    );
  });

  test('glucose context offers before_meal', () {
    expect(bloodGlucoseContextOptions, contains('before_meal'));
    expect(formatBloodGlucoseContextLabel('before_meal'), 'Before meal');
  });
}
