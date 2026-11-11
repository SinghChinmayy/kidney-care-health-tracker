import 'package:flutter/foundation.dart';

/// Fires when the active patient changes or the set of accessible patients
/// changes (switch, create, grant, revoke). Screens refresh on it.
class ActivePatientNotifier extends ChangeNotifier {
  int _revision = 0;

  int get revision => _revision;

  void markChanged() {
    _revision++;
    notifyListeners();
  }
}
