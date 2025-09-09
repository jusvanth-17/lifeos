-- PowerSync + Supabase Setup Script
-- Run this in your Supabase SQL Editor

-- 1. Create a role/user with replication privileges for PowerSync
CREATE ROLE powersync_role WITH REPLICATION BYPASSRLS LOGIN PASSWORD 'your-secure-password-here';

-- 2. Set up permissions for the newly created role
-- Read-only (SELECT) access is required
GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync_role;  

-- 3. Optionally, grant SELECT on all future tables (to cater for schema additions)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powersync_role; 

-- 4. Create a publication to replicate tables
-- The publication must be named "powersync"
CREATE PUBLICATION powersync FOR ALL TABLES;

-- 5. Verify the setup
SELECT rolname, rolreplication FROM pg_roles WHERE rolname = 'powersync_role';
SELECT pubname FROM pg_publication WHERE pubname = 'powersync';

-- Note: Replace 'your-secure-password-here' with a strong password
-- You'll need this password when configuring PowerSync Cloud
