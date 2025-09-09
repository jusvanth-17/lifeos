import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class GoalsSecondarySidebar extends ConsumerWidget {
  const GoalsSecondarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Goals Hierarchy
        Expanded(
          child: _buildGoalsHierarchy(context, theme),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'OKR Goals',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add new goal
            },
            icon: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Add Goal',
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsHierarchy(BuildContext context, ThemeData theme) {
    // Mock data for now
    final goals = _getMockGoals();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      children: [
        for (final goal in goals) _buildGoalItem(context, theme, goal),
      ],
    );
  }

  Widget _buildGoalItem(BuildContext context, ThemeData theme, MockGoal goal) {
    return ExpansionTile(
      leading: Icon(
        Icons.flag_outlined,
        color: theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        goal.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${goal.progress}% complete',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        // Projects under this goal
        for (final project in goal.projects)
          _buildProjectItem(context, theme, project),
      ],
    );
  }

  Widget _buildProjectItem(
      BuildContext context, ThemeData theme, MockProject project) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.spacingL),
      child: ExpansionTile(
        leading: Icon(
          Icons.folder_outlined,
          color: theme.colorScheme.secondary,
          size: 18,
        ),
        title: Text(
          project.title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${project.milestones.length} milestones',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        children: [
          // Milestones under this project
          for (final milestone in project.milestones)
            _buildMilestoneItem(context, theme, milestone),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(
      BuildContext context, ThemeData theme, MockMilestone milestone) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.spacingXL),
      child: ListTile(
        dense: true,
        leading: Icon(
          milestone.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: milestone.isCompleted
              ? Colors.green
              : theme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        title: Text(
          milestone.title,
          style: theme.textTheme.bodySmall?.copyWith(
            decoration:
                milestone.isCompleted ? TextDecoration.lineThrough : null,
            color: milestone.isCompleted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: milestone.dueDate != null
            ? Text(
                'Due: ${milestone.dueDate}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              )
            : null,
      ),
    );
  }

  List<MockGoal> _getMockGoals() {
    return [
      MockGoal(
        title: 'Improve Personal Productivity',
        progress: 65,
        projects: [
          MockProject(
            title: 'Build lifeOS App',
            milestones: [
              MockMilestone(title: 'Design UI/UX', isCompleted: true),
              MockMilestone(
                  title: 'Implement Navigation',
                  isCompleted: false,
                  dueDate: 'Jan 15'),
              MockMilestone(
                  title: 'Add Task Management',
                  isCompleted: false,
                  dueDate: 'Jan 30'),
            ],
          ),
          MockProject(
            title: 'Establish Morning Routine',
            milestones: [
              MockMilestone(title: 'Wake up at 6 AM', isCompleted: true),
              MockMilestone(title: 'Exercise daily', isCompleted: false),
            ],
          ),
        ],
      ),
      MockGoal(
        title: 'Learn New Technologies',
        progress: 30,
        projects: [
          MockProject(
            title: 'Master Flutter Development',
            milestones: [
              MockMilestone(
                  title: 'Complete Flutter course',
                  isCompleted: false,
                  dueDate: 'Feb 15'),
              MockMilestone(title: 'Build 3 apps', isCompleted: false),
            ],
          ),
        ],
      ),
    ];
  }
}

class MockGoal {
  final String title;
  final int progress;
  final List<MockProject> projects;

  MockGoal({
    required this.title,
    required this.progress,
    required this.projects,
  });
}

class MockProject {
  final String title;
  final List<MockMilestone> milestones;

  MockProject({
    required this.title,
    required this.milestones,
  });
}

class MockMilestone {
  final String title;
  final bool isCompleted;
  final String? dueDate;

  MockMilestone({
    required this.title,
    required this.isCompleted,
    this.dueDate,
  });
}
