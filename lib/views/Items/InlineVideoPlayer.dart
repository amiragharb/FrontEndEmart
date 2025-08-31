import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  const InlineVideoPlayer({required this.url});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}


class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: false,
          looping: false,
          aspectRatio: _controller.value.aspectRatio,
        );
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController!);
  }
}