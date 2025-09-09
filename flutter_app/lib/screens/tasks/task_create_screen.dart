import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/task.dart';
import '../../widgets/layout/four_panel_layout.dart';

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  DateTime? _selectedDueDate;
  DateTime? _selectedStartDate;

  @override
  void initState() {
    super.initState();
    // Set default project name
    _projectController.text = 'Personal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure navigation state is set to tasks
    Future.microtask(() {
      ref
          .read(navigationProvider.notifier)
          .setActiveFeature(AppConstants.navTasks);
    });

    return FourPanelLayout(
      title: 'Create New Quest',
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => context.go('/tasks'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppConstants.spacingS),

        // Save Button
        ElevatedButton(
          onPressed: _saveTask,
          child: const Text('Create Quest'),
        ),
      ],
      child: _buildCreateForm(context),
    );
  }

  Widget _buildCreateForm(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Card
            _buildBasicInfoCard(context, theme),
            const SizedBox(height: AppConstants.spacingL),

            // Details Card
            _buildDetailsCard(context, theme),
            const SizedBox(height: AppConstants.spacingL),

            // Scheduling Card
            _buildSchedulingCard(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quest Title *',
                hintText: 'Enter a descriptive title for your quest',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quest title';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this quest involves...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Project Field
            TextFormField(
              controller: _projectController,
              decoration: const InputDecoration(
                labelText: 'Project *',
                hintText: 'Which project does this quest belong to?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quest Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Priority and Status Row
            Row(
              children: [
                // Priority Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      DropdownButtonFormField<TaskPriority>(
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingM,
                            vertical: AppConstants.spacingS,
                          ),
                        ),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(priority),
                                  size: 16,
                                  color: _getPriorityColor(priority),
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Text(priority.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (priority) {
                          if (priority != null) {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppConstants.spacingM),

                // Status Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initial Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      DropdownButtonFormField<TaskStatus>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingM,
                            vertical: AppConstants.spacingS,
                          ),
                        ),
                        items: [
                          TaskStatus.backlog,
                          TaskStatus.todo,
                          TaskStatus.inProgress,
                        ].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 16,
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Text(status.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (status) {
                          if (status != null) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Estimated Hours Field
            TextFormField(
              controller: _estimatedHoursController,
              decoration: const InputDecoration(
                labelText: 'Estimated Hours',
                hintText: 'How many hours do you estimate this will take?',
                border: OutlineInputBorder(),
                suffixText: 'hours',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final hours = double.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return 'Please enter a valid number of hours';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Start Date
            _buildDateField(
              context,
              theme,
              'Start Date',
              _selectedStartDate,
              (date) => setState(() => _selectedStartDate = date),
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Due Date
            _buildDateField(
              context,
              theme,
              'Due Date',
              _selectedDueDate,
              (date) => setState(() => _selectedDueDate = date),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    ThemeData theme,
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        InkWell(
          onTap: () => _selectDate(context, selectedDate, onDateSelected),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate)
                        : 'Select $label',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (selectedDate != null)
                  IconButton(
                    onPressed: () => onDateSelected(null),
                    icon: const Icon(Icons.clear, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime?) onDateSelected,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate != null) {
      onDateSelected(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final estimatedHours = _estimatedHoursController.text.isNotEmpty
        ? double.tryParse(_estimatedHoursController.text)
        : null;

    final title = _titleController.text.trim();
    final projectId =
        _projectController.text.trim().toLowerCase().replaceAll(' ', '_');

    // Add task to provider
    ref.read(taskProvider.notifier).createTask(
          title: title,
          description: _descriptionController.text.trim(),
          projectId: projectId,
          createdBy: 'current_user', // TODO: Get from auth provider
          questDocument: '',
          status: _selectedStatus,
          priority: _selectedPriority,
          estimatedHours: estimatedHours,
          dueDate: _selectedDueDate,
          startDate: _selectedStartDate,
          knowledgeReward: 10,
        );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest "$title" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to tasks
    context.go('/tasks');
  }

  // Helper methods for icons and colors
  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Icons.priority_high;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.none:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.none:
        return Colors.grey;
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
}
