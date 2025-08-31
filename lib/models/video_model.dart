class VideoModel {
  final int id;
  final int medicineId;
  final String fileName;
  final String fileUrl;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.medicineId,
    required this.fileName,
    required this.fileUrl,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      medicineId: json['medicineId'],
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
