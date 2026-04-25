class AlistFile {
  final String name;
  final bool isDir;
  final int size;
  final String modified;
  final String? thumb;
  final String parentPath;
  final String? sign;
  final FileType type;

  AlistFile({
    required this.name,
    required this.isDir,
    required this.size,
    required this.modified,
    this.thumb,
    required this.parentPath,
    this.sign,
    required this.type,
  });

  String get fullPath => parentPath == '/'
      ? '/$name'
      : '$parentPath/$name';

  factory AlistFile.fromJson(Map<String, dynamic> json, String parentPath) {
    final name = json['name'] as String? ?? '';
    final isDir = json['is_dir'] as bool? ?? false;
    return AlistFile(
      name: name,
      isDir: isDir,
      size: json['size'] as int? ?? 0,
      modified: json['modified'] as String? ?? '',
      thumb: json['thumb'] as String?,
      parentPath: parentPath,
      sign: json['sign'] as String?,
      type: isDir ? FileType.directory : _detectType(name),
    );
  }

  static FileType _detectType(String name) {
    final ext = name.toLowerCase().split('.').last;
    const videoExts = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'm4v', 'webm', 'ts', 'm2ts'];
    const audioExts = ['mp3', 'flac', 'aac', 'wav', 'ogg', 'm4a', 'opus'];
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic'];
    const docExts = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'md'];
    const archiveExts = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'];

    if (videoExts.contains(ext)) return FileType.video;
    if (audioExts.contains(ext)) return FileType.audio;
    if (imageExts.contains(ext)) return FileType.image;
    if (docExts.contains(ext)) return FileType.document;
    if (archiveExts.contains(ext)) return FileType.archive;
    return FileType.other;
  }

  String get formattedSize {
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum FileType { directory, video, audio, image, document, archive, other }

class FileDetail {
  final String name;
  final int size;
  final bool isDir;
  final String modified;
  final String? rawUrl;
  final String? thumb;
  final String? sign;
  final int hashInfoSha256;

  FileDetail({
    required this.name,
    required this.size,
    required this.isDir,
    required this.modified,
    this.rawUrl,
    this.thumb,
    this.sign,
    this.hashInfoSha256 = 0,
  });

  factory FileDetail.fromJson(Map<String, dynamic> json) {
    return FileDetail(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      isDir: json['is_dir'] as bool? ?? false,
      modified: json['modified'] as String? ?? '',
      rawUrl: json['raw_url'] as String?,
      thumb: json['thumb'] as String?,
      sign: json['sign'] as String?,
    );
  }
}
