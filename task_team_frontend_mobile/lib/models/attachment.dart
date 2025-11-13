class Attachment {
  final String? attachmentId;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? size;
  final DateTime uploadedAt;
  final String? uploadedBy;

  Attachment({
    this.attachmentId,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.size,
    DateTime? uploadedAt,
    this.uploadedBy,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      attachmentId: json['attachment_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type'],
      size: json['size'] is num ? json['size'].toInt() : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachment_id': attachmentId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'size': size,
      'uploaded_at': uploadedAt.toIso8601String(),
      'uploaded_by': uploadedBy,
    };
  }

  @override
  String toString() {
    return 'Attachment(fileName:$attachmentId $fileName, fileUrl: $fileUrl)';
  }
}