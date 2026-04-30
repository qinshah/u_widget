import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';
import 'package:u_widget_example/utils.dart';

class VideoPlayerExample extends StatefulWidget {
  const VideoPlayerExample({super.key});

  @override
  State<VideoPlayerExample> createState() => _VideoPlayerExampleState();
}

class _VideoPlayerExampleState extends State<VideoPlayerExample> {
  int _width = 16;
  int _height = 9;
  double _playerHeight = 200;
  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: ListView(
        // scrollDirection: Axis.horizontal,
        children: [
          SizedBox(
            height: _playerHeight,
            // width: MediaQuery.of(context).size.width * 0.3,
            child: UVideoPlayer(
              video: ColoredBox(color: theme.primary),
              aspectRatio: _width / _height,
              topLeft: (_) => Row(children: [BackButton()]),
              topRight: (_) =>
                  Row(children: [Icon(Icons.info), Icon(Icons.more_vert)]),
              topCenter: (_) => Center(child: Text('标题')),
              progressBuilder: (_) => LinearProgressIndicator(),
              bottomLeft: (_) => Row(children: [Icon(Icons.play_arrow)]),
              centerLeft: (_) => Icon(Icons.lock),
              centerRight: (_) => Icon(Icons.camera),
              bottomRight: (_) => Row(
                children: [
                  IconButton(
                    onPressed: () {
                      context.push(
                        Scaffold(
                          appBar: AppBar(toolbarHeight: 0),
                          body: UVideoPlayer(
                            video: ColoredBox(color: theme.primary),
                            aspectRatio: _width / _height,
                            topLeft: (_) => Row(children: [BackButton()]),
                            topRight: (_) => Row(
                              children: [
                                Icon(Icons.info),
                                Icon(Icons.more_vert),
                              ],
                            ),
                            topCenter: (_) => Center(child: Text('标题')),
                            progressBuilder: (_) => LinearProgressIndicator(),
                            bottomLeft: (_) =>
                                Row(children: [Icon(Icons.play_arrow)]),
                            centerLeft: (_) => Icon(Icons.lock),
                            centerRight: (_) => Icon(Icons.camera),
                            bottomRight: (context) => Row(
                              children: [
                                IconButton(
                                  onPressed: context.pop,
                                  icon: Icon(Icons.fullscreen_exit),
                                ),
                              ],
                            ),
                            onProgressDragEnd:
                                (DragEndDetails details, double progress) {},
                            onProgressDragUpdate:
                                (DragUpdateDetails details, double progress) {},
                            onProgressTapDown: (double value) {},
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.fullscreen),
                  ),
                ],
              ),
              onProgressDragEnd: (DragEndDetails details, double progress) {},
              onProgressDragUpdate:
                  (DragUpdateDetails details, double progress) {},
              onProgressTapDown: (double value) {},
            ),
          ),
          Text('宽高比：$_width : $_height'),
          // Column(
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _width.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (value) {
                    if (value == _width) return;
                    setState(() {
                      _width = value.toInt();
                    });
                  },
                ),
              ),
              Expanded(
                child: Slider(
                  value: _height.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (value) {
                    if (value == _height) return;
                    setState(() {
                      _height = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
          Text('播放器高度：$_playerHeight'),
          Slider(
            value: _playerHeight,
            min: 100,
            max: 600,
            onChanged: (value) {
              setState(() {
                _playerHeight = value;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
