import 'package:flutter/material.dart';
import 'package:flutter_questions/model/question.dart';
import 'package:flutter_questions/widgets/video_recorder.dart';

class QuestionsListPage extends StatefulWidget {
  QuestionsListPage({Key key}) : super(key: key);

  @override
  _QuestionsListPageState createState() => _QuestionsListPageState();
}

class _QuestionsListPageState extends State<QuestionsListPage> {
  List<Question> questions = [
    Question(question: 'Pregunta 1', timeToRecord: 10),
    Question(question: 'Pregunta 2', timeToRecord: 10),
    Question(question: 'Pregunta 3', timeToRecord: 10),
    Question(question: 'Pregunta 4', timeToRecord: 10),
    Question(question: 'Pregunta 5', timeToRecord: 10),
    Question(question: 'Pregunta 6', timeToRecord: 10),
    Question(question: 'Pregunta 7', timeToRecord: 10)
  ];

  int _index = 0;
  String _questionText = '';

  @override
  void initState() {
    super.initState();
    _questionText = questions[0].getQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions'),
      ),
      body: _getBody(),
    );
  }

  _getBody() {
    ListView list = ListView(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.all(10.0),
              title: Text(
                _questionText,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              alignment: Alignment.topRight,
              margin: EdgeInsets.only(right: 10.0),
              child: RaisedButton(
                color: Colors.blue,
                textColor: Colors.white,
                shape: StadiumBorder(),
                child: Text('Next Question'),
                onPressed: () => onNextButtonPressed(),
              ),
            ),
            VideoRecorder(),
          ],
        )
      ],
    );
    return list;
  }

  onNextButtonPressed() {
    setState(() {
      _index++;
      if (_index == questions.length) _index = 0;
      _questionText = questions[_index].getQuestion();
    });
  }
}
