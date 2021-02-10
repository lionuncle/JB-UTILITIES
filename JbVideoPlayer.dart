import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class JbVideoPlayer extends StatefulWidget {
  String videoUrl;
  double width;
  double height;
  JbVideoPlayer(this.videoUrl,this.width, this.height);
  @override
  _JbVideoPlayerState createState() => _JbVideoPlayerState();
}

class _JbVideoPlayerState extends State<JbVideoPlayer> {
  VideoPlayerController _currVideoPlayerController;
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
    _currVideoPlayerController?.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return getVideoPlayer(VideoPlayerController.network(widget.videoUrl));
  }

  Widget getVideoPlayer(VideoPlayerController videoController){
    _currVideoPlayerController = videoController;
    videoController..addListener(() {
      if(videoController.value.duration?.compareTo(videoController.value.position) == 0){
        //TODO: do anything you want when video completes
      }
    });
    return Chewie(
      controller: ChewieController(
        videoPlayerController: videoController,
        autoInitialize: true,
        autoPlay: true,
        aspectRatio: widget.width / widget.height,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              "An error has occurred...",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
