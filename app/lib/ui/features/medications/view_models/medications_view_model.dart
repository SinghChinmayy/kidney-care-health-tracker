import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class MedicationsViewModel extends ChangeNotifier {
  MedicationsViewModel({required MedicationsRepository medicationsRepository})
      : _medicationsRepository = medicationsRepository {
    refresh();
  }

  final MedicationsRepository _medicationsRepository;
  static const _uuid = Uuid();

  List<Medication> _medications = [];
  String _query = '';
  bool _isLoading = true;
  String? _error;

  List<Medication> get medications {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return _medications;
    }
    return _medications.where((m) {
      return m.pharmaceuticalName.toLowerCase().contains(q) ||
          m.composition.toLowerCase().contains(q) ||
          m.about.toLowerCase().contains(q);
    }).toList();
  }

  String get query => _query;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isEmpty => !_isLoading && _error == null && medications.isEmpty;

  void setQuery(String value) {
    if (_query == value) {
      return;
    }
    _query = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medications = await _medicationsRepository.getAll();
    } catch (e) {
      _error = 'Could not load medications.';
      _medications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication({
    required String pharmaceuticalName,
    required String composition,
    required String about,
  }) async {
    final now = DateTime.now().toUtc();
    await _medicationsRepository.add(
      Medication(
        id: _uuid.v4(),
        pharmaceuticalName: pharmaceuticalName.trim(),
        composition: composition.trim(),
        about: about.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await refresh();
  }
}
