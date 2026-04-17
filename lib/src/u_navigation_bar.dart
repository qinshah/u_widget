import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UNavigationBar extends StatelessWidget {
  const UNavigationBar({
    super.key,
    required this.currentPath,
    required this.onHome,
    required this.onBack,
    required this.onForward,
    required this.onUp,
    required this.onRefresh,
    this.canGoBack = false,
    this.canGoForward = false,
    this.showPath = true,
    this.pathController,
    this.onPathSubmitted,
  });

  final String currentPath;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onUp;
  final VoidCallback onRefresh;
  final bool canGoBack;
  final bool canGoForward;
  final bool showPath;
  final TextEditingController? pathController;
  final Function(String)? onPathSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Card(
      elevation: theme.elevationSmall,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(theme.spacingSmall),
        child: Column(
          children: [
            Row(
              children: [
                _buildNavButton(
                  Icons.home,
                  'Home',
                  onHome,
                  theme,
                  enabled: true,
                ),
                _buildNavButton(
                  Icons.arrow_back,
                  'Back',
                  onBack,
                  theme,
                  enabled: canGoBack,
                ),
                _buildNavButton(
                  Icons.arrow_forward,
                  'Forward',
                  onForward,
                  theme,
                  enabled: canGoForward,
                ),
                _buildNavButton(
                  Icons.arrow_upward,
                  'Up',
                  onUp,
                  theme,
                  enabled: true,
                ),
                _buildNavButton(
                  Icons.refresh,
                  'Refresh',
                  onRefresh,
                  theme,
                  enabled: true,
                ),
                const Spacer(),
                if (showPath) ...[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 400) {
                          return _buildPathDisplay(theme);
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (showPath) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth <= 400) {
                    return Padding(
                      padding: EdgeInsets.only(top: theme.spacingSmall),
                      child: _buildPathDisplay(theme),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    UThemeData theme, {
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onPressed : null,
        color: enabled ? theme.primary : theme.secondary,
      ),
    );
  }

  Widget _buildPathDisplay(UThemeData theme) {
    if (pathController != null && onPathSubmitted != null) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: theme.secondary),
          borderRadius: BorderRadius.circular(theme.borderRadiusSmall),
        ),
        child: TextField(
          controller: pathController,
          onSubmitted: onPathSubmitted,
          style: TextStyle(fontSize: 14, color: theme.onSurface),
          decoration: InputDecoration(
            hintText: currentPath,
            hintStyle: TextStyle(color: theme.secondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: theme.spacingSmall,
              vertical: theme.spacingTiny,
            ),
          ),
        ),
      );
    }
    return Text(
      currentPath,
      style: TextStyle(fontSize: 14, color: theme.onSurface),
      overflow: TextOverflow.ellipsis,
    );
  }
}
