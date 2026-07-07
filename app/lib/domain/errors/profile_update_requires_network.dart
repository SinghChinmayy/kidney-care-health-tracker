class ProfileUpdateRequiresNetworkException implements Exception {
  const ProfileUpdateRequiresNetworkException();

  static const message =
      'Profile updates require an internet connection. Please try again when online.';

  @override
  String toString() => message;
}
