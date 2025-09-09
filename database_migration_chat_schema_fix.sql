-- Chat System Database Schema Migration
-- This migration fixes the schema mismatch between the application and database

-- First, backup existing chat data if any
CREATE TABLE IF NOT EXISTS chats_backup AS SELECT * FROM chats;

-- Drop the old simple chats table
DROP TABLE IF EXISTS chats;

-- Create the comprehensive chats table matching the application expectations
CREATE TABLE chats (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT,
    type TEXT NOT NULL DEFAULT 'direct', -- direct, group, team, project, task
    is_private INTEGER DEFAULT 1,
    team_id TEXT,
    project_id TEXT,
    task_id TEXT,
    last_message_id TEXT,
    last_message_at TEXT,
    message_count INTEGER DEFAULT 0,
    allow_ai_assistant INTEGER DEFAULT 1,
    notification_settings TEXT, -- JSON string
    created_by TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE SET NULL,
    FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
);

-- Create chat_messages table for storing all messages
CREATE TABLE chat_messages (
    id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL,
    content TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text', -- text, file, image, system, ai_response
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_avatar TEXT,
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    is_edited INTEGER DEFAULT 0,
    reply_to_id TEXT,
    thread_count INTEGER DEFAULT 0,
    reactions TEXT, -- JSON string: {"emoji": ["user_id1", "user_id2"]}
    mentions TEXT, -- JSON array: ["user_id1", "user_id2"]
    ai_context TEXT, -- JSON object for AI responses
    call_type TEXT, -- voice, video, screen_share
    call_status TEXT, -- initiated, ringing, answered, declined, ended, missed
    call_duration INTEGER, -- in seconds
    call_participants TEXT, -- JSON array of participant IDs
    FOREIGN KEY (room_id) REFERENCES chats (id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (reply_to_id) REFERENCES chat_messages (id) ON DELETE SET NULL
);

-- Create chat_participants table for managing chat participants
CREATE TABLE chat_participants (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_avatar TEXT,
    is_admin INTEGER DEFAULT 0,
    is_online INTEGER DEFAULT 0,
    last_seen TEXT,
    is_typing INTEGER DEFAULT 0,
    joined_at TEXT NOT NULL,
    FOREIGN KEY (chat_id) REFERENCES chats (id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    UNIQUE(chat_id, user_id) -- Prevent duplicate participants
);

-- Create indexes for better performance
CREATE INDEX idx_chats_created_by ON chats(created_by);
CREATE INDEX idx_chats_type ON chats(type);
CREATE INDEX idx_chats_created_at ON chats(created_at);

CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_room_created ON chat_messages(room_id, created_at);

CREATE INDEX idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX idx_chat_participants_online ON chat_participants(is_online);

-- Migrate any existing chat data from backup (if needed)
-- Note: This assumes the old schema had basic fields, adjust as needed
INSERT INTO chats (id, name, created_by, created_at, updated_at, type)
SELECT 
    id,
    title as name,
    user_id as created_by,
    created_at,
    updated_at,
    'direct' as type
FROM chats_backup
WHERE EXISTS (SELECT 1 FROM chats_backup);

-- Clean up backup table
DROP TABLE IF EXISTS chats_backup;

-- Insert some sample data for testing (optional - remove in production)
-- This will help verify the schema works correctly
/*
INSERT INTO chats (
    id, name, description, type, created_by, created_at, updated_at
) VALUES (
    'chat_test_' || datetime('now'),
    'Test Chat',
    'Sample chat for testing',
    'group',
    'user_1a4f96481178',
    datetime('now'),
    datetime('now')
);
*/
