import 'package:flutter/foundation.dart';

/// Fires when the active patient changes or the set of accessible patients
/// changes (switch, create, grant, revoke). Screens refresh on it.
///
/// Deliberately not a [Listenable] itself: it is provided with a plain
/// `Provider`, so dependent proxy providers (sync engine, coordinator,
/// repositories) are not rebuilt every time the patient changes. Listeners
/// subscribe explicitly via [addListener].
class ActivePatientNotifier {
  final ValueNotifier<int> _revision = ValueNotifier(0);

  int get revision => _revision.value;

  ValueListenable<int> get changes => _revision;

  void markChanged() => _revision.value++;

  void addListener(VoidCallback listener) => _revision.addListener(listener);

  void removeListener(VoidCallback listener) =>
      _revision.removeListener(listener);

  void dispose() => _revision.dispose();
}
