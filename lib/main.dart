import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:story_view/models/story_model.dart';
import 'package:story_view/screens/compress.dart';
import 'package:story_view/screens/story.dart';
import 'package:video_player/video_player.dart';

import 'data.dart';
import 'models/user_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
        title: 'Flutter Instagram Stories',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: VideoCompressing()
        // StoryScreen(stories: stories),
        );
  }
}
