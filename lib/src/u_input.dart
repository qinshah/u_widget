import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

enum UInputType { number, password }

class UInput extends StatefulWidget {
  const UInput({
    super.key,
    this.type,
    this.prefix,
    this.suffix,
    this.showClearIcon = false,
    this.cntlr,
    this.hintText,
  });

  final UInputType? type;
  final Widget? prefix;
  final Widget? suffix;
  final bool showClearIcon;
  final TextEditingController? cntlr;
  final String? hintText;

  @override
  State<UInput> createState() => _UInputState();
}

class _UInputState extends State<UInput> {
  late bool _obscureText;
  late bool _isEmpty;
  late final _cntlr = widget.cntlr ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.type == UInputType.password;
    _isEmpty = _cntlr.text.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return TextField(
      controller: _cntlr,
      keyboardType: widget.type == UInputType.number
          ? TextInputType.number
          : null,
      onChanged: (value) {
        final isEmpty = value.isEmpty;
        if (_isEmpty != isEmpty) {
          setState(() => _isEmpty = isEmpty);
        }
      },
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: theme.secondary),
        prefixIcon: widget.prefix,
        suffixIcon: _buildSuffix(theme),
        isDense: true,
        contentPadding: EdgeInsets.all(theme.spacingSmall),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: theme.secondary),
          borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.secondary),
          borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primary),
          borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
        ),
      ),
    );
  }

  Widget _buildSuffix(UThemeData theme) {
    List<Widget> children = [];
    if (widget.suffix != null) children.add(widget.suffix!);
    if (widget.type == UInputType.password) {
      children.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: theme.secondary,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      );
    }
    if (widget.showClearIcon) {
      children.add(
        IconButton(
          icon: Icon(Icons.clear, color: _isEmpty ? theme.secondary : null),
          onPressed: _isEmpty
              ? null
              : () {
                  _cntlr.clear();
                  setState(() => _isEmpty = true);
                },
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
