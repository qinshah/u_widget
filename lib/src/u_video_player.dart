import 'dart:async';
import 'package:flutter/material.dart';

class UVideoPlayer extends StatefulWidget {
  // UVideoPlayer copyWith({
  //   Key? key,
  //   WidgetBuilder? topLeft,
  //   WidgetBuilder? topRight,
  //   WidgetBuilder? bottomLeft,
  //   WidgetBuilder? bottomRight,
  //   WidgetBuilder? topCenter,
  //   WidgetBuilder? bottomCenter,
  //   WidgetBuilder? centerRight,
  //   WidgetBuilder? centerLeft,
  // }) {
  //   return UVideoPlayer(
  //     key: key,
  //     aspectRatio: aspectRatio,
  //     video: video,
  //     topLeft: topLeft ?? this.topLeft,
  //     topRight: topRight ?? this.topRight,
  //     bottomLeft: bottomLeft ?? this.bottomLeft,
  //     bottomRight: bottomRight ?? this.bottomRight,
  //     centerRight: centerRight ?? this.centerRight,
  //     centerLeft: centerLeft ?? this.centerLeft,
  //     topCenter: topCenter ?? this.topCenter,
  //     bottomCenter: bottomCenter ?? this.bottomCenter,
  //   );
  // }

  const UVideoPlayer({
    super.key,
    this.aspectRatio = 16 / 9,
    required this.video,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.centerRight,
    this.centerLeft,
    this.topCenter,
    this.bottomCenter,
  });

  final double aspectRatio;

  final Widget video;

  final WidgetBuilder? topLeft;

  final WidgetBuilder? topRight;

  final WidgetBuilder? bottomLeft;

  final WidgetBuilder? bottomRight;

  final WidgetBuilder? topCenter;

  final WidgetBuilder? bottomCenter;

  final WidgetBuilder? centerRight;

  final WidgetBuilder? centerLeft;

  @override
  State<UVideoPlayer> createState() => _UVideoPlayerState();
}

class _UVideoPlayerState extends State<UVideoPlayer> {
  Timer _hubTimer = Timer(Duration.zero, () {})..cancel();

  void _onTap() {
    if (_hubTimer.isActive) {
      setState(() => _hubTimer.cancel());
      return;
    }
    _hubTimer.cancel();
    setState(() {
      _hubTimer = Timer(const Duration(seconds: 3), () {
        setState(() => _hubTimer.cancel());
      });
    });
  }

  @override
  void dispose() {
    _hubTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget stack = Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: Colors.black)),
        Center(
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: widget.video,
          ),
        ),
        GestureDetector(onTap: _onTap),
        if (_hubTimer.isActive)
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: widget.centerLeft?.call(context),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: widget.centerRight?.call(context),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: Colors.red,
                  child: Row(
                    children: [
                      if (widget.topLeft != null) widget.topLeft!.call(context),
                      Expanded(
                        child: widget.topCenter == null
                            ? SizedBox.shrink()
                            : widget.topCenter!.call(context),
                      ),
                      if (widget.topRight != null)
                        widget.topRight!.call(context),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: Colors.red,
                  child: Row(
                    children: [
                      if (widget.bottomLeft != null)
                        widget.bottomLeft!.call(context),
                      Expanded(
                        child: widget.bottomCenter == null
                            ? SizedBox.shrink()
                            : widget.bottomCenter!.call(context),
                      ),
                      if (widget.bottomRight != null)
                        widget.bottomRight!.call(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
    return _buildConstraint(context, stack);
  }

  Widget _buildConstraint(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final biggestSize = constraints.biggest;
        if (biggestSize.width == double.infinity) {
          child = SizedBox(
            height: biggestSize.height,
            width: biggestSize.height * widget.aspectRatio,
            child: child,
          );
        } else if (biggestSize.height == double.infinity) {
          child = SizedBox(
            width: biggestSize.width,
            height: biggestSize.width / widget.aspectRatio,
            child: child,
          );
        }
        return child;
      },
    );
  }
}
