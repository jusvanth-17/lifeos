import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task.dart';

class TasksGraphView extends ConsumerWidget {
  const TasksGraphView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasks = ref.watch(filteredTasksProvider);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graph Controls
          _buildGraphControls(context, ref),

          const SizedBox(height: AppConstants.spacingL),

          // Graph Visualization
          _buildGraphVisualization(context, filteredTasks),

          const SizedBox(height: AppConstants.spacingL),

          // Legend
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'No quest dependencies to visualize',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Create quests with dependencies to see the relationship graph.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphControls(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            'Graph Controls',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),

          // Layout Toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'hierarchical',
                label: Text('Hierarchical'),
                icon: Icon(Icons.account_tree, size: 16),
              ),
              ButtonSegment(
                value: 'circular',
                label: Text('Circular'),
                icon: Icon(Icons.radio_button_unchecked, size: 16),
              ),
              ButtonSegment(
                value: 'force',
                label: Text('Force'),
                icon: Icon(Icons.scatter_plot, size: 16),
              ),
            ],
            selected: const {'hierarchical'},
            onSelectionChanged: (Set<String> selection) {
              // TODO: Handle layout change
            },
          ),

          const SizedBox(width: AppConstants.spacingM),

          // Zoom Controls
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Zoom out
                },
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom Out',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Reset zoom
                },
                icon: const Icon(Icons.center_focus_strong),
                tooltip: 'Reset View',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Zoom in
                },
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom In',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphVisualization(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // Background Grid
          CustomPaint(
            size: const Size.fromHeight(600),
            painter: GridPainter(theme: theme),
          ),

          // Graph Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_tree,
                  size: 48,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Interactive Dependency Graph',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Coming Soon',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // Mock Graph Nodes
                _buildMockGraphNodes(context, tasks.take(5).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockGraphNodes(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppConstants.spacingL,
      runSpacing: AppConstants.spacingL,
      children: tasks.map((task) {
        return Container(
          width: 120,
          height: 80,
          padding: const EdgeInsets.all(AppConstants.spacingS),
          decoration: BoxDecoration(
            color: _getStatusColor(task.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: _getStatusColor(task.status),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(task.status),
                color: _getStatusColor(task.status),
                size: 20,
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                task.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Wrap(
            spacing: AppConstants.spacingL,
            runSpacing: AppConstants.spacingM,
            children: [
              _buildLegendItem(
                context,
                'Dependencies',
                Icons.arrow_forward,
                theme.colorScheme.primary,
                'Solid arrows show task dependencies',
              ),
              _buildLegendItem(
                context,
                'Blocking',
                Icons.block,
                Colors.red,
                'Red indicates blocked tasks',
              ),
              _buildLegendItem(
                context,
                'In Progress',
                Icons.play_circle,
                Colors.orange,
                'Orange shows active tasks',
              ),
              _buildLegendItem(
                context,
                'Completed',
                Icons.check_circle,
                Colors.green,
                'Green indicates completed tasks',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String description,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppConstants.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Colors.grey;
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Icons.inbox;
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class GridPainter extends CustomPainter {
  final ThemeData theme;

  GridPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
