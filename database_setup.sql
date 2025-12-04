-- ============================================
-- TDTU UniCircle Database Setup
-- Complete Schema for All Services
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query

-- ============================================
-- I. AUTH DOMAIN (Extends auth.users)
-- ============================================

-- 1. Students Table
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  student_code VARCHAR(10) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Email validation trigger
CREATE OR REPLACE FUNCTION validate_student_email()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email NOT LIKE '%@student.tdtu.edu.vn' THEN
    RAISE EXCEPTION 'Email must end with @student.tdtu.edu.vn';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_student_email
  BEFORE INSERT OR UPDATE ON students
  FOR EACH ROW
  EXECUTE FUNCTION validate_student_email();

-- ============================================
-- II. PROFILE DOMAIN
-- ============================================

-- 2. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL,
  dob DATE,
  phone_number VARCHAR(20),
  faculty VARCHAR(255),
  bio TEXT,
  academic_year VARCHAR(20),
  avatar_url TEXT,
  social_links JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id)
);

-- ============================================
-- III. FEED DOMAIN
-- ============================================

-- 4. Threads Table
CREATE TABLE IF NOT EXISTS threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  media_urls TEXT[],
  tags VARCHAR(50) CHECK (tags IN ('QUESTION', 'ANSWER', 'DISCUSSION')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Comments Table
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- IV. RESOURCE SHARING DOMAIN
-- ============================================

-- 6. Resources Table
CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  course_code VARCHAR(20),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  resource_type VARCHAR(20) NOT NULL CHECK (resource_type IN ('URL', 'DOCUMENT')),
  file_url TEXT,
  hashtags TEXT[],
  upvote_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- V. COLLECTION DOMAIN
-- ============================================

-- 7. Collections Table
CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  tags TEXT[],
  refs TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VI. NOTIFICATION DOMAIN
-- ============================================

-- 8. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES students(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Students indexes
CREATE INDEX IF NOT EXISTS idx_students_student_code ON students(student_code);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);

-- Threads indexes
CREATE INDEX IF NOT EXISTS idx_threads_author_id ON threads(author_id);
CREATE INDEX IF NOT EXISTS idx_threads_tags ON threads(tags);
CREATE INDEX IF NOT EXISTS idx_threads_created_at ON threads(created_at);

-- Comments indexes
CREATE INDEX IF NOT EXISTS idx_comments_thread_id ON comments(thread_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id);

-- Resources indexes
CREATE INDEX IF NOT EXISTS idx_resources_owner_id ON resources(owner_id);
CREATE INDEX IF NOT EXISTS idx_resources_course_code ON resources(course_code);
CREATE INDEX IF NOT EXISTS idx_resources_hashtags ON resources USING GIN(hashtags);

-- Collections indexes
CREATE INDEX IF NOT EXISTS idx_collections_owner_id ON collections(owner_id);
CREATE INDEX IF NOT EXISTS idx_collections_is_public ON collections(is_public);
CREATE INDEX IF NOT EXISTS idx_collections_tags ON collections USING GIN(tags);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sender_id ON notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- ============================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Students Policies
CREATE POLICY "Allow authenticated users to read all students"
  ON students FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow service role to insert students"
  ON students FOR INSERT TO service_role
  WITH CHECK (true);

-- Profiles Policies
CREATE POLICY "Allow authenticated users to read all profiles"
  ON profiles FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow users to update their own profile"
  ON profiles FOR UPDATE TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Allow service role to insert profiles"
  ON profiles FOR INSERT TO service_role
  WITH CHECK (true);

-- Threads Policies
CREATE POLICY "Allow authenticated users to read all threads"
  ON threads FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to create threads"
  ON threads FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Allow authors to update their threads"
  ON threads FOR UPDATE TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY "Allow authors to delete their threads"
  ON threads FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- Comments Policies
CREATE POLICY "Allow authenticated users to read all comments"
  ON comments FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to create comments"
  ON comments FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Allow authors to update their comments"
  ON comments FOR UPDATE TO authenticated
  USING (author_id = auth.uid());

CREATE POLICY "Allow authors to delete their comments"
  ON comments FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- Resources Policies
CREATE POLICY "Allow authenticated users to read all resources"
  ON resources FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to create resources"
  ON resources FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Allow owners to update their resources"
  ON resources FOR UPDATE TO authenticated
  USING (owner_id = auth.uid());

CREATE POLICY "Allow owners to delete their resources"
  ON resources FOR DELETE TO authenticated
  USING (owner_id = auth.uid());

-- Collections Policies
CREATE POLICY "Allow users to read public collections"
  ON collections FOR SELECT TO authenticated
  USING (is_public = true OR owner_id = auth.uid());

CREATE POLICY "Allow authenticated users to create collections"
  ON collections FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Allow owners to update their collections"
  ON collections FOR UPDATE TO authenticated
  USING (owner_id = auth.uid());

CREATE POLICY "Allow owners to delete their collections"
  ON collections FOR DELETE TO authenticated
  USING (owner_id = auth.uid());

-- Notifications Policies
CREATE POLICY "Allow users to read their own notifications"
  ON notifications FOR SELECT TO authenticated
  USING (recipient_id = auth.uid());

CREATE POLICY "Allow system to create notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow users to update their own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING (recipient_id = auth.uid());

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL ON students TO authenticated, service_role;
GRANT ALL ON profiles TO authenticated, service_role;
GRANT ALL ON threads TO authenticated, service_role;
GRANT ALL ON comments TO authenticated, service_role;
GRANT ALL ON resources TO authenticated, service_role;
GRANT ALL ON collections TO authenticated, service_role;
GRANT ALL ON notifications TO authenticated, service_role;

-- ============================================
-- SAMPLE DATA & NOTES
-- ============================================

-- Example social_links JSONB format:
-- {
--   "facebook": "https://facebook.com/username",
--   "instagram": "https://instagram.com/username",
--   "linkedin": "https://linkedin.com/in/username",
--   "github": "https://github.com/username"
-- }

-- Verify setup
SELECT 'Database setup completed successfully!' as status;
SELECT
  (SELECT COUNT(*) FROM students) as students_count,
  (SELECT COUNT(*) FROM profiles) as profiles_count;

-- ============================================
-- NOTES:
-- - auth.users table is managed by Supabase Auth
-- - students table has 1:1 relationship with auth.users
-- - Email validation enforced via trigger (@student.tdtu.edu.vn)
-- - Student code is extracted from email during registration
-- - profiles table stores extended student information
-- ============================================
