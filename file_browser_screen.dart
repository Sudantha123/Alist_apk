import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/file_model.dart';
import '../models/server_config.dart';
import '../services/alist_service.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';
import 'image_viewer_screen.dart';

class FileBrowserScreen extends StatefulWidget {
  final ServerConfig server;
  final String path;

  const FileBrowserScreen({
    super.key,
    required this.server,
    this.path = '/',
  });

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<AlistFile> _files = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';
  bool _isGridView = false;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final files = await AlistService().listFiles(widget.path);
      files.sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMsg = e.toString();
      });
    }
  }

  void _onFileTap(AlistFile file) {
    if (file.isDir) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileBrowserScreen(
            server: widget.server,
            path: file.fullPath,
          ),
        ),
      );
      return;
    }

    switch (file.type) {
      case FileType.video:
        final url = AlistService().getStreamUrl(file.fullPath);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              url: url,
              title: file.name,
            ),
          ),
        );
        break;
      case FileType.image:
        final url = AlistService().getDownloadUrl(file.fullPath);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(url: url, title: file.name),
          ),
        );
        break;
      default:
        _showFileOptions(file);
    }
  }

  void _showFileOptions(AlistFile file) {
    final url = AlistService().getDownloadUrl(file.fullPath);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _fileIcon(file, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        file.formattedSize,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.divider),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppTheme.primary),
              title: const Text('File Info', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(url, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = widget.path == '/';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: isRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRoot ? widget.server.name : _folderName(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isRoot)
              Text(
                widget.path,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  String _folderName() {
    final parts = widget.path.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => 'Root');
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    if (_files.isEmpty) return _buildEmptyState();
    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Loading files...',
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFiles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Empty folder', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadFiles,
      color: AppTheme.primary,
      backgroundColor: AppTheme.cardColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _files.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) => _buildListTile(_files[i]),
      ),
    );
  }

  Widget _buildListTile(AlistFile file) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onFileTap(file),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _fileIcon(file, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (file.formattedSize.isNotEmpty) ...[
                          Text(
                            file.formattedSize,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppTheme.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            _formatDate(file.modified),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (file.isDir)
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20)
              else
                _buildFileTypeChip(file),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: _loadFiles,
      color: AppTheme.primary,
      backgroundColor: AppTheme.cardColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _files.length,
        itemBuilder: (_, i) => _buildGridItem(_files[i]),
      ),
    );
  }

  Widget _buildGridItem(AlistFile file) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onFileTap(file),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _fileIcon(file, size: 48),
              const SizedBox(height: 8),
              Text(
                file.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (file.formattedSize.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  file.formattedSize,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileIcon(AlistFile file, {double size = 40}) {
    if (file.type == FileType.image && file.thumb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: file.thumb!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _iconBox(Icons.image_rounded, AppTheme.secondary, size),
          errorWidget: (_, __, ___) => _iconBox(Icons.image_rounded, AppTheme.secondary, size),
        ),
      );
    }

    switch (file.type) {
      case FileType.directory:
        return _iconBox(Icons.folder_rounded, const Color(0xFFFFB74D), size);
      case FileType.video:
        return _iconBox(Icons.play_circle_filled_rounded, AppTheme.primary, size);
      case FileType.audio:
        return _iconBox(Icons.music_note_rounded, AppTheme.secondary, size);
      case FileType.image:
        return _iconBox(Icons.image_rounded, const Color(0xFF4CAF50), size);
      case FileType.document:
        return _iconBox(Icons.description_rounded, AppTheme.accent, size);
      case FileType.archive:
        return _iconBox(Icons.folder_zip_rounded, const Color(0xFF9C27B0), size);
      default:
        return _iconBox(Icons.insert_drive_file_rounded, AppTheme.textSecondary, size);
    }
  }

  Widget _iconBox(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }

  Widget _buildFileTypeChip(AlistFile file) {
    Color color;
    String label;
    switch (file.type) {
      case FileType.video:
        color = AppTheme.primary;
        label = 'Video';
        break;
      case FileType.audio:
        color = AppTheme.secondary;
        label = 'Audio';
        break;
      case FileType.image:
        color = const Color(0xFF4CAF50);
        label = 'Image';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate.substring(0, 10.clamp(0, isoDate.length));
    }
  }
}
