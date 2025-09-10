import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/chat.dart';
import '../../../services/agora_service.dart';

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
  bool _isConnecting = true;
  String _connectionStatus = 'Connecting to call...';

  // Agora configuration
  String? _appId;
  String? _currentToken;
  AgoraTokenResponse? _tokenResponse;
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
      setState(() {
        _connectionStatus = 'Requesting permissions...';
      });

      // Request permissions
      if (Platform.isAndroid || Platform.isIOS) {
        await [Permission.microphone, Permission.camera].request();
      }

      setState(() {
        _connectionStatus = 'Generating token...';
      });

      // Generate dynamic token
      try {
        _tokenResponse = await AgoraService.instance.generateToken(
          channelName: widget.sessionId,
          uid: 0,
          role: 'publisher',
          expiryTime: 3600, // 1 hour
        );
        _appId = _tokenResponse!.appId;
        _currentToken = _tokenResponse!.token;
        
        debugPrint("✅ Dynamic token generated: ${_currentToken!.substring(0, 20)}...");
      } catch (e) {
        setState(() {
          _connectionStatus = 'Token generation failed: $e';
          _isConnecting = false;
        });
        return;
      }

      setState(() {
        _connectionStatus = 'Initializing RTC engine...';
      });

      // Initialize RTC engine
      _rtcEngine = createAgoraRtcEngine();
      await _rtcEngine!.initialize(RtcEngineContext(appId: _appId!));
      
      if (widget.callType == CallType.video) {
        await _rtcEngine!.enableVideo();
      } else {
        await _rtcEngine!.disableVideo();
      }
      
      await _rtcEngine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Set up event handlers
      _rtcEngine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("✅ RTC: Joined channel successfully");
          setState(() {
            _isJoined = true;
            _isConnecting = false;
            _connectionStatus = 'Connected';
          });
          if (widget.callType == CallType.video) {
            _rtcEngine!.startPreview();
          }
        },
        onLeaveChannel: (connection, stats) {
          debugPrint("✅ RTC: Left channel");
          setState(() {
            _isJoined = false;
          });
          if (_isScreenSharing) {
            _toggleScreenShare();
          }
          _rtcEngine!.stopPreview();
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint("👤 RTC: Remote user $uid joined");
          setState(() {
            _remoteUid = uid;
          });
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint("👤 RTC: Remote user $uid left");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (connection, token) async {
          debugPrint("⚠️ Token will expire, refreshing...");
          await _refreshToken();
        },
        onError: (err, msg) {
          debugPrint("❌ RTC Error: $err - $msg");
          setState(() {
            _connectionStatus = 'Connection error: $msg';
          });
        },
      ));

      setState(() {
        _connectionStatus = 'Joining channel...';
      });

      // Join channel with dynamic token
      await _rtcEngine!.joinChannel(
        token: _currentToken!,
        channelId: widget.sessionId,
        options: const ChannelMediaOptions(publishScreenTrack: false),
        uid: 0,
      );
    } catch (e) {
      debugPrint("❌ RTC initialization error: $e");
      setState(() {
        _connectionStatus = 'Failed to initialize: $e';
        _isConnecting = false;
      });
      
      // Show error dialog
      if (mounted) {
        _showErrorDialog('Call Failed', 'Failed to connect to the call: $e');
      }
    }
  }

  /// Refresh the Agora token when it's about to expire
  Future<void> _refreshToken() async {
    try {
      final newTokenResponse = await AgoraService.instance.refreshToken(
        channelName: widget.sessionId,
        uid: 0,
        role: 'publisher',
        expiryTime: 3600,
      );
      
      _tokenResponse = newTokenResponse;
      _currentToken = newTokenResponse.token;
      
      // Update the token in the channel
      await _rtcEngine!.renewToken(_currentToken!);
      debugPrint("✅ Token refreshed successfully");
    } catch (e) {
      debugPrint("❌ Failed to refresh token: $e");
    }
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close call screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
          if (_isConnecting) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            _connectionStatus,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Session ID: ${widget.sessionId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          if (!_isConnecting && !_isJoined) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isConnecting = true;
                  _connectionStatus = 'Retrying...';
                });
                _initializeRtc();
              },
              child: const Text('Retry'),
            ),
          ],
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
