import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/task_create_screen.dart';
import 'screens/debug/debug_screen.dart';
import 'providers/supabase_auth_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/layout/four_panel_layout.dart';
import 'widgets/common/no_transition_page.dart';
import 'services/power_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with environment variables and proper session persistence
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ??
        'https://ebbvdmylnvjhhjcxgebe.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViYnZkbXlsbnZqaGhqY3hnZWJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NjYwOTksImV4cCI6MjA3MjU0MjA5OX0.QRUUNe9T6hiK420O3RjXsUZco45og-Pa3usKfeAvUro',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Enable automatic session persistence and token refresh
      autoRefreshToken: true,
    ),
  );

  print('✅ Supabase initialized with session persistence enabled');

  runApp(const ProviderScope(child: LifeOSApp()));
}

class LifeOSApp extends ConsumerWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<void>(
      future: _initializeApp(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'lifeOS',
            theme: ref.watch(themeProvider).themeData,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return _buildApp(context, ref);
      },
    );
  }

  Future<void> _initializeApp(WidgetRef ref) async {
    print('🚀 App initialization started');

    // Step 1: Wait for Supabase session recovery to complete
    // Supabase automatically attempts session recovery on initialization
    // We need to give it time to complete before checking auth state
    await Future.delayed(const Duration(milliseconds: 1000));
    print('⏱️ Waited for Supabase session recovery');

    // Step 2: Load and validate session state
    try {
      await ref.read(authProvider.notifier).loadSavedSession();
      print('✅ Auth session loading completed');
    } catch (e) {
      print('❌ Error loading auth session: $e');
    }

    // Step 3: Initialize PowerSync database service
    try {
      print('🔧 Starting PowerSync initialization...');
      await PowerSyncService.instance.initialize();
      print('✅ PowerSync database initialized successfully');

      // Test PowerSync extension loading
      try {
        print('🧪 Testing PowerSync extension...');
        final result = await PowerSyncService.instance
            .execute('SELECT powersync_rs_version() as version');
        print('✅ PowerSync extension loaded successfully!');
        print('🔧 PowerSync version: ${result.first['version']}');

        // Test basic database operations
        final basicTest =
            await PowerSyncService.instance.execute('SELECT 1 as test');
        print('✅ Basic SQL execution works: ${basicTest.first['test']}');

        // Test schema creation
        final tables = await PowerSyncService.instance.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
        print('✅ Database schema created successfully!');
        print('📋 Tables found: ${tables.map((t) => t['name']).join(', ')}');
      } catch (extensionError) {
        print('❌ PowerSync extension test failed: $extensionError');
        print(
            'This indicates the PowerSync native extension is not loaded properly.');
      }

      // Step 4: Connect to PowerSync if user is authenticated
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        try {
          await PowerSyncService.instance.connectWithSupabaseAuth();
          print('✅ PowerSync connected to Supabase');

          // Trigger post-authentication sync to ensure users are synced locally
          await PowerSyncService.instance.triggerPostAuthSync();
          print('✅ PowerSync post-auth sync completed');
        } catch (connectError) {
          print('❌ PowerSync connection failed: $connectError');
        }
      } else {
        print('ℹ️ User not authenticated - PowerSync connection skipped');
      }

      print('✅ PowerSync database ready for sync');
    } catch (e) {
      print('❌ Failed to initialize PowerSync database: $e');
      print('Stack trace: ${StackTrace.current}');
      // Continue without database - app can still work in offline mode
    }

    print('🎉 App initialization completed');
  }

  Widget _buildApp(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Determine initial location based on auth state and saved route
    String initialLocation = '/auth';
    if (authState.isAuthenticated) {
      // In a real implementation, you could get the last route here
      initialLocation = '/home';
    }

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/auth',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const AuthScreen(),
          ),
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const HomeScreen(),
          ),
        ),
        // Primary navigation routes
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'OKR Goals'),
          ),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const TasksScreen(),
          ),
          routes: [
            // Task creation route
            GoRoute(
              path: 'create',
              pageBuilder: (context, state) => buildNoTransitionPage(
                child: const TaskCreateScreen(),
              ),
            ),
            // Task detail route
            GoRoute(
              path: ':taskId',
              pageBuilder: (context, state) {
                final taskId = state.pathParameters['taskId']!;
                return buildNoTransitionPage(
                  child: TaskDetailScreen(taskId: taskId),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chats',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/documents',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Documents'),
          ),
        ),
        GoRoute(
          path: '/ai-assistant',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'AI Assistant'),
          ),
        ),

        // Legacy routes for backward compatibility
        GoRoute(
          path: '/insights',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Insights'),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Calendar'),
          ),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Notes'),
          ),
        ),
        GoRoute(
          path: '/focus',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Focus Session'),
          ),
        ),
        GoRoute(
          path: '/time',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Time Tracking'),
          ),
        ),
        GoRoute(
          path: '/learning',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Learning'),
          ),
        ),
        GoRoute(
          path: '/reflection',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Reflection'),
          ),
        ),
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Projects'),
          ),
        ),
        GoRoute(
          path: '/team',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Team'),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Chat'),
          ),
        ),
        GoRoute(
          path: '/meetings',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Meetings'),
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Analytics'),
          ),
        ),
        GoRoute(
          path: '/feedback',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Feedback'),
          ),
        ),
        GoRoute(
          path: '/community',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Community'),
          ),
        ),
        GoRoute(
          path: '/discover',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Discover'),
          ),
        ),
        GoRoute(
          path: '/quests',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Quests'),
          ),
        ),
        GoRoute(
          path: '/events',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Events'),
          ),
        ),
        GoRoute(
          path: '/discussions',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Discussions'),
          ),
        ),
        GoRoute(
          path: '/contribute',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Contribute'),
          ),
        ),
        GoRoute(
          path: '/knowledge',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Knowledge Base'),
          ),
        ),
        GoRoute(
          path: '/share',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const PlaceholderScreen(title: 'Share'),
          ),
        ),
        // Debug route
        GoRoute(
          path: '/debug',
          pageBuilder: (context, state) => buildNoTransitionPage(
            child: const DebugScreen(),
          ),
        ),
      ],
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isLoggedIn = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/auth';

        if (!isLoggedIn && !isLoggingIn) {
          return '/auth';
        }
        if (isLoggedIn && isLoggingIn) {
          return '/home';
        }
        return null;
      },
    );

    return MaterialApp.router(
      title: 'lifeOS',
      theme: themeState.themeData,
      darkTheme: themeState.themeData,
      themeMode: themeState.isSystemBrightness
          ? ThemeMode.system
          : (themeState.brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark),
      routerConfig: router,
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return FourPanelLayout(
      title: title,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'This feature is coming soon!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
