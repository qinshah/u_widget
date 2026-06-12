part of '../u_text_editor.dart';

// ===================== Editor Context Menu Overlay =====================

class _EditorContextMenu extends StatelessWidget {
  const _EditorContextMenu({
    required this.editorKey,
    required this.hasSelection,
    this.onCut,
    this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
  });

  final GlobalKey editorKey;
  final bool hasSelection;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 8,
          bottom: 8,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection) ...[
                    if (onCut != null)
                      _menuItem(context, 'Cut', Icons.content_cut,
                          onCut!),
                    if (onCopy != null)
                      _menuItem(context, 'Copy', Icons.content_copy,
                          onCopy!),
                  ],
                  _menuItem(
                      context, 'Paste', Icons.content_paste, onPaste),
                  const Divider(height: 1),
                  _menuItem(context, 'Select All', Icons.select_all,
                      onSelectAll),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}