import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class DocumentsSecondarySidebar extends ConsumerWidget {
  const DocumentsSecondarySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Search
        _buildSearch(context, theme),

        // Folder Structure and Filters
        Expanded(
          child: _buildFolderStructure(context, theme),
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
            Icons.description,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add new document
            },
            icon: Icon(
              Icons.add,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'New Document',
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search documents...',
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: BorderSide(color: theme.colorScheme.outline),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
        ),
      ),
    );
  }

  Widget _buildFolderStructure(BuildContext context, ThemeData theme) {
    return ListView(
      children: [
        // Quick Filters
        _buildQuickFilters(context, theme),

        const Divider(),

        // Folder Structure
        _buildFolderTree(context, theme),
      ],
    );
  }

  Widget _buildQuickFilters(BuildContext context, ThemeData theme) {
    final filters = [
      {'icon': Icons.schedule, 'label': 'Recent', 'count': 12},
      {'icon': Icons.star, 'label': 'Starred', 'count': 5},
      {'icon': Icons.share, 'label': 'Shared with me', 'count': 8},
      {'icon': Icons.delete_outline, 'label': 'Trash', 'count': 3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'Quick Access',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final filter in filters)
          ListTile(
            dense: true,
            leading: Icon(
              filter['icon'] as IconData,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              filter['label'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Text(
              '${filter['count']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              // TODO: Apply filter
            },
          ),
      ],
    );
  }

  Widget _buildFolderTree(BuildContext context, ThemeData theme) {
    final folders = _getMockFolders();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'Folders',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        for (final folder in folders) _buildFolderItem(context, theme, folder),
      ],
    );
  }

  Widget _buildFolderItem(
      BuildContext context, ThemeData theme, MockFolder folder) {
    return ExpansionTile(
      leading: Icon(
        Icons.folder,
        color: Colors.amber[700],
        size: 20,
      ),
      title: Text(
        folder.name,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${folder.documents.length} documents',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        for (final doc in folder.documents)
          _buildDocumentItem(context, theme, doc),
      ],
    );
  }

  Widget _buildDocumentItem(
      BuildContext context, ThemeData theme, MockDocument doc) {
    IconData getDocIcon(String type) {
      switch (type.toLowerCase()) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow;
        default:
          return Icons.insert_drive_file;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.spacingL),
      child: ListTile(
        dense: true,
        leading: Icon(
          getDocIcon(doc.type),
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          doc.name,
          style: theme.textTheme.bodySmall,
        ),
        subtitle: Text(
          '${doc.type.toUpperCase()} • ${doc.size} • ${doc.modified}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        onTap: () {
          // TODO: Open document
        },
      ),
    );
  }

  List<MockFolder> _getMockFolders() {
    return [
      MockFolder(
        name: 'Projects',
        documents: [
          MockDocument(
              name: 'lifeOS Spec.pdf',
              type: 'pdf',
              size: '2.1 MB',
              modified: '2 days ago'),
          MockDocument(
              name: 'UI Mockups.fig',
              type: 'fig',
              size: '5.3 MB',
              modified: '1 week ago'),
        ],
      ),
      MockFolder(
        name: 'Meeting Notes',
        documents: [
          MockDocument(
              name: 'Sprint Planning.docx',
              type: 'docx',
              size: '156 KB',
              modified: '3 days ago'),
          MockDocument(
              name: 'Team Standup.md',
              type: 'md',
              size: '12 KB',
              modified: '1 day ago'),
        ],
      ),
      MockFolder(
        name: 'Resources',
        documents: [
          MockDocument(
              name: 'Flutter Guide.pdf',
              type: 'pdf',
              size: '8.7 MB',
              modified: '1 month ago'),
          MockDocument(
              name: 'Design System.sketch',
              type: 'sketch',
              size: '15.2 MB',
              modified: '2 weeks ago'),
        ],
      ),
    ];
  }
}

class MockFolder {
  final String name;
  final List<MockDocument> documents;

  MockFolder({
    required this.name,
    required this.documents,
  });
}

class MockDocument {
  final String name;
  final String type;
  final String size;
  final String modified;

  MockDocument({
    required this.name,
    required this.type,
    required this.size,
    required this.modified,
  });
}
