import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UFileItem {
  final String name;
  final String path;
  final String type;
  final int? size;
  final DateTime modified;

  UFileItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    required this.modified,
  });

  static fromJson(item) {
    return UFileItem(
      name: item['name'],
      path: item['path'],
      type: item['type'],
      size: item['size'],
      modified: DateTime.parse(item['modified']),
    );
  }
}

class UFileListWidget extends StatefulWidget {
  const UFileListWidget({
    super.key,
    required this.files,
    required this.onItemTap,
    required this.onShowMenu,
    required this.onItemDoubleTap,
    this.showIcons = true,
    this.showDetails = true,
  });

  final List<UFileItem> files;
  final Function(UFileItem) onItemTap;
  final Function(UFileItem, Offset) onShowMenu;
  final Function(UFileItem) onItemDoubleTap;
  final bool showIcons;
  final bool showDetails;

  @override
  State<UFileListWidget> createState() => _UFileListWidgetState();
}

class _UFileListWidgetState extends State<UFileListWidget> {
  Offset _globalPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Theme(
      data: theme.toMaterial(),
      child: MouseRegion(
        onHover: (event) => _globalPosition = event.position,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            if (isWideScreen) {
              return _buildGridView(theme);
            } else {
              return _buildListView(theme);
            }
          },
        ),
      ),
    );
  }

  Widget _buildListView(UThemeData theme) {
    return ListView.builder(
      key: PageStorageKey(widget.key),
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        return _buildFileItem(file, theme);
      },
    );
  }

  Widget _buildGridView(UThemeData theme) {
    return GridView.builder(
      key: PageStorageKey(widget.key),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: theme.spacingSmall,
        mainAxisSpacing: theme.spacingSmall,
      ),
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        return _buildFileItem(file, theme, isGrid: true);
      },
    );
  }

  Widget _buildFileItem(
    UFileItem file,
    UThemeData theme, {
    bool isGrid = false,
  }) {
    return GestureDetector(
      onTap: () => widget.onItemTap(file),
      onTapDown: (details) => _globalPosition = details.globalPosition,
      onLongPress: () => widget.onShowMenu(file, _globalPosition),
      onSecondaryTap: () => widget.onShowMenu(file, _globalPosition),
      onDoubleTap: () => widget.onItemDoubleTap(file),
      child: Container(
        padding: EdgeInsets.all(theme.spacingSmall),
        child: isGrid
            ? _buildGridItem(file, theme)
            : _buildListItem(file, theme),
      ),
    );
  }

  Widget _buildListItem(UFileItem file, UThemeData theme) {
    return Card(
      elevation: theme.elevationSmall,
      child: Padding(
        padding: EdgeInsets.all(theme.spacingMedium),
        child: Row(
          children: [
            if (widget.showIcons) ...[
              Icon(
                file.type == 'directory'
                    ? Icons.folder
                    : Icons.insert_drive_file,
                size: 32,
                color: file.type == 'directory'
                    ? theme.primary
                    : theme.secondary,
              ),
              SizedBox(width: theme.spacingMedium),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(fontSize: 16, color: theme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.showDetails) ...[
                    SizedBox(height: theme.spacingSmall),
                    Text(
                      '${file.type} • ${_formatDate(file.modified)}',
                      style: TextStyle(fontSize: 12, color: theme.secondary),
                    ),
                    if (file.size != null) ...[
                      Text(
                        _formatSize(file.size!),
                        style: TextStyle(fontSize: 12, color: theme.secondary),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (file.type == 'directory')
              Icon(Icons.folder, color: theme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(UFileItem file, UThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          file.type == 'directory' ? Icons.folder : Icons.insert_drive_file,
          size: 48,
          color: file.type == 'directory' ? theme.primary : theme.secondary,
        ),
        SizedBox(height: theme.spacingSmall),
        Text(
          file.name,
          style: TextStyle(fontSize: 14, color: theme.onSurface),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (widget.showDetails) ...[
          SizedBox(height: theme.spacingSmall),
          Text(
            _formatDate(file.modified),
            style: TextStyle(fontSize: 10, color: theme.secondary),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
