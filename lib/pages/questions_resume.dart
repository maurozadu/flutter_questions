import 'package:flutter/material.dart';
import 'package:flutter_questions/models/question.dart';

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
        children: <Widget>[],
      ),
    );
  }
}
