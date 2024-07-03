import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Omegle Clone Widget
class Omegle extends StatefulWidget {
  const Omegle({Key? key}) : super(key: key);

  @override
  State<Omegle> createState() => _OmegleState();
}

class _OmegleState extends State<Omegle> {
  // States for video, audio,and socket connection
  bool video = true;
  bool audio = true;
  bool socketStatus = false;
  String UserConnectionMsg = "Not Connected";
  io.Socket? socket;

  // Controllers and renderers for handling peer connection and video streams
  final TextEditingController _msgController = TextEditingController();
  final Peer peer = Peer(options: PeerOptions(debug: LogLevel.All));
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool inCall = false;
  String? peerID;

  String? otherUser;
  MediaStream? localStream;
  String? otherPeerID;

  bool joined = false;
  bool waitingOnConnection = false;
  bool _remoteVideoLoading = true; // State variable for remote video loading
  int onlineUsers = 0;

  @override
  void initState() {
    super.initState();
    initRenderers();
    peer.on("open").listen((id) {
      setState(() {
        peerID = peer.id;
        debugPrint('peerID: $peerID');
      });
    });
    connectSocket();
    _getUsersMedia(audio, video);

    // Listener for incoming calls
    peer.on<MediaConnection>("call").listen((call) async {
      call.answer(localStream!);

      call.on("close").listen((event) {
        setState(() {
          inCall = false;
          _remoteRenderer.srcObject = null;
        });
      });

      call.on<MediaStream>("stream").listen((event) {
        setState(() {
          _remoteRenderer.srcObject = event;
          inCall = true;
          _remoteVideoLoading = false; // Remote video is ready
        });
      });
    });
  }

  /// Initialize local and remote renderers
  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  /// Connect to the socket server
  void connectSocket() {
    debugPrint("Connecting to socket");
    socket = io.io('https://omegleclone.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();
    
    // Listeners for various socket events
    socket!.on('oc', (oc) {
      setState(() {
        socketStatus = true;
        debugPrint('online users: $oc');
        onlineUsers = oc;
      });
    });
    socket!.on('connect', (data) {
      setState(() {
        socketStatus = true;
        debugPrint('Socket connected $data');
      });
      _getUsersMedia(audio, video);
      socket!.emit('join', peerID);
    });

    socket!.on('dc', (msg) async {
      debugPrint('Socket disconnected $msg');
      setState(() {
        _remoteRenderer.srcObject = null;
        socketStatus = false;
        joined = false;
        UserConnectionMsg = "Disconnected";
      });
      await joinRoom();
    });

    socket!.on('other peer', (pid) {
      setState(() {
        otherPeerID = pid;
        debugPrint('otherPeerID: $otherPeerID');
      });
    });

    socket!.on('user joined', (msg) {
      setState(() {
        socketStatus = true;
        connect(msg[1]);
        joined = true;
        UserConnectionMsg = "Connected";
      });
    });
  }

  /// Connect to a new user
  void connectToNewUser(String pid, MediaStream stream) {
    debugPrint('connectToNewUser: $pid Stream: $stream');
    final call = peer.call(pid, stream);
    call.on<MediaStream>('stream').listen((remoteStream) {
      setState(() {
        _remoteRenderer.srcObject = remoteStream;
        _remoteVideoLoading = false;
      });
    });

    call.on('close').listen((event) {
      setState(() {
        inCall = false;
        _remoteRenderer.srcObject = null;
      });
    });
  }

  /// Join a room
  Future<void> joinRoom() async {
    try {
      setState(() {
        waitingOnConnection = true;
        UserConnectionMsg = "Searching for a user...";
        joined = false;
        _remoteVideoLoading = true;
      });

      socket!.emit('join room', ({peerID, video}));
      debugPrint('join room: $peerID $video');
      setState(() {
        waitingOnConnection = true;
        joined = false;
        _remoteRenderer.srcObject = null;
      });

      peer.on<MediaConnection>('call').listen((call) {
        call.answer(localStream!);
        call.on<MediaStream>('stream').listen((stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
            waitingOnConnection = false;
            joined = true;
            UserConnectionMsg = "Connected";
            _remoteVideoLoading = false; // Remote video is ready
          });
        });
      });
    } catch (e) {
      debugPrint('join Room: $e');
    }
  }

  /// Get user's media (audio and video)
  Future<void> _getUsersMedia(bool audio, bool video) async {
    final Map<String, dynamic> mediaConstraints = {'audio': audio, 'video': video};
    try {
      final MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      setState(() {
        localStream = stream;
        _localRenderer.srcObject = stream;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    peer.dispose();
    _msgController.dispose();
    if (localStream != null) {
      localStream!.getTracks().forEach((track) => track.stop());
      localStream = null;
    }
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socket!.disconnect();
    super.dispose();
  }

  /// Connect to a peer
  void connect(String peerid) async {
    final MediaStream mediaStream = await navigator.mediaDevices.getUserMedia({"video": true, "audio": true});

    final call = peer.call(peerid, mediaStream);

    call.on<MediaStream>("stream").listen((event) {
      setState(() {
        _remoteRenderer.srcObject = event;
        _localRenderer.srcObject = mediaStream;
        inCall = true;
        _remoteVideoLoading = false;
      });
    });

    call.on('close').listen((event) {
      setState(() {
        inCall = false;
        _remoteRenderer.srcObject = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            VideoRenderers(),
            ButtonSection(),
          ],
        ),
      ),
    );
  }

  /// Section for control buttons
  Row ButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              video = !video;
            });
            _getUsersMedia(audio, video);
          },
          icon: Icon(
            video ? Icons.videocam : Icons.videocam_off,
            color: video ? Colors.blue : Colors.grey,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              audio = !audio;
            });
            _getUsersMedia(audio, video);
          },
          icon: Icon(
            audio ? Icons.mic : Icons.mic_off,
            color: audio ? Colors.blue : Colors.grey,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        ElevatedButton(
          onPressed: () async {
            await joinRoom();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: const StadiumBorder(),
            backgroundColor: Colors.white,
          ),
          child: const Text('Search for Next Partner',
              style: TextStyle(color: Color.fromARGB(255, 7, 7, 7))),
        ),
      ],
    );
  }

  /// Section for displaying local and remote video streams
  SizedBox VideoRenderers() => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                key: const Key('remote'),
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                ),
                child: Stack(
                  children: [
                    RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                    if (_remoteVideoLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                key: const Key('local'),
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                ),
                child: video
                    ? RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(child: Text('No Video')),
              ),
            ),
          ],
        ),
      );
}
