-- Supabase Database Schema for Group Chat System
-- This script sets up all necessary tables with proper RLS policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- =============================================
-- USERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL DEFAULT 'Unknown User',
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can read all users (for discovery and chat participants)
CREATE POLICY "Users can view all users" ON public.users
  FOR SELECT USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (during signup)
CREATE POLICY "Users can insert their own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- CHATS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group', 'team', 'project', 'task')),
  is_private BOOLEAN DEFAULT true,
  team_id UUID,
  project_id UUID,
  task_id UUID,
  last_message_id UUID,
  last_message_at TIMESTAMP WITH TIME ZONE,
  message_count INTEGER DEFAULT 0,
  allow_ai_assistant BOOLEAN DEFAULT true,
  notification_settings JSONB DEFAULT '{"all_messages": true, "mentions_only": false, "muted": false}'::jsonb,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for chats
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

-- Users can view chats they are participants in
CREATE POLICY "Users can view chats they participate in" ON public.chats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants 
      WHERE chat_id = chats.id AND user_id = auth.uid()
    )
    OR created_by = auth.uid()
  );

-- Users can insert chats they create
CREATE POLICY "Users can create chats" ON public.chats
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- Users can update chats they created or are admins of
CREATE POLICY "Users can update chats they created" ON public.chats
  FOR UPDATE USING (created_by = auth.uid());

-- =============================================
-- CHAT PARTICIPANTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.chat_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  user_avatar TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE,
  is_typing BOOLEAN DEFAULT false,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chat_id, user_id)
);

-- Enable RLS for chat participants
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;

-- Users can view participants of chats they are in
CREATE POLICY "Users can view chat participants" ON public.chat_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants cp 
      WHERE cp.chat_id = chat_participants.chat_id AND cp.user_id = auth.uid()
    )
  );

-- Users can insert participants if they are chat creator or admin
CREATE POLICY "Users can add participants" ON public.chat_participants
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id = chat_id AND created_by = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.chat_participants 
      WHERE chat_id = chat_participants.chat_id 
      AND user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Users can update their own participant record
CREATE POLICY "Users can update own participant status" ON public.chat_participants
  FOR UPDATE USING (user_id = auth.uid());

-- Users can remove participants if they are admin or removing themselves
CREATE POLICY "Users can remove participants" ON public.chat_participants
  FOR DELETE USING (
    user_id = auth.uid() -- Users can remove themselves
    OR EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id = chat_id AND created_by = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.chat_participants 
      WHERE chat_id = chat_participants.chat_id 
      AND user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- =============================================
-- CHAT MESSAGES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'file', 'image', 'system', 'aiResponse', 'call')),
  sender_id UUID NOT NULL REFERENCES public.users(id),
  sender_name TEXT NOT NULL,
  sender_avatar TEXT,
  room_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  reply_to_id UUID REFERENCES public.chat_messages(id),
  thread_count INTEGER DEFAULT 0,
  reactions JSONB DEFAULT '{}'::jsonb,
  mentions JSONB DEFAULT '[]'::jsonb,
  ai_context JSONB,
  call_type TEXT CHECK (call_type IN ('voice', 'video')),
  call_status TEXT CHECK (call_status IN ('answered', 'missed', 'declined', 'busy')),
  call_duration INTEGER, -- in seconds
  call_participants JSONB,
  is_edited BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS for chat messages
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats" ON public.chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants 
      WHERE chat_id = room_id AND user_id = auth.uid()
    )
  );

-- Users can insert messages in chats they participate in
CREATE POLICY "Users can send messages in their chats" ON public.chat_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.chat_participants 
      WHERE chat_id = room_id AND user_id = auth.uid()
    )
  );

-- Users can update their own messages
CREATE POLICY "Users can update their own messages" ON public.chat_messages
  FOR UPDATE USING (sender_id = auth.uid());

-- Users can delete their own messages
CREATE POLICY "Users can delete their own messages" ON public.chat_messages
  FOR DELETE USING (sender_id = auth.uid());

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Chat participants indexes
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_id ON public.chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON public.chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_user ON public.chat_participants(chat_id, user_id);

-- Chat messages indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON public.chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created ON public.chat_messages(room_id, created_at DESC);

-- Chats indexes
CREATE INDEX IF NOT EXISTS idx_chats_created_by ON public.chats(created_by);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON public.chats(updated_at DESC);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_display_name ON public.users(display_name);

