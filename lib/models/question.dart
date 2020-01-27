
class Question{
  String question;
  int timeToRecord;
  String videoURL;

  Question({this.question, this.timeToRecord});

  String getQuestion(){
    return question;
  }

  setVideoUrl(String inVideoURL){
    this.videoURL = videoURL;
  }
}