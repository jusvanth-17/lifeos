import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class AgoraService {
  static AgoraService? _instance;
  static AgoraService get instance => _instance ??= AgoraService._();

  AgoraService._();

  // Your backend URL - update this to match your backend
  static const String _baseUrl = 'http://localhost:8000/api/v1/agora';
  static const String _authBaseUrl = 'http://localhost:8000/api/v1/auth';
  
  // Store the current JWT token
  String? _currentToken;

  /// Set the current authentication token
  void setAuthToken(String token) {
    _currentToken = token;
  }

  /// Authenticate with backend using user credentials and get JWT token
  Future<String?> authenticateWithBackend({
    required String email,
    required String displayName,
  }) async {
    try {
      developer.log('🔐 Authenticating with backend for: $email', name: 'AgoraService');
      
      // Step 1: Register user (if not exists)
      try {
        final registerResponse = await http.post(
          Uri.parse('$_authBaseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'display_name': displayName,
          }),
        );
        
        if (registerResponse.statusCode == 200) {
          developer.log('✅ User registered successfully', name: 'AgoraService');
        } else {
          developer.log('ℹ️ User might already exist: ${registerResponse.statusCode}', name: 'AgoraService');
        }
      } catch (e) {
        developer.log('ℹ️ Register attempt failed (user might exist): $e', name: 'AgoraService');
      }

      // Step 2: Start WebAuthn registration to create credentials
      try {
        final userId = email.hashCode.abs().toString(); // Simple user ID from email
        
        final regStartResponse = await http.post(
          Uri.parse('$_authBaseUrl/webauthn/registration/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'email': email,
            'display_name': displayName,
          }),
        );

        if (regStartResponse.statusCode == 200) {
          developer.log('✅ WebAuthn registration started', name: 'AgoraService');
          
          // Step 3: Complete registration with mock credentials
          final regCompleteResponse = await http.post(
            Uri.parse('$_authBaseUrl/webauthn/registration/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'credential': {
                'id': 'mock_credential_${userId}',
                'type': 'public-key'
              },
            }),
          );

          if (regCompleteResponse.statusCode == 200) {
            developer.log('✅ WebAuthn registration completed', name: 'AgoraService');
          }
        }
      } catch (e) {
        developer.log('ℹ️ WebAuthn registration attempt: $e', name: 'AgoraService');
      }

      // Step 4: Start authentication to get JWT token
      final authStartResponse = await http.post(
        Uri.parse('$_authBaseUrl/webauthn/authentication/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (authStartResponse.statusCode == 200) {
        developer.log('✅ WebAuthn authentication started', name: 'AgoraService');
        
        // Step 5: Complete authentication with mock credentials
        final userId = email.hashCode.abs().toString();
        final authCompleteResponse = await http.post(
          Uri.parse('$_authBaseUrl/webauthn/authentication/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'credential': {
              'id': 'mock_credential_${userId}',
              'type': 'public-key'
            },
          }),
        );

        if (authCompleteResponse.statusCode == 200) {
          final authData = jsonDecode(authCompleteResponse.body);
          final token = authData['access_token'] as String?;
          
          if (token != null) {
            _currentToken = token;
            developer.log('✅ JWT token obtained and stored', name: 'AgoraService');
            return token;
          }
        }
      }

      throw Exception('Failed to complete authentication flow');
      
    } catch (e) {
      developer.log('❌ Backend authentication failed: $e', name: 'AgoraService');
      return null;
    }
  }

  /// Generate a fresh Agora token for joining a call
  Future<AgoraTokenResponse> generateToken({
    required String channelName,
    int uid = 0,
    String role = 'publisher',
    int expiryTime = 3600,
  }) async {
    try {
      if (_currentToken == null) {
        throw Exception('User not authenticated - no token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
        body: jsonEncode({
          'channel_name': channelName,
          'uid': uid,
          'role': role,
          'expiry_time': expiryTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Agora token generated successfully', name: 'AgoraService');
        return AgoraTokenResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Token generation failed: ${error['detail']}');
      }
    } catch (e) {
      developer.log('❌ Error generating Agora token: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Start a new call session
  Future<CallSessionResponse> startCall({
    required String chatRoomId,
    String callType = 'video',
  }) async {
    try {
      if (_currentToken == null) {
        throw Exception('User not authenticated - no token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/start-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
        body: jsonEncode({
          'chat_room_id': chatRoomId,
          'call_type': callType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Call session started: ${data['session_id']}', name: 'AgoraService');
        return CallSessionResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to start call: ${error['detail']}');
      }
    } catch (e) {
      developer.log('❌ Error starting call: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Join an existing call session
  Future<JoinCallResponse> joinCall({
    required String sessionId,
  }) async {
    try {
      if (_currentToken == null) {
        throw Exception('User not authenticated - no token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/join-call/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Joined call session: $sessionId', name: 'AgoraService');
        return JoinCallResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to join call: ${error['detail']}');
      }
    } catch (e) {
      developer.log('❌ Error joining call: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Refresh an existing token when it's about to expire
  Future<AgoraTokenResponse> refreshToken({
    required String channelName,
    int uid = 0,
    String role = 'publisher',
    int expiryTime = 3600,
  }) async {
    try {
      if (_currentToken == null) {
        throw Exception('User not authenticated - no token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
        body: jsonEncode({
          'channel_name': channelName,
          'uid': uid,
          'role': role,
          'expiry_time': expiryTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Agora token refreshed successfully', name: 'AgoraService');
        return AgoraTokenResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Token refresh failed: ${error['detail']}');
      }
    } catch (e) {
      developer.log('❌ Error refreshing Agora token: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Check Agora service health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Agora service health: ${data['status']}', name: 'AgoraService');
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      developer.log('❌ Error checking Agora health: $e', name: 'AgoraService');
      return false;
    }
  }
}

/// Response model for token generation
class AgoraTokenResponse {
  final String token;
  final String appId;
  final String channelName;
  final int uid;
  final int expiryTime;
  final int expiresAt;

  AgoraTokenResponse({
    required this.token,
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.expiryTime,
    required this.expiresAt,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'],
      appId: json['app_id'],
      channelName: json['channel_name'],
      uid: json['uid'],
      expiryTime: json['expiry_time'],
      expiresAt: json['expires_at'],
    );
  }

  /// Check if token is about to expire (within 5 minutes)
  bool get isExpiringSoon {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (expiresAt - currentTime) < 300; // 5 minutes
  }

  /// Check if token is expired
  bool get isExpired {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime >= expiresAt;
  }
}

/// Response model for starting a call session
class CallSessionResponse {
  final String sessionId;
  final String channelName;
  final List<String> participants;
  final String callType;
  final String createdAt;
  final String status;

  CallSessionResponse({
    required this.sessionId,
    required this.channelName,
    required this.participants,
    required this.callType,
    required this.createdAt,
    required this.status,
  });

  factory CallSessionResponse.fromJson(Map<String, dynamic> json) {
    return CallSessionResponse(
      sessionId: json['session_id'],
      channelName: json['channel_name'],
      participants: List<String>.from(json['participants']),
      callType: json['call_type'],
      createdAt: json['created_at'],
      status: json['status'],
    );
  }
}

/// Response model for joining a call session
class JoinCallResponse {
  final String sessionId;
  final String channelName;
  final AgoraTokenResponse tokenInfo;

  JoinCallResponse({
    required this.sessionId,
    required this.channelName,
    required this.tokenInfo,
  });

  factory JoinCallResponse.fromJson(Map<String, dynamic> json) {
    return JoinCallResponse(
      sessionId: json['session_id'],
      channelName: json['channel_name'],
      tokenInfo: AgoraTokenResponse.fromJson(json['token_info']),
    );
  }
}
