import 'package:flutter/material.dart';
import 'package:flutter_questions/models/question.dart';
import 'package:flutter_questions/pages/questions_resume.dart';
import 'package:flutter_questions/widgets/video_recorder.dart';

class QuestionsListPage extends StatefulWidget {
  QuestionsListPage({Key key}) : super(key: key);

  @override
  _QuestionsListPageState createState() => _QuestionsListPageState();
}

class _QuestionsListPageState extends State<QuestionsListPage> {
  VideoRecorderController recorderController = VideoRecorderController();

  List<Question> questions = [
    Question(question: 'Pregunta 1', timeToRecord: 10),
    Question(question: 'Pregunta 2', timeToRecord: 10)
  ];

  int _index = 0;
  String _questionText = '';
  String _recordButtonText = 'Siguiente';
  IconData recordIcon;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _questionText = questions[0].getQuestion();
    recordIcon = Icons.videocam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Questions'),
      ),
      body: Builder(
        builder: (context) => _getBody(context: context),
      ),
    );
  }

  _getBody({BuildContext context}) {
    Row buttonsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.switch_video,
            color: Colors.blue,
          ),
          onPressed: () => _switchCamera(),
          tooltip: 'Switch camera',
        ),
        IconButton(
          icon: Icon(recordIcon, color: Colors.blue),
          onPressed: () => onRecordButtonPressed(),
        ),
        !questions[_index].hasVideo()
            ? Container()
            : RaisedButton(
                color: Colors.blue,
                textColor: Colors.white,
                shape: StadiumBorder(),
                child: Text(_recordButtonText),
                onPressed: () => onNextButtonPressed(context),
              ),
      ],
    );

    Column list = Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.all(10.0),
            title: Text(
              _questionText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(10.0),
          child: buttonsRow,
        ),
      ],
    );

    Widget body = Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: VideoRecorder(
                  recorderController: recorderController,
                  onVideoRecorded: (videoURL) =>
                      onVideoRecorded(videoURL, context),
                  onUpdateRecordingButton: () => updateUIButtons(),
                ),
              ),
              Positioned(
                child: list,
              )
            ],
          ),
        ),
      ],
    );
    return body;
  }

  void onVideoRecorded(String videoURL, BuildContext context) {
    if (videoURL != null && videoURL.isNotEmpty) {
      questions[_index].setVideoUrl(videoURL);
      print('$videoURL saved to ${questions[_index].getQuestion()}');
      setState(() {});
    }
  }

  onNextButtonPressed(BuildContext context) {
    _index++;
    if (_index == questions.length) {
      final route = MaterialPageRoute(
          builder: (context) => QuestionsResumePage(questions: questions));
      Navigator.push(context, route);
      _index = 0;
      return;
    }
    setState(() {
      _questionText = questions[_index].getQuestion();
    });
  }

  onRecordButtonPressed() {
    setState(() {
      if (recorderController.isRecording()) {
        stopRecording();
      } else {
        startRecording();
      }
    });
  }

  startRecording() {
    if (!recorderController.isRecording()) {
      recorderController.startRecording();
    }
  }

  stopRecording() {
    recorderController.stopRecording();
  }

  _switchCamera() {
    recorderController.switchCamera();
  }

  updateUIButtons() {
    setState(() {
      recordIcon =
          recorderController.isRecording() ? Icons.stop : Icons.videocam;
    });
  }

  void showSnackBarMessage(String message, BuildContext context) {
    if (message != null)
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}
