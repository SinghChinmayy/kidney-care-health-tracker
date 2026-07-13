class Medication {
  const Medication({
    required this.id,
    required this.pharmaceuticalName,
    required this.composition,
    required this.about,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String pharmaceuticalName;
  final String composition;
  final String about;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
