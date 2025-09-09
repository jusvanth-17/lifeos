import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Information
  static const String appName = 'lifeOS';
  static const String appVersion = '1.0.0';

  // Layout Constants - Four Panel Layout
  static const double primarySidebarWidth = 280.0;
  static const double primarySidebarCollapsedWidth = 60.0;
  static const double secondarySidebarWidth = 280.0;
  static const double copilotPanelWidth = 320.0;
  static const double copilotPanelCollapsedWidth = 56.0;

  // Breakpoints
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // Animation Durations
  static const Duration defaultAnimationDuration =
      Duration(milliseconds: 0); // Instant transitions
  static const Duration fastAnimationDuration = Duration(milliseconds: 0);
  static const Duration slowAnimationDuration = Duration(milliseconds: 0);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  // Focus Modes
  static const String focusModeMe = 'me';
  static const String focusModeWork = 'work';
  static const String focusModeCommunity = 'community';

  // Primary Navigation Features
  static const String navDashboard = 'dashboard';
  static const String navGoals = 'goals';
  static const String navTasks = 'tasks';
  static const String navChats = 'chats';
  static const String navDocuments = 'documents';
  static const String navAIAssistant = 'ai_assistant';

  // Dashboard Submenus
  static const String dashboardExplore = 'explore';
  static const String dashboardPlan = 'plan';
  static const String dashboardAct = 'act';
  static const String dashboardLearnReflect = 'learn_reflect';

  // AI Assistant
  static const String aiAssistantName = 'Chotu';
  static const String aiWelcomeMessage =
      'Hi! I\'m Chotu, your AI assistant. How can I help you today?';

  // Currencies
  static const String currencyTime = 'T';
  static const String currencyKnowledge = 'K';
  static const String currencyGratification = 'G';
  static const String currencyCredits = 'Credits';

  // Database Configuration
  static const String localDatabaseName = 'lifeos_local.db';

  // Supabase Configuration - These will be loaded from .env at runtime
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://ebbvdmylnvjhhjcxgebe.supabase.co';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // PowerSync Configuration - These will be loaded from .env at runtime
  static String get powerSyncUrl =>
      dotenv.env['POWERSYNC_URL'] ?? 'https://your-instance.powersync.cloud';

  static String get powerSyncToken => dotenv.env['POWERSYNC_TOKEN'] ?? '';

  // Database sync settings
  static const bool enableRealTimeSync = true;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
