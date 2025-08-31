class Datasheet {
  final int id;
  final int? medicineId; // peut être null
  final String fileName;
  final String fileUrl;
  final DateTime createdAt;

  Datasheet({
    required this.id,
    required this.medicineId,
    required this.fileName,
    required this.fileUrl,
    required this.createdAt,
  });

  factory Datasheet.fromJson(Map<String, dynamic> json) {
    return Datasheet(
      id: json["id"],
      medicineId: json["medicineId"], // parfois null
      fileName: json["fileName"],
      fileUrl: json["fileUrl"],
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
