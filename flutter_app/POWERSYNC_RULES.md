# PowerSync Sync Rules - Simplified Version

These are simplified sync rules that avoid all complex queries to ensure compatibility with PowerSync limitations.

## Sync Rules

```yaml
# Define sync rules to control which data is synced to each user
# See the docs: https://docs.powersync.com/usage/sync-rules

bucket_definitions:
  # Global bucket for data that should be available to all users
  global:
    data:
      # Sync all users so everyone can see each other for chat creation
      - SELECT * FROM public.users

      # Sync all projects (could be limited to public projects in production)
      - SELECT * FROM public.projects

  # User-specific bucket for data that belongs to the current user
  by_user:
    # Get the current user's ID
    parameters: SELECT request.user_id() as user_id
    data:
      # User's WebAuthn credentials
      - SELECT * FROM public.webauthn_credentials WHERE user_id = bucket.user_id

      # User's sessions
      - SELECT * FROM public.user_sessions WHERE user_id = bucket.user_id

      # Tasks created by the user
      - SELECT * FROM public.tasks WHERE created_by = bucket.user_id

      # Task assignments for the user
      - SELECT * FROM public.task_assignments WHERE user_id = bucket.user_id

      # Documents created by the user
      - SELECT * FROM public.documents WHERE created_by = bucket.user_id

  # Team bucket for data related to teams the user is a member of
  by_team:
    # Get all teams the user is a member of
    parameters: SELECT team_id FROM public.team_members WHERE user_id = request.user_id()
    data:
      # Team details
      - SELECT * FROM public.teams WHERE id = bucket.team_id

      # Team members
      - SELECT * FROM public.team_members WHERE team_id = bucket.team_id

      # Project members for this team
      - SELECT * FROM public.project_members WHERE team_id = bucket.team_id

  # Project bucket for data related to projects the user has access to
  by_project:
    # Get all projects the user has access to (direct access)
    parameters: SELECT project_id FROM public.project_members WHERE user_id = request.user_id()
    data:
      # Project details
      - SELECT * FROM public.projects WHERE id = bucket.project_id

      # Tasks in the project
      - SELECT * FROM public.tasks WHERE project_id = bucket.project_id

  # Chat bucket for data related to chats the user is a participant in
  by_chat:
    # Get all chats the user is a participant in
    parameters: SELECT chat_id FROM public.chat_participants WHERE user_id = request.user_id()
    data:
      # Chat details
      - SELECT * FROM public.chats WHERE id = bucket.chat_id

      # Chat participants
      - SELECT * FROM public.chat_participants WHERE chat_id = bucket.chat_id

      # Chat messages for this chat
      - SELECT * FROM public.chat_messages WHERE chat_id = bucket.chat_id

  # Task bucket for tasks the user is assigned to
  by_task:
    # Get all tasks the user is assigned to
    parameters: SELECT task_id FROM public.task_assignments WHERE user_id = request.user_id()
    data:
      # Task details
      - SELECT * FROM public.tasks WHERE id = bucket.task_id

      # Task assignments
      - SELECT * FROM public.task_assignments WHERE task_id = bucket.task_id

      # Task dependencies
      - SELECT * FROM public.task_dependencies WHERE task_id = bucket.task_id OR depends_on_task_id = bucket.task_id

      # Task documents
      - SELECT * FROM public.task_documents WHERE task_id = bucket.task_id
```

## Notes on Sync Rules

1. **Simplified Approach**: These rules have been simplified to avoid all complex queries and subqueries that might not be supported by PowerSync.

2. **Limited Relationships**: Some data relationships that were previously handled through subqueries have been removed to ensure compatibility.

3. **Core Functionality**: The rules focus on providing the core functionality while maintaining compatibility with PowerSync's limitations.

4. **No Subqueries**: All subqueries have been eliminated from both the parameters and data sections.

5. **Reduced Buckets**: The number of buckets has been reduced to simplify the configuration.
