import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:webrtc_streamer/utils/subtle_defs.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print

class Streamer extends StatefulWidget {
  const Streamer({super.key});

  @override
  State<Streamer> createState() => _StreamerState();
}

class Viewer extends StatefulWidget {
  const Viewer({super.key});

  @override
  State<Viewer> createState() => _ViewerState();
}

// STREAMER
class _StreamerState extends State<Streamer> {
  // VARS
  bool _offer = true;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  TextEditingController sdpController = TextEditingController();

  TextEditingController localSDPController = TextEditingController();
  TextEditingController candidateController = TextEditingController();

  @override
  void initState() {
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  @override
  void dispose() {
    sdpController.dispose();
    super.dispose();
  }

  // Media

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': true, // WORKS
    };

    MediaStream? localStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    setState(() {});

    return localStream;
  }

  // Network

  Future _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun1.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSDPConstraints = {
      "mandatory": {
        "OfferToRecieveAudio": false, // WORKS
        "OfferToRecieveVideo": false,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSDPConstraints);

    _localStream!.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        String candidateStringHump = jsonEncode(
          {
            'candidate': e.candidate.toString(),
            'sdpMid': e.sdpMid.toString(),
            'sdpMLineIndex': e.sdpMLineIndex,
          },
        );

        printM(candidateStringHump);

        if (candidateStringHump.contains('udp')) {
          candidateController.text = candidateStringHump;

          // eye.setCandidate(candidateController.text);
        }
      }
    };

    pc.onIceConnectionState = (state) => print(state);
    pc.onAddStream = (stream) {
      print('Added Stream: ${stream.id}');
      // _remoteRenderer.srcObject = stream;
    };
    pc.onAddTrack = (stream, track) {
      print('Added TRACK BRUH: ${track.id}');
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToRecieveVideo': 1});

    var session = parse(description.sdp!);
    print(json.encode(session));
    _offer = true;

    localSDPController.text = jsonEncode(session);

    _peerConnection!.setLocalDescription(description);

    // EYE
    // WebSocketChannel channel = eye.watch();

    // eye.setLocalSDP(localSDPController.text);

    // channel.stream.listen((data) {
    //   String message = data.toString();
    //   printC('EYE: $message');

    //   if (message.contains('remoteSDP:=')) {
    //     printG('GOT REMOTE SDP');
    //     sdpController.text = message.replaceAll('remoteSDP:=', '');
    //     _setRemoteDescription();
    //   }
    // });
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = json.decode(jsonString);

    String sdp = write(session, null);

    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');

    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
    printG('REMOTE SDP SET!');
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToRecieveVideo': 1});

    var session = parse(description.sdp!);

    print(jsonEncode(session));
    localSDPController.text = jsonEncode(session);

    _peerConnection!.setLocalDescription(description);
  }

  void _setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);

    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMLineIndex']);

    await _peerConnection!.addCandidate(candidate);
  }

  // Widgets
  Row offerAndAnswerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: _createOffer,
            child: Text('Offer'),
          ),
          ElevatedButton(
            onPressed: _createAnswer,
            child: Text('Answer'),
          ),
        ],
      );

  Widget sdpCandidateTF() => Padding(
        padding: const EdgeInsets.all(10),
        child: TextField(
          controller: sdpController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          maxLength: TextField.noMaxLength,
        ),
      );

  Widget sdpCandidateButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _setRemoteDescription,
            child: Text('Set Remote Desc.'),
          ),
          ElevatedButton(
            onPressed: _setCandidate,
            child: Text('Set Candidate'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          offerAndAnswerButtons(),
          sdpCandidateTF(),
          const SizedBox(height: 20),
          sdpCandidateButtons(),
          const SizedBox(height: 30),
          TextField(
            controller: localSDPController,
            maxLines: 2,
            decoration:
                InputDecoration(hintText: "LocalSDP get populated here..."),
          ),
          TextField(
            controller: candidateController,
            decoration:
                InputDecoration(hintText: "Candidates get populated here..."),
          ),
        ],
      ),
    );
  }
}

// VIEWER
class _ViewerState extends State<Viewer> {
  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final _remoteRenderer = RTCVideoRenderer();

  TextEditingController sdpController = TextEditingController();

  TextEditingController localSDPController = TextEditingController();
  TextEditingController candidateController = TextEditingController();

  @override
  void initState() {
    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  // Media

  Future initRenderers() async {
    _remoteRenderer.initialize();
  }

  // Network

  Future _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun1.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSDPConstraints = {
      "mandatory": {
        "OfferToRecieveAudio": false, // WORKS
        "OfferToRecieveVideo": true,
      },
      "optional": [],
    };

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSDPConstraints);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        String candidateStringHump = jsonEncode(
          {
            'candidate': e.candidate.toString(),
            'sdpMid': e.sdpMid.toString(),
            'sdpMLineIndex': e.sdpMLineIndex,
          },
        );

        printM(candidateStringHump);

        if (candidateStringHump.contains('udp')) {
          candidateController.text = candidateStringHump;
        }
      }
    };

    pc.onIceConnectionState = (state) => print(state);
    pc.onAddStream = (stream) {
      print('Added Stream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };
    pc.onAddTrack = (stream, track) {
      print('Added TRACK BRUH: ${track.id}');
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToRecieveVideo': 1});

    var session = parse(description.sdp!);
    print(json.encode(session));
    _offer = true;

    localSDPController.text = jsonEncode(session);

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = json.decode(jsonString);

    String sdp = write(session, null);

    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');

    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToRecieveVideo': 1});

    var session = parse(description.sdp!);

    print(jsonEncode(session));
    localSDPController.text = jsonEncode(session);

    _peerConnection!.setLocalDescription(description);
  }

  void _setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);

    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMLineIndex']);

    await _peerConnection!.addCandidate(candidate);
  }

  // Widgets
  Row offerAndAnswerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: _createOffer,
            child: Text('Offer'),
          ),
          ElevatedButton(
            onPressed: _createAnswer,
            child: Text('Answer'),
          ),
        ],
      );

  Widget sdpCandidateTF() => Padding(
        padding: const EdgeInsets.all(10),
        child: TextField(
          controller: sdpController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          maxLength: TextField.noMaxLength,
        ),
      );

  Widget sdpCandidateButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _setRemoteDescription,
            child: Text('Set Remote Desc.'),
          ),
          ElevatedButton(
            onPressed: _setCandidate,
            child: Text('Set Candidate'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viewer'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    color: Colors.black,
                    key: Key('remote'),
                    child: RTCVideoView(_remoteRenderer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          offerAndAnswerButtons(),
          sdpCandidateTF(),
          const SizedBox(height: 20),
          sdpCandidateButtons(),
          const SizedBox(height: 30),
          TextField(
            controller: localSDPController,
            maxLines: 2,
            decoration:
                InputDecoration(hintText: "LocalSDP get populated here..."),
          ),
          TextField(
            controller: candidateController,
            decoration:
                InputDecoration(hintText: "Candidates get populated here..."),
          ),
        ],
      ),
    );
  }
}
