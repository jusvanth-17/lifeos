import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../services/agora_service.dart';

/// Simple test screen to verify call functionality
class TestCallScreen extends ConsumerStatefulWidget {
  const TestCallScreen({super.key});

  @override
  ConsumerState<TestCallScreen> createState() => _TestCallScreenState();
}

class _TestCallScreenState extends ConsumerState<TestCallScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testAgoraHealth() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Agora health...';
    });

    try {
      final isHealthy = await AgoraService.instance.checkHealth();
      setState(() {
        _status = isHealthy ? '✅ Agora service is healthy' : '❌ Agora service is unhealthy';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Agora health check failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testTokenGeneration() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing token generation...';
    });

    try {
      final token = await AgoraService.instance.generateToken(
        channelName: 'test_channel',
        uid: 12345,
      );
      setState(() {
        _status = '✅ Token generated successfully:\n${token.token.substring(0, 50)}...';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Token generation failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCallInitiation() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing call initiation...';
    });

    try {
      // First create a test chat room for the call
      setState(() {
        _status = 'Creating test chat room...';
      });
      
      final testChatRoom = await ref.read(chatProvider.notifier).createChatRoom(
        name: 'Test Call Room',
        roomType: ChatRoomType.group,
        participantIds: [], // Just the current user for testing
      );
      
      setState(() {
        _status = 'Test chat room created, selecting it...';
      });
      
      // Select the test chat room
      await ref.read(chatProvider.notifier).selectChat(testChatRoom.id);
      
      setState(() {
        _status = 'Chat room selected, initiating call...';
      });
      
      // Now initiate the call
      await ref.read(chatProvider.notifier).initiateCall(CallType.voice);
      
      // Check if call state was updated
      final callState = ref.read(callStateProvider);
      final chatState = ref.read(chatProvider);
      setState(() {
        _status = callState.isCallActive 
          ? '✅ Call initiated successfully! State: ${callState.screenState}\nChat Room: ${testChatRoom.name} (${testChatRoom.id})\nSession ID: ${chatState.currentCallSessionId}'
          : '❌ Call initiation failed - no active call state';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Call initiation failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCallJoin() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing call join functionality...';
    });

    try {
      final chatState = ref.read(chatProvider);
      final sessionId = chatState.currentCallSessionId;
      
      if (sessionId == null) {
        setState(() {
          _status = '❌ No active call session to join. Please initiate a call first.';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _status = 'Joining call session: $sessionId';
      });
      
      // Test joining the current call session
      await ref.read(chatProvider.notifier).joinCall(sessionId);
      
      final callState = ref.read(callStateProvider);
      setState(() {
        _status = callState.isCallActive 
          ? '✅ Successfully joined call! State: ${callState.screenState}'
          : '❌ Call join failed - no active call state';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Call join failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final callState = ref.watch(callStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Integration Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text(_status),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call State',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Screen State: ${callState.screenState}'),
                    Text('Call Type: ${callState.callType}'),
                    Text('Is Active: ${callState.isCallActive}'),
                    Text('Participants: ${callState.participants.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (chatState.error != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chatState.error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testAgoraHealth,
              child: const Text('Test Agora Health'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testTokenGeneration,
              child: const Text('Test Token Generation'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testCallInitiation,
              child: const Text('Test Call Initiation'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testCallJoin,
              child: const Text('Test Call Join'),
            ),

            const SizedBox(height: 16),

            if (callState.isCallActive) ...[
              const Divider(),
              Text(
                'Call Controls',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(chatProvider.notifier).endCall();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('End Call'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(chatProvider.notifier).toggleMute();
                    },
                    child: Text(callState.isMuted ? 'Unmute' : 'Mute'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
