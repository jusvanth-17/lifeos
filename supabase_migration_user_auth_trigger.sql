-- Migration: Create user auth trigger
-- This migration creates a trigger that automatically creates entries in public.users
-- when new users are created in auth.users (during sign up)

-- Function to create user in public.users when auth.users is created
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, avatar_url, created_at, updated_at)
  VALUES (
    NEW.id::text,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.created_at,
    NEW.updated_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute the function
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Optional: Handle existing users (run this once if you have existing auth users without public.users entries)
-- INSERT INTO public.users (id, email, display_name, avatar_url, created_at, updated_at)
-- SELECT 
--   id::text,
--   email,
--   COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1)) as display_name,
--   raw_user_meta_data->>'avatar_url' as avatar_url,
--   created_at,
--   updated_at
-- FROM auth.users
-- WHERE id::text NOT IN (SELECT id FROM public.users);
