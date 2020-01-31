import 'package:flutter/material.dart';
import 'package:flutter_questions/models/question.dart';
import 'package:flutter_questions/widgets/video_player_widget.dart';

class QuestionsResumePage extends StatefulWidget {
  final List<Question> questions;

  QuestionsResumePage({this.questions});

  @override
  _QuestionsResumePageState createState() => _QuestionsResumePageState();
}

class _QuestionsResumePageState extends State<QuestionsResumePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resume Video'),
      ),
      body: ListView(
        children: getQuestionListView(),
      ),
    );
  }

  List<Widget> getQuestionListView() {
    final List<Widget> questionLists = [];
    widget.questions.forEach((question) {
      final tile = ListTile(
        title: Text(question.getQuestion()),
        subtitle: VideoPlayerWidget(
          videoUrl: question.getVideoUrl(),
        ),
      );

      questionLists..add(tile);
    });
    return questionLists;
  }
}
