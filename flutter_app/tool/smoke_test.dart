import 'package:supabase/supabase.dart';

Future<void> main() async {
  final client = SupabaseClient(
    'http://127.0.0.1:54321',
    'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  final email = 'smoke_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final signUpRes = await client.auth.signUp(email: email, password: 'password123');
  print('Signed up: ${signUpRes.user?.id}, session: ${signUpRes.session != null}');

  // bootstrap trigger should have created a bare patients row already
  final row = await client.from('patients').select().eq('auth_user_id', signUpRes.user!.id).single();
  print('Bootstrap row: $row');
  assert(row['full_name'] == null);

  // onboarding update
  final updated = await client
      .from('patients')
      .update({'full_name': 'Test Patient', 'sex': 'female', 'ckd_stage': 'stage_3a'})
      .eq('auth_user_id', signUpRes.user!.id)
      .select()
      .single();
  print('After onboarding update: $updated');
  assert(updated['full_name'] == 'Test Patient');

  // RLS check: a second, unrelated user must NOT see this patient row
  final client2 = SupabaseClient(
    'http://127.0.0.1:54321',
    'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final email2 = 'smoke2_${DateTime.now().millisecondsSinceEpoch}@example.com';
  await client2.auth.signUp(email: email2, password: 'password123');
  final otherPatients = await client2.from('patients').select();
  print('User2 sees ${otherPatients.length} patients (should be 1, only their own)');
  assert(otherPatients.length == 1);

  print('SMOKE TEST PASSED');
}
