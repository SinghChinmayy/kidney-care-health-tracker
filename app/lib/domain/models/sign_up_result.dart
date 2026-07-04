enum SignUpStatus {
  sessionCreated,
  emailConfirmationRequired,
}

class SignUpResult {
  const SignUpResult({required this.status});

  final SignUpStatus status;

  bool get hasSession => status == SignUpStatus.sessionCreated;

  bool get needsEmailConfirmation =>
      status == SignUpStatus.emailConfirmationRequired;
}
