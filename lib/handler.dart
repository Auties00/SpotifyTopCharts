import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart' as parser;

class ResponseHandler{
  DateTime _lastUpdate;
  List<SpotifyTrack> _tracks;
  ResponseHandler(){
    this._lastUpdate = DateTime.now();
    SpotifyTrackFactory.generateTracks().then((value) {
      this._tracks = value;
    });
  }

  Future<String> handle() async{
    if(_tracks == null){
      return "Starting up backend server, please wait!";
    }

    var now = DateTime.now();
    if(now.day != _lastUpdate.day){
      this._tracks = await SpotifyTrackFactory.generateTracks();
    }

    return json.encode(_tracks);
  }
}

class SpotifyTrack{
  String title;
  String artist;
  String imageUrl;
  SpotifyTrack(this.title, this.artist, this.imageUrl);

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'imageUrl': imageUrl
  };
}

class SpotifyTrackFactory{
  static Future<List<SpotifyTrack>> generateTracks() async {
    var response = await http.get("https://spotifycharts.com/regional/");

    var document = parser.parse(response.body);
    var chart = document.getElementsByClassName("chart-table")[0];
    var body = chart.getElementsByTagName("tbody")[0];

    List<SpotifyTrack> list = [];
    for(int x = 0; x < 20; x++){
      Element element = body.children[x];
      var url = element.children[0].children[0].outerHtml;

      RegExp exp = new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
      var match = exp.allMatches(url).first;

      var parsedUrl = url.substring(match.start, match.end);

      var spotify = await http.get(parsedUrl);
      Document spotifyDocument = parser.parse(spotify.body);

      var imageUrl = spotifyDocument.getElementsByClassName("cover-art-image")[0].outerHtml.replaceAll('<div class="cover-art-image" style="background-image:url(//', '');
      var end = imageUrl.indexOf('),');

      imageUrl = imageUrl.substring(0, end);

      var container = element.children[3];

      list.add(SpotifyTrack(container.children[0].text, container.children[1].text, "http://" + imageUrl));
    }


    return list;
  }
}