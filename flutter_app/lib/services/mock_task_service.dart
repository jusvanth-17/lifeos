import '../models/task.dart';
import '../models/extensions/task_extensions.dart';

class MockTaskService {
  static final List<Task> _mockTasks = [
    Task(
      id: 'task-1',
      title: 'Implement User Authentication',
      description:
          'Build secure login and registration system with Firebase Auth',
      questDocument: '''# User Authentication Quest

## Objective
Implement a secure authentication system for lifeOS using Firebase Auth.

## Requirements
- [ ] Login screen with email/password
- [ ] Registration with email verification
- [ ] Password reset functionality
- [ ] Social login (Google, Apple)
- [ ] Session management

## Technical Notes
- Use Firebase Auth SDK
- Implement proper error handling
- Add loading states
- Store user session securely

## Resources
- Firebase Auth Documentation
- Flutter Auth Best Practices
''',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      estimatedHours: 16.0,
      actualHours: 8.5,
      timeSpent: 8.5,
      questTeam: [
        TaskAssignment(
          id: 'assignment-1-1',
          taskId: 'task-1',
          userId: 'user-1',
          userName: 'Alex Chen',
          userAvatar: 'https://i.pravatar.cc/150?img=1',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(days: 3)),
          assignedBy: 'user-admin',
        ),
        TaskAssignment(
          id: 'assignment-1-2',
          taskId: 'task-1',
          userId: 'user-2',
          userName: 'Sarah Kim',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          role: TeamRole.designer,
          assignedAt: DateTime.now().subtract(const Duration(days: 2)),
          assignedBy: 'user-1',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      goalId: 'goal-1',
      subtaskIds: const ['task-1-1', 'task-1-2'],
      dependsOn: const [],
      blocks: const ['task-2'],
      attachedDocumentIds: const ['doc-auth-spec'],
      chatRoomId: 'chat-task-1',
      knowledgeReward: 25,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-2',
      title: 'Design Task Management UI',
      description: 'Create intuitive and beautiful task management interface',
      questDocument: '''# Task Management UI Quest

## Objective
Design and implement the task management interface for lifeOS.

## Requirements
- [ ] Task list view with filtering
- [ ] Kanban board for visual workflow
- [ ] Task detail view with rich editing
- [ ] Quick actions and shortcuts
- [ ] Mobile-responsive design

## Design Goals
- Clean, minimal interface
- Focus mode integration
- Accessibility compliance
- Smooth animations

## Mockups
- Desktop layouts
- Mobile layouts
- Dark/light theme variants
''',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      estimatedHours: 24.0,
      timeSpent: 0.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-2-1',
          taskId: 'task-2',
          userId: 'user-2',
          userName: 'Sarah Kim',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(days: 1)),
          assignedBy: 'user-admin',
        ),
        TaskAssignment(
          id: 'assignment-2-2',
          taskId: 'task-2',
          userId: 'user-3',
          userName: 'Mike Johnson',
          userAvatar: 'https://i.pravatar.cc/150?img=3',
          role: TeamRole.designer,
          assignedAt: DateTime.now().subtract(const Duration(days: 1)),
          assignedBy: 'user-2',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const [],
      dependsOn: const ['task-1'],
      blocks: const [],
      attachedDocumentIds: const ['doc-ui-mockups'],
      chatRoomId: 'chat-task-2',
      knowledgeReward: 20,
      dueDate: DateTime.now().add(const Duration(days: 10)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      isDrifting: false,
      isBlocked: true,
    ),
    Task(
      id: 'task-3',
      title: 'Set up CI/CD Pipeline',
      description: 'Automate testing and deployment process',
      questDocument: '''# CI/CD Pipeline Quest

## Objective
Set up automated testing and deployment pipeline for lifeOS.

## Requirements
- [ ] GitHub Actions workflow
- [ ] Automated testing on PR
- [ ] Code quality checks
- [ ] Automated deployment to staging
- [ ] Production deployment approval

## Tools
- GitHub Actions
- Flutter test framework
- Firebase App Distribution
- App Store Connect API

## Success Criteria
- All tests pass automatically
- Code coverage > 80%
- Deployment time < 10 minutes
''',
      status: TaskStatus.done,
      priority: TaskPriority.high,
      estimatedHours: 12.0,
      actualHours: 14.0,
      timeSpent: 14.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-3-1',
          taskId: 'task-3',
          userId: 'user-4',
          userName: 'David Wilson',
          userAvatar: 'https://i.pravatar.cc/150?img=4',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(days: 10)),
          assignedBy: 'user-admin',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const [],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const ['doc-cicd-config'],
      chatRoomId: 'chat-task-3',
      knowledgeReward: 30,
      gratificationRating: 5,
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      startDate: DateTime.now().subtract(const Duration(days: 8)),
      completedDate: DateTime.now().subtract(const Duration(days: 1)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-4',
      title: 'Research AI Integration Options',
      description:
          'Explore different AI services for lifeOS assistant features',
      questDocument: '''# AI Integration Research Quest

## Objective
Research and evaluate AI services for integration into lifeOS.

## Areas to Research
- [ ] OpenAI GPT-4 API
- [ ] Google Gemini API
- [ ] Anthropic Claude API
- [ ] Local LLM options
- [ ] Cost analysis

## Evaluation Criteria
- Response quality
- Latency
- Cost per request
- Privacy considerations
- Integration complexity

## Deliverables
- Comparison matrix
- Proof of concept implementations
- Recommendation report
''',
      status: TaskStatus.backlog,
      priority: TaskPriority.low,
      estimatedHours: 8.0,
      timeSpent: 0.0,
      questTeam: const [],
      projectId: 'project-2',
      projectName: 'AI Assistant Features',
      subtaskIds: const [],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const [],
      chatRoomId: 'chat-task-4',
      knowledgeReward: 15,
      dueDate: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-5',
      title: 'Optimize App Performance',
      description: 'Improve app startup time and reduce memory usage',
      questDocument: '''# Performance Optimization Quest

## Objective
Optimize lifeOS mobile app for better performance and user experience.

## Performance Issues
- [ ] Slow app startup (>3 seconds)
- [ ] High memory usage
- [ ] Laggy animations
- [ ] Large app bundle size

## Optimization Strategies
- Code splitting and lazy loading
- Image optimization
- Database query optimization
- Widget tree optimization
- Bundle size analysis

## Success Metrics
- App startup < 2 seconds
- Memory usage < 100MB
- 60fps animations
- Bundle size < 50MB
''',
      status: TaskStatus.inProgress,
      priority: TaskPriority.urgent,
      estimatedHours: 20.0,
      actualHours: 12.0,
      timeSpent: 12.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-5-1',
          taskId: 'task-5',
          userId: 'user-1',
          userName: 'Alex Chen',
          userAvatar: 'https://i.pravatar.cc/150?img=1',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(days: 7)),
          assignedBy: 'user-admin',
        ),
        TaskAssignment(
          id: 'assignment-5-2',
          taskId: 'task-5',
          userId: 'user-4',
          userName: 'David Wilson',
          userAvatar: 'https://i.pravatar.cc/150?img=4',
          role: TeamRole.builder,
          assignedAt: DateTime.now().subtract(const Duration(days: 5)),
          assignedBy: 'user-1',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const ['task-5-1', 'task-5-2', 'task-5-3'],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const ['doc-performance-audit'],
      chatRoomId: 'chat-task-5',
      knowledgeReward: 35,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 4)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-6',
      title: 'Write API Documentation',
      description: 'Create comprehensive documentation for lifeOS backend API',
      questDocument: '''# API Documentation Quest

## Objective
Create comprehensive, developer-friendly documentation for the lifeOS backend API.

## Documentation Scope
- [ ] Authentication endpoints
- [ ] User management
- [ ] Task management
- [ ] Project management
- [ ] Chat system
- [ ] File uploads

## Documentation Format
- OpenAPI/Swagger specification
- Interactive API explorer
- Code examples in multiple languages
- Error handling guide
- Rate limiting information

## Tools
- Swagger/OpenAPI
- Postman collections
- Documentation hosting
''',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      estimatedHours: 16.0,
      timeSpent: 0.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-6-1',
          taskId: 'task-6',
          userId: 'user-5',
          userName: 'Emma Davis',
          userAvatar: 'https://i.pravatar.cc/150?img=5',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(hours: 12)),
          assignedBy: 'user-admin',
        ),
      ],
      projectId: 'project-3',
      projectName: 'Developer Experience',
      subtaskIds: const [],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const [],
      chatRoomId: 'chat-task-6',
      knowledgeReward: 20,
      dueDate: DateTime.now().add(const Duration(days: 14)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 12)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-7',
      title: 'Implement Dark Mode',
      description: 'Add dark mode support across the entire application',
      questDocument: '''# Dark Mode Implementation Quest

## Objective
Implement comprehensive dark mode support for lifeOS with smooth transitions.

## Requirements
- [ ] Dark theme color palette
- [ ] Theme switching mechanism
- [ ] Persistent theme preference
- [ ] Smooth theme transitions
- [ ] All screens support dark mode

## Design Considerations
- Accessibility compliance
- Battery optimization on OLED screens
- Consistent color usage
- Proper contrast ratios

## Implementation
- Theme provider setup
- Color scheme definitions
- Widget theme overrides
- Animation transitions
''',
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
      estimatedHours: 10.0,
      actualHours: 6.0,
      timeSpent: 6.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-7-1',
          taskId: 'task-7',
          userId: 'user-2',
          userName: 'Sarah Kim',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          role: TeamRole.leader,
          assignedAt: DateTime.now().subtract(const Duration(days: 4)),
          assignedBy: 'user-admin',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const [],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const ['doc-dark-theme-spec'],
      chatRoomId: 'chat-task-7',
      knowledgeReward: 15,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      startDate: DateTime.now().subtract(const Duration(days: 4)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-8',
      title: 'Security Audit',
      description: 'Conduct comprehensive security audit of the application',
      questDocument: '''# Security Audit Quest

## Objective
Perform thorough security audit to identify and fix vulnerabilities.

## Audit Areas
- [ ] Authentication security
- [ ] Data encryption
- [ ] API security
- [ ] Input validation
- [ ] Session management
- [ ] Third-party dependencies

## Security Checklist
- OWASP Mobile Top 10
- Data protection compliance
- Secure coding practices
- Penetration testing
- Vulnerability scanning

## Deliverables
- Security audit report
- Vulnerability fixes
- Security best practices guide
- Compliance documentation
''',
      status: TaskStatus.backlog,
      priority: TaskPriority.high,
      estimatedHours: 32.0,
      timeSpent: 0.0,
      questTeam: const [],
      projectId: 'project-4',
      projectName: 'Security & Compliance',
      subtaskIds: const [],
      dependsOn: const ['task-1'],
      blocks: const [],
      attachedDocumentIds: const [],
      chatRoomId: 'chat-task-8',
      knowledgeReward: 40,
      dueDate: DateTime.now().add(const Duration(days: 45)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-9',
      title: 'User Onboarding Flow',
      description: 'Design and implement smooth user onboarding experience',
      questDocument: '''# User Onboarding Quest

## Objective
Create an engaging and informative onboarding flow for new users.

## Onboarding Steps
- [ ] Welcome screen
- [ ] Feature highlights
- [ ] Account setup
- [ ] Preferences configuration
- [ ] First task creation
- [ ] Tutorial completion

## Design Principles
- Progressive disclosure
- Interactive tutorials
- Minimal cognitive load
- Clear value proposition
- Easy skip options

## Success Metrics
- Onboarding completion rate > 80%
- Time to first task < 5 minutes
- User retention after 7 days > 60%
''',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      estimatedHours: 18.0,
      timeSpent: 0.0,
      questTeam: [
        TaskAssignment(
          id: 'assignment-9-1',
          taskId: 'task-9',
          userId: 'user-2',
          userName: 'Sarah Kim',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          role: TeamRole.designer,
          assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
          assignedBy: 'user-admin',
        ),
        TaskAssignment(
          id: 'assignment-9-2',
          taskId: 'task-9',
          userId: 'user-3',
          userName: 'Mike Johnson',
          userAvatar: 'https://i.pravatar.cc/150?img=3',
          role: TeamRole.builder,
          assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
          assignedBy: 'user-admin',
        ),
      ],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const [],
      dependsOn: const ['task-1', 'task-2'],
      blocks: const [],
      attachedDocumentIds: const ['doc-onboarding-flow'],
      chatRoomId: 'chat-task-9',
      knowledgeReward: 25,
      dueDate: DateTime.now().add(const Duration(days: 21)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      isDrifting: false,
      isBlocked: false,
    ),
    Task(
      id: 'task-10',
      title: 'Notification System',
      description:
          'Implement push notifications and in-app notification system',
      questDocument: '''# Notification System Quest

## Objective
Build comprehensive notification system for lifeOS with multiple delivery channels.

## Notification Types
- [ ] Task reminders
- [ ] Team mentions
- [ ] Project updates
- [ ] System announcements
- [ ] Achievement notifications

## Delivery Channels
- Push notifications
- In-app notifications
- Email notifications
- SMS (optional)

## Features
- Notification preferences
- Do not disturb mode
- Notification history
- Smart batching
- Rich notifications

## Technical Implementation
- Firebase Cloud Messaging
- Local notifications
- Background processing
- Notification scheduling
''',
      status: TaskStatus.backlog,
      priority: TaskPriority.medium,
      estimatedHours: 22.0,
      timeSpent: 0.0,
      questTeam: const [],
      projectId: 'project-1',
      projectName: 'lifeOS Mobile App',
      subtaskIds: const [],
      dependsOn: const [],
      blocks: const [],
      attachedDocumentIds: const [],
      chatRoomId: 'chat-task-10',
      knowledgeReward: 30,
      dueDate: DateTime.now().add(const Duration(days: 35)),
      createdBy: 'user-admin',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      isDrifting: false,
      isBlocked: false,
    ),
  ];

  // Simulate network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<Task>> getAllTasks() async {
    await _simulateDelay();
    return List<Task>.from(_mockTasks);
  }

  Future<Task?> getTaskById(String id) async {
    await _simulateDelay();
    try {
      return _mockTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Task>> getTasksByProject(String projectId) async {
    await _simulateDelay();
    return _mockTasks.where((task) => task.projectId == projectId).toList();
  }

  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    await _simulateDelay();
    return _mockTasks.where((task) => task.status == status).toList();
  }

  Future<List<Task>> getTasksByAssignee(String userId) async {
    await _simulateDelay();
    return _mockTasks.where((task) {
      return task.questTeam.any((assignment) => assignment.userId == userId);
    }).toList();
  }

  Future<Task> createTask(Task task) async {
    await _simulateDelay();

    // Generate new ID
    final newId = 'task-${DateTime.now().millisecondsSinceEpoch}';

    // Create a new task with the generated ID
    Task newTask = Task(
      id: newId,
      title: task.title,
      description: task.description,
      questDocument: task.questDocument,
      status: task.status,
      priority: task.priority,
      estimatedHours: task.estimatedHours,
      actualHours: task.actualHours,
      timeSpent: task.timeSpent,
      questTeam: task.questTeam,
      projectId: task.projectId,
      projectName: task.projectName,
      goalId: task.goalId,
      parentTaskId: task.parentTaskId,
      chatRoomId: 'chat-$newId', // Auto-create chat room
      knowledgeReward: task.knowledgeReward,
      gratificationRating: task.gratificationRating,
      dueDate: task.dueDate,
      startDate: task.startDate,
      completedDate: task.completedDate,
      createdBy: task.createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActivity: task.lastActivity,
      isDrifting: task.isDrifting,
      isBlocked: task.isBlocked,
      subtaskIds: task.subtaskIds,
      dependsOn: task.dependsOn,
      blocks: task.blocks,
      attachedDocumentIds: task.attachedDocumentIds,
    );

    _mockTasks.add(newTask);
    return newTask;
  }

  Future<Task> updateTask(Task task) async {
    await _simulateDelay();

    final index = _mockTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      throw Exception('Task not found');
    }

    // Create a new task with updated timestamp
    Task updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      questDocument: task.questDocument,
      status: task.status,
      priority: task.priority,
      estimatedHours: task.estimatedHours,
      actualHours: task.actualHours,
      timeSpent: task.timeSpent,
      questTeam: task.questTeam,
      projectId: task.projectId,
      projectName: task.projectName,
      goalId: task.goalId,
      parentTaskId: task.parentTaskId,
      chatRoomId: task.chatRoomId ?? 'chat-${task.id}',
      knowledgeReward: task.knowledgeReward,
      gratificationRating: task.gratificationRating,
      dueDate: task.dueDate,
      startDate: task.startDate,
      completedDate: task.completedDate,
      createdBy: task.createdBy,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      lastActivity: task.lastActivity,
      isDrifting: task.isDrifting,
      isBlocked: task.isBlocked,
      subtaskIds: task.subtaskIds,
      dependsOn: task.dependsOn,
      blocks: task.blocks,
      attachedDocumentIds: task.attachedDocumentIds,
    );

    _mockTasks[index] = updatedTask;
    return updatedTask;
  }

  Future<void> deleteTask(String id) async {
    await _simulateDelay();

    final index = _mockTasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw Exception('Task not found');
    }

    _mockTasks.removeAt(index);
  }

  Future<List<Task>> searchTasks(String query) async {
    await _simulateDelay();

    final lowercaseQuery = query.toLowerCase();
    return _mockTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.projectName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Helper method to get unique project names
  List<String> getUniqueProjects() {
    final projects = <String>{};
    for (final task in _mockTasks) {
      projects.add(task.projectName);
    }
    return projects.toList()..sort();
  }

  // Helper method to get unique assignees
  List<String> getUniqueAssignees() {
    final assignees = <String>{};
    for (final task in _mockTasks) {
      for (final assignment in task.questTeam) {
        assignees.add(assignment.userName);
      }
    }
    return assignees.toList()..sort();
  }

  // Simulate task statistics
  Map<String, int> getTaskStatistics() {
    final stats = <String, int>{
      'total': _mockTasks.length,
      'backlog': 0,
      'todo': 0,
      'inProgress': 0,
      'done': 0,
      'cancelled': 0,
      'overdue': 0,
      'drifting': 0,
      'blocked': 0,
    };

    for (final task in _mockTasks) {
      stats[task.status.value] = (stats[task.status.value] ?? 0) + 1;

      if (task.isOverdue) {
        stats['overdue'] = (stats['overdue'] ?? 0) + 1;
      }

      if (task.isDrifting) {
        stats['drifting'] = (stats['drifting'] ?? 0) + 1;
      }

      if (task.isBlocked) {
        stats['blocked'] = (stats['blocked'] ?? 0) + 1;
      }
    }

    return stats;
  }
}