-- =============================================
-- FUNCTIONS FOR AUTOMATIC OPERATIONS
-- =============================================

-- Function to automatically add chat creator as participant
CREATE OR REPLACE FUNCTION auto_add_chat_creator()
RETURNS TRIGGER AS $$
BEGIN
  -- Get user info for the creator
  INSERT INTO public.chat_participants (chat_id, user_id, user_name, user_avatar, role)
  SELECT 
    NEW.id,
    NEW.created_by,
    COALESCE(u.display_name, 'Unknown User'),
    u.avatar_url,
    'admin'
  FROM public.users u 
  WHERE u.id = NEW.created_by;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically add chat creator as participant
DROP TRIGGER IF EXISTS trigger_auto_add_chat_creator ON public.chats;
CREATE TRIGGER trigger_auto_add_chat_creator
  AFTER INSERT ON public.chats
  FOR EACH ROW
  EXECUTE FUNCTION auto_add_chat_creator();

-- Function to update chat's last message info
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chats 
  SET 
    last_message_id = NEW.id,
    last_message_at = NEW.created_at,
    message_count = message_count + 1,
    updated_at = NOW()
  WHERE id = NEW.room_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update chat info when message is sent
DROP TRIGGER IF EXISTS trigger_update_chat_last_message ON public.chat_messages;
CREATE TRIGGER trigger_update_chat_last_message
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_last_message();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS trigger_users_updated_at ON public.users;
CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_chats_updated_at ON public.chats;
CREATE TRIGGER trigger_chats_updated_at
  BEFORE UPDATE ON public.chats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_messages_updated_at ON public.chat_messages;
CREATE TRIGGER trigger_messages_updated_at
  BEFORE UPDATE ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- REAL-TIME SUBSCRIPTIONS SETUP
-- =============================================

-- Enable real-time for all chat-related tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;

-- Grant necessary permissions for real-time
GRANT SELECT ON public.chats TO anon, authenticated;
GRANT SELECT ON public.chat_participants TO anon, authenticated;
GRANT SELECT ON public.chat_messages TO anon, authenticated;
GRANT SELECT ON public.users TO anon, authenticated;

-- =============================================
-- HELPER VIEWS FOR COMMON QUERIES
-- =============================================

-- View for chat list with participant count and last message info
CREATE OR REPLACE VIEW public.chat_list_view AS
SELECT 
  c.*,
  COUNT(cp.user_id) as participant_count,
  cm.content as last_message_content,
  cm.sender_name as last_message_sender,
  u.display_name as creator_name
FROM public.chats c
LEFT JOIN public.chat_participants cp ON c.id = cp.chat_id
LEFT JOIN public.chat_messages cm ON c.last_message_id = cm.id
LEFT JOIN public.users u ON c.created_by = u.id
GROUP BY c.id, cm.content, cm.sender_name, u.display_name;

-- View for user's chats
CREATE OR REPLACE VIEW public.user_chats_view AS
SELECT DISTINCT
  c.*,
  cp.role as user_role,
  cp.joined_at as user_joined_at
FROM public.chats c
INNER JOIN public.chat_participants cp ON c.id = cp.chat_id
WHERE cp.user_id = auth.uid()
ORDER BY c.updated_at DESC;

-- Grant access to views
GRANT SELECT ON public.chat_list_view TO authenticated;
GRANT SELECT ON public.user_chats_view TO authenticated;

-- =============================================
-- SAMPLE DATA FOR TESTING (OPTIONAL)
-- =============================================

-- This section can be removed in production
-- INSERT INTO public.users (id, email, display_name) VALUES 
-- (uuid_generate_v4(), 'test@example.com', 'Test User')
-- ON CONFLICT (email) DO NOTHING;

COMMENT ON TABLE public.chats IS 'Chat rooms including direct messages and group chats';
COMMENT ON TABLE public.chat_participants IS 'Users participating in each chat room';
COMMENT ON TABLE public.chat_messages IS 'Messages sent in chat rooms';
COMMENT ON COLUMN public.chat_messages.call_type IS 'Type of call for call messages (voice/video)';
COMMENT ON COLUMN public.chat_messages.call_status IS 'Status of call (answered/missed/declined/busy)';
COMMENT ON COLUMN public.chat_messages.ai_context IS 'Additional context for AI-generated messages and call invitations';
