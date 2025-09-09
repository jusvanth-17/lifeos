import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/chat.dart';

class CallPage extends StatefulWidget {
  final String sessionId;
  final ChatRoom chatRoom;
  final List<ChatParticipant> participants;
  final CallType callType;
  
  const CallPage({
    super.key, 
    required this.sessionId,
    required this.chatRoom,
    required this.participants,
    required this.callType,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  // RTC engine
  RtcEngine? _rtcEngine;

  // State
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isScreenSharing = false;
  int? _remoteUid;

  // Replace with your own values
  final String _appId = "88f1741521a941778d07e17a48890191";
  final String _tempToken = "007eJxTYMg9H3fYbs/2Pxy7luvxlkSu5fq85uXlOC7xR3IM3m0FKgcVGCws0gzNTQxNjQwTLU0Mzc0tUgzMUw3NE00sLCwNDC0N3Rfvz2gIZGSYO+syAyMUgvgsDCWpxSUMDAAQ/R57";
  final String _iosAppGroup = "group.com.jusvanthraja.agora";

  @override
  void initState() {
    super.initState();
    _initializeRtc();
  }

  @override
  void dispose() {
    _disposeRtc();
    super.dispose();
  }

  Future<void> _initializeRtc() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await [Permission.microphone, Permission.camera].request();
      }

      _rtcEngine = createAgoraRtcEngine();
      await _rtcEngine!.initialize(RtcEngineContext(appId: _appId));
      await _rtcEngine!.enableVideo();
      await _rtcEngine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      _rtcEngine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("✅ RTC: Joined channel");
          setState(() => _isJoined = true);
          _rtcEngine!.startPreview();
        },
        onLeaveChannel: (connection, stats) {
          debugPrint("✅ RTC: Left channel");
          if (_isScreenSharing) {
            _toggleScreenShare();
          }
          setState(() => _isJoined = false);
          _rtcEngine!.stopPreview();
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint("👤 RTC: Remote user $uid joined");
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint("👤 RTC: Remote user $uid left");
          setState(() => _remoteUid = null);
        },
      ));

      await _rtcEngine!.joinChannel(
        token: _tempToken,
        channelId: widget.sessionId,
        options: const ChannelMediaOptions(publishScreenTrack: false),
        uid: 0,
      );
    } catch (e) {
      debugPrint("❌ RTC initialization error: $e");
    }
  }

  Future<void> _disposeRtc() async {
    try {
      await _rtcEngine?.leaveChannel();
      await _rtcEngine?.stopPreview();
      await _rtcEngine?.release();
    } catch (_) {}
  }

  Future<void> _leaveChannel() async {
    await _rtcEngine?.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleScreenShare() async {
    if (_rtcEngine == null) return;
    try {
      if (!_isScreenSharing) {
        await _rtcEngine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
              publishCameraTrack: false, publishScreenTrack: true),
        );
        if (Platform.isAndroid) {
          await _rtcEngine!.startScreenCapture(const ScreenCaptureParameters2());
        } else if (Platform.isIOS) {
          await _rtcEngine!.setParameters('{"ios.app_group":"$_iosAppGroup"}');
          await _rtcEngine!.startScreenCapture(const ScreenCaptureParameters2());
        }
        setState(() => _isScreenSharing = true);
      } else {
        await _rtcEngine!.stopScreenCapture();
        await _rtcEngine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
              publishCameraTrack: true, publishScreenTrack: false),
        );
        setState(() => _isScreenSharing = false);
      }
    } catch (e) {
      debugPrint("❌ Screen sharing error: $e");
    }
  }

  void _toggleMute() {
    if (_rtcEngine == null) return;
    setState(() => _isMuted = !_isMuted);
    _rtcEngine!.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    if (_rtcEngine == null) return;
    setState(() => _isVideoOff = !_isVideoOff);
    _rtcEngine!.enableLocalVideo(!_isVideoOff);
    if (_isVideoOff) {
      _rtcEngine!.stopPreview();
    } else {
      _rtcEngine!.startPreview();
    }
  }

  void _navigateToChat() {
    // Return to chat screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.chatRoom.name ?? 
        (widget.chatRoom.isDirectChat 
            ? (widget.participants.isNotEmpty ? widget.participants.first.name : 'Call')
            : 'Group Call');
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chatName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.callType == CallType.video ? 'Video Call' : 'Voice Call',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isJoined ? _buildCallView() : _buildConnectingView(),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Connecting to call...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Session ID: ${widget.sessionId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallView() {
    return Stack(
      children: [
        _remoteVideo(),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Visibility(
                  visible: !_isVideoOff && !_isScreenSharing,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _rtcEngine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _toolbar(),
      ],
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && _rtcEngine != null) {
      try {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _rtcEngine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.sessionId),
          ),
        );
      } catch (e) {
        debugPrint("❌ Remote video error: $e");
        return const Center(child: Text("Error displaying remote video"));
      }
    } else {
      return const Center(child: Text("Waiting for another user to join..."));
    }
  }

  Widget _toolbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              onPressed: _toggleMute,
            ),
            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              onPressed: _leaveChannel,
            ),
            IconButton(
              icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
              onPressed: _toggleVideo,
            ),
            IconButton(
              icon: Icon(
                _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              ),
              onPressed: _toggleScreenShare,
              color: _isScreenSharing ? Colors.redAccent : null,
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _navigateToChat,
            ),
          ],
        ),
      ),
    );
  }
}
