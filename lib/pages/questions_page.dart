import 'package:flutter/material.dart';
import 'package:flutter_questions/model/question.dart';

class QuestionsListPage extends StatefulWidget {
  QuestionsListPage({Key key}) : super(key: key);

  @override
  _QuestionsListPageState createState() => _QuestionsListPageState();
}

class _QuestionsListPageState extends State<QuestionsListPage> {
  List<Question> questions = [
    Question('Pregunta 1', 10),
    Question('Pregunta 2', 10),
    Question('Pregunta 3', 10),
    Question('Pregunta 4', 10),
    Question('Pregunta 5', 10),
    Question('Pregunta 6', 10),
    Question('Pregunta 7', 10)
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
      body: Column(
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
        ],
      ),
    );
  }

  onNextButtonPressed() {
    setState(() {
      _index++;
      if (_index == questions.length) _index = 0;
      _questionText = questions[_index].getQuestion();
    });
  }
}
