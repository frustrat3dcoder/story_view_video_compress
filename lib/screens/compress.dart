import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';

// import 'package:example/preview.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoCompressing extends StatefulWidget {
  const VideoCompressing({super.key});

  @override
  State<VideoCompressing> createState() => _VideoCompressingState();
}

class _VideoCompressingState extends State<VideoCompressing> {
  String counter = 'video';

  trimVideo(file) async {
    final Trimmer _trimmer = Trimmer();
    await _trimmer.loadVideo(videoFile: file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: ElevatedButton(
              onPressed: () => openGallery(context),
              child: const Text('Open gallery')),
        ),
      ),
    );
  }

  openGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      var fileType = File(pickedFile.path);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => TrimmerView(fileType)));
    }
  }
}

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {Key? key}) : super(key: key);
  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();

    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  _saveVideo() {
    setState(() {
      _progressVisibility = true;
    });

    _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        setState(() {
          _progressVisibility = false;
        });
        debugPrint('OUTPUT PATH: $outputPath');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Preview(outputPath),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Video Trimmer"),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                ElevatedButton(
                  onPressed: _progressVisibility ? null : () => _saveVideo(),
                  child: const Text("SAVE"),
                ),
                Expanded(
                  child: VideoViewer(trimmer: _trimmer),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                      maxVideoLength: const Duration(seconds: 10),
                      editorProperties: TrimEditorProperties(
                        borderPaintColor: Colors.yellow,
                        borderWidth: 4,
                        borderRadius: 5,
                        circlePaintColor: Colors.yellow.shade800,
                      ),
                      areaProperties: TrimAreaProperties.edgeBlur(
                        thumbnailQuality: 10,
                      ),
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                    ),
                  ),
                ),
                TextButton(
                  child: _isPlaying
                      ? const Icon(
                          Icons.pause,
                          size: 80.0,
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.play_arrow,
                          size: 80.0,
                          color: Colors.white,
                        ),
                  onPressed: () async {
                    bool playbackState = await _trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() => _isPlaying = playbackState);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Preview extends StatefulWidget {
  final String? outputVideoPath;

  const Preview(this.outputVideoPath, {Key? key}) : super(key: key);

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.outputVideoPath!));
    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          InkWell(
            onTap: () => _compressVideo(File(widget.outputVideoPath!)),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: _controller.value.isInitialized
              ? VideoPlayer(_controller)
              : const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _compressVideo(file) async {
    // Get the external storage directory
    final externalDir = await getExternalStorageDirectory();
    final storageDirectory = externalDir!.path;

    // Generate a new file path in the accessible directory
    final accessibleFilePath = '$storageDirectory/trimmed_video.mp4';

    // Copy the trimmed video file to the accessible directory
    final trimmedFile = File(widget.outputVideoPath!);
    await trimmedFile.copy(accessibleFilePath);

    if (file != null) {
      try {
        await VideoCompress.compressVideo(
          accessibleFilePath,
          quality: VideoQuality.LowQuality,
          deleteOrigin: false,
          includeAudio: true,
        ).then((value) => getVideoFileSize(value!.path!));

        // setState(() {
        //   counter = info!.path!;
        // });
      } catch (e) {
        print("error is $e");
      }
    } else {
      return;
    }
    // await VideoCompress.setLogLevel(0);
  }

  Future<int?> getVideoFileSize(String videoPath) async {
    try {
      final file = File(videoPath);
      final fileExists = await file.exists();

      if (fileExists) {
        final fileStat = await file.stat();
        final fileSize = fileStat.size;

        // Returning the size in bytes
        return fileSize;
      } else {
        print('Video file does not exist');
        return null;
      }
    } catch (e) {
      print('Error occurred while getting video file size: $e');
      return null;
    }
  }
}
