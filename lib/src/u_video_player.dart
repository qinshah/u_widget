import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class UVideoPlayer extends StatefulWidget {
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
    this.progressBuilder,
    this.onTogglePlay,
    this.onDoubleTapDown,
    required this.onProgressDragEnd,
    required this.onProgressDragUpdate,
    required this.onProgressTapDown,
    this.hubDuration = const Duration(seconds: 3),
  });

  final VoidCallback? onTogglePlay;

  final GestureTapDownCallback? onDoubleTapDown;

  final double aspectRatio;

  final Widget video;

  final WidgetBuilder? topLeft;

  final WidgetBuilder? topRight;

  final WidgetBuilder? bottomLeft;

  final WidgetBuilder? progressBuilder;

  final WidgetBuilder? bottomRight;

  final WidgetBuilder? topCenter;

  final WidgetBuilder? centerRight;

  final WidgetBuilder? centerLeft;

  final Duration hubDuration;

  @override
  State<UVideoPlayer> createState() => _UVideoPlayerState();

  final void Function(DragEndDetails details, double progress)?
  onProgressDragEnd;
  final void Function(DragUpdateDetails details, double progress)?
  onProgressDragUpdate;

  final ValueChanged<double>? onProgressTapDown;
}

class _UVideoPlayerState extends State<UVideoPlayer> {
  Timer _hubTimer = Timer(Duration.zero, () {})..cancel();

  PointerDeviceKind? _deviceKind;

  late Duration _hubDuration = widget.hubDuration;

  double _progressLength = 0;

  Timer _buildNewHubTimer() {
    return Timer(_hubDuration, () {
      setState(() => _hubTimer.cancel());
    });
  }

  void _taggleHubTimer() => setState(() {
    _hubTimer.isActive ? _hubTimer.cancel() : _hubTimer = _buildNewHubTimer();
  });

  void _cancelHubTimer(_) {
    setState(() => _hubTimer.cancel());
  }

  void _resetHubTimer(_) {
    bool wasActive = _hubTimer.isActive;
    _hubTimer.cancel();
    _hubTimer = _buildNewHubTimer();
    if (!wasActive) {
      setState(() {
        // _hubTimer active
      });
    }
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
        GestureDetector(
          onDoubleTapDown: widget.onDoubleTapDown,
          onTap: _deviceKind == PointerDeviceKind.mouse
              ? widget.onTogglePlay
              : _taggleHubTimer,
          onTapDown: (details) => _deviceKind = details.kind,
        ),
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
                child: Row(
                  children: [
                    if (widget.topLeft != null) widget.topLeft!.call(context),
                    Expanded(
                      child: widget.topCenter == null
                          ? SizedBox.shrink()
                          : widget.topCenter!.call(context),
                    ),
                    if (widget.topRight != null) widget.topRight!.call(context),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    if (widget.bottomLeft != null)
                      widget.bottomLeft!.call(context),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          _hubDuration = const Duration(days: 666);
                          _resetHubTimer(details); // 拖动时hub显示666天(不自动隐藏)
                          final progress =
                              details.localPosition.dx / _progressLength;
                          widget.onProgressDragUpdate?.call(details, progress);
                        },
                        onTapDown: (details) {
                          widget.onProgressTapDown?.call(
                            details.localPosition.dx / _progressLength,
                          );
                        },
                        onHorizontalDragEnd: (details) {
                          _hubDuration = widget.hubDuration;
                          _resetHubTimer(details); // 拖动结束时恢复hub显示时间
                          final progress =
                              details.localPosition.dx / _progressLength;
                          widget.onProgressDragEnd?.call(details, progress);
                        },
                        child: LayoutBuilder(
                          builder: (context, cconstraints) {
                            _progressLength = cconstraints.maxWidth;
                            return IgnorePointer(
                              child: widget.progressBuilder?.call(context),
                            );
                          },
                        ),
                      ),
                    ),
                    if (widget.bottomRight != null)
                      widget.bottomRight!.call(context),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
    return MouseRegion(
      onEnter: _resetHubTimer,
      onHover: _resetHubTimer,
      onExit: _cancelHubTimer,
      child: _buildConstraint(context, stack),
    );
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
