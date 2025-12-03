-- ============================================
-- TDTU UniCircle Database Setup
-- Complete Schema for All Services
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query

-- ============================================
-- I. SUPPORT TABLES
-- ============================================

-- 1. Faculty Table (Support)
CREATE TABLE
IF NOT EXISTS faculty
(
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR
(10) UNIQUE NOT NULL,
  faculty_code_char VARCHAR
(1) UNIQUE NOT NULL,
  name VARCHAR
(255) NOT NULL,
  name_vi VARCHAR
(255),
  description TEXT,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- Insert TDTU faculties based on student code system
INSERT INTO faculty
  (code, faculty_code_char, name, name_vi)
VALUES
  ('FL', '0', 'Faculty of Foreign Languages', 'Khoa Ngoại ngữ'),
  ('IFA', '1', 'Faculty of Industrial Fine Arts', 'Khoa Mỹ thuật công nghiệp'),
  ('ACC', '2', 'Faculty of Accounting', 'Khoa Kế toán'),
  ('SSH', '3', 'Faculty of Social Sciences & Humanities', 'Khoa KHXH & Nhân văn'),
  ('EEE', '4', 'Faculty of Electrical & Electronics Engineering', 'Khoa Điện - Điện tử'),
  ('IT', '5', 'Faculty of Information Technology', 'Khoa Công nghệ thông tin'),
  ('AS', '6', 'Faculty of Applied Sciences', 'Khoa Khoa học ứng dụng'),
  ('BA', '7', 'Faculty of Business Administration', 'Khoa Quản trị kinh doanh'),
  ('CE', '8', 'Faculty of Civil Engineering', 'Khoa Kỹ thuật công trình'),
  ('ENV', '9', 'Faculty of Environment & Occupational Safety', 'Khoa Môi trường & BHLĐ'),
  ('LWU', 'A', 'Faculty of Labor and Trade Union', 'Khoa Lao động công đoàn'),
  ('FIN', 'B', 'Faculty of Finance & Banking', 'Khoa Tài chính ngân hàng'),
  ('MATH', 'C', 'Faculty of Mathematics & Statistics', 'Khoa Toán - Thống kê'),
  ('SPRT', 'D', 'Faculty of Sport Science', 'Khoa Khoa học thể thao'),
  ('LAW', 'E', 'Faculty of Law', 'Khoa Luật'),
  ('IED', 'F', 'Faculty of International Education', 'Khoa Giáo dục quốc tế'),
  ('PHAR', 'H', 'Faculty of Pharmacy', 'Khoa Dược')
ON CONFLICT
(code) DO NOTHING;

-- 2. Course Table (Support)
CREATE TABLE
IF NOT EXISTS course
(
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR
(20) UNIQUE NOT NULL,
  name VARCHAR
(255) NOT NULL,
  faculty_id BIGINT REFERENCES faculty
(id) ON
DELETE
SET NULL
,
  description TEXT,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- Insert sample courses
INSERT INTO course
  (code, name, faculty_id)
VALUES
  ('503045', 'Service-Oriented Architecture', (SELECT id
    FROM faculty
    WHERE code = 'IT')),
  ('503046', 'Software Engineering', (SELECT id
    FROM faculty
    WHERE code = 'IT')),
  ('503047', 'Database Systems', (SELECT id
    FROM faculty
    WHERE code = 'IT')),
  ('502042', 'Data Structures and Algorithms', (SELECT id
    FROM faculty
    WHERE code = 'IT')),
  ('501030', 'Introduction to Programming', (SELECT id
    FROM faculty
    WHERE code = 'IT'))
ON CONFLICT
(code) DO NOTHING;

-- ============================================
-- II. AUTH DOMAIN
-- ============================================

-- 3. Auth Table (uses Supabase auth.users + custom fields)
-- Note: Supabase auth.users already exists, we extend it with student_profile
-- This table links auth.users with student-specific data

-- ============================================
-- III. PROFILE DOMAIN
-- ============================================

-- 4. Student Profile Table
CREATE TABLE
IF NOT EXISTS student_profile
(
  id BIGSERIAL PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users
(id) ON
DELETE CASCADE,
  student_code VARCHAR(10)
UNIQUE NOT NULL,
  faculty_id BIGINT REFERENCES faculty
(id) ON
DELETE
SET NULL
,
  username VARCHAR
(255) NOT NULL,
  bio TEXT,
  dob DATE,
  academic_year VARCHAR
(20),
  phone_number VARCHAR
(20),
  avatar_url TEXT,
  unicircle_profile_slug VARCHAR
(255) UNIQUE NOT NULL,
  social_links JSONB,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- ============================================
-- IV. STUDY SERVICE DOMAIN
-- ============================================

-- 5. Study Session Table
CREATE TABLE
IF NOT EXISTS study_session
(
  id BIGSERIAL PRIMARY KEY,
  host_student_id BIGINT NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  topic VARCHAR(255)
NOT NULL,
  course_id BIGINT REFERENCES course
(id) ON
DELETE
SET NULL
,
  primary_faculty_id BIGINT REFERENCES faculty
(id) ON
DELETE
SET NULL
,
  location VARCHAR
(255),
  visibility VARCHAR
(20) NOT NULL DEFAULT 'public' CHECK
(visibility IN
('public', 'private_password')),
  password_hash VARCHAR
(255),
  participants_limit INTEGER,
  meet_link TEXT,
  room_link VARCHAR
(255) UNIQUE,
  start_time TIMESTAMP
WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP
WITH TIME ZONE NOT NULL,
  status VARCHAR
(20) NOT NULL DEFAULT 'scheduled' CHECK
(status IN
('scheduled', 'live', 'completed', 'cancelled')),
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- 6. Study Session Participant Table
CREATE TABLE
IF NOT EXISTS study_session_participant
(
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES study_session
(id) ON
DELETE CASCADE,
  student_id BIGINT
NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  role VARCHAR(20)
NOT NULL DEFAULT 'member' CHECK
(role IN
('host', 'member')),
  status VARCHAR
(20) NOT NULL DEFAULT 'joined' CHECK
(status IN
('joined', 'left', 'kicked')),
  joined_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  left_at TIMESTAMP
WITH TIME ZONE,
  UNIQUE
(session_id, student_id)
);

-- 7. Study Session Request Table (Invites & Join Requests)
CREATE TABLE
IF NOT EXISTS study_session_request
(
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES study_session
(id) ON
DELETE CASCADE,
  type VARCHAR(20)
NOT NULL CHECK
(type IN
('invitation', 'join_request')),
  from_student_id BIGINT NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  to_student_id BIGINT
NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  message TEXT,
  status VARCHAR
(20) NOT NULL DEFAULT 'pending' CHECK
(status IN
('pending', 'accepted', 'rejected', 'cancelled', 'expired')),
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  responded_at TIMESTAMP
WITH TIME ZONE
);

-- ============================================
-- V. NOTIFICATION DOMAIN
-- ============================================

-- 8. Notification Table
CREATE TABLE
IF NOT EXISTS notification
(
  id BIGSERIAL PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  type VARCHAR(50)
NOT NULL CHECK
(type IN
('invitation', 'join_request', 'request_accepted', 'request_rejected', 'session_created', 'session_updated', 'session_cancelled')),
  title VARCHAR
(255) NOT NULL,
  message TEXT NOT NULL,
  session_id BIGINT REFERENCES study_session
(id) ON
DELETE
SET NULL
,
  from_student_id BIGINT REFERENCES student_profile
(id) ON
DELETE
SET NULL
,
  link_to TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  read_at TIMESTAMP
WITH TIME ZONE
);

-- ============================================
-- VI. RESOURCE SHARING DOMAIN
-- ============================================

-- 9. Resource Table
CREATE TABLE
IF NOT EXISTS resource
(
  id BIGSERIAL PRIMARY KEY,
  owner_student_id BIGINT NOT NULL REFERENCES student_profile
(id) ON
DELETE CASCADE,
  course_id BIGINT
REFERENCES course
(id) ON
DELETE
SET NULL
,
  title VARCHAR
(255) NOT NULL,
  description TEXT,
  resource_type VARCHAR
(20) NOT NULL CHECK
(resource_type IN
('url', 'document')),
  url TEXT,
  file_path TEXT,
  file_mime_type VARCHAR
(100),
  hashtags VARCHAR
(500),
  upvote_count INTEGER DEFAULT 0,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Faculty indexes
CREATE INDEX
IF NOT EXISTS idx_faculty_code ON faculty
(code);
CREATE INDEX
IF NOT EXISTS idx_faculty_code_char ON faculty
(faculty_code_char);

-- Course indexes
CREATE INDEX
IF NOT EXISTS idx_course_code ON course
(code);
CREATE INDEX
IF NOT EXISTS idx_course_faculty_id ON course
(faculty_id);

-- Student Profile indexes
CREATE INDEX
IF NOT EXISTS idx_student_profile_user_id ON student_profile
(user_id);
CREATE INDEX
IF NOT EXISTS idx_student_profile_student_code ON student_profile
(student_code);
CREATE INDEX
IF NOT EXISTS idx_student_profile_faculty_id ON student_profile
(faculty_id);
CREATE INDEX
IF NOT EXISTS idx_student_profile_slug ON student_profile
(unicircle_profile_slug);

-- Study Session indexes
CREATE INDEX
IF NOT EXISTS idx_study_session_host ON study_session
(host_student_id);
CREATE INDEX
IF NOT EXISTS idx_study_session_course ON study_session
(course_id);
CREATE INDEX
IF NOT EXISTS idx_study_session_faculty ON study_session
(primary_faculty_id);
CREATE INDEX
IF NOT EXISTS idx_study_session_status ON study_session
(status);
CREATE INDEX
IF NOT EXISTS idx_study_session_start_time ON study_session
(start_time);
CREATE INDEX
IF NOT EXISTS idx_study_session_room_link ON study_session
(room_link);

-- Study Session Participant indexes
CREATE INDEX
IF NOT EXISTS idx_session_participant_session ON study_session_participant
(session_id);
CREATE INDEX
IF NOT EXISTS idx_session_participant_student ON study_session_participant
(student_id);

-- Study Session Request indexes
CREATE INDEX
IF NOT EXISTS idx_session_request_session ON study_session_request
(session_id);
CREATE INDEX
IF NOT EXISTS idx_session_request_from ON study_session_request
(from_student_id);
CREATE INDEX
IF NOT EXISTS idx_session_request_to ON study_session_request
(to_student_id);
CREATE INDEX
IF NOT EXISTS idx_session_request_status ON study_session_request
(status);

-- Notification indexes
CREATE INDEX
IF NOT EXISTS idx_notification_student ON notification
(student_id);
CREATE INDEX
IF NOT EXISTS idx_notification_is_read ON notification
(is_read);
CREATE INDEX
IF NOT EXISTS idx_notification_created_at ON notification
(created_at);

-- Resource indexes
CREATE INDEX
IF NOT EXISTS idx_resource_owner ON resource
(owner_student_id);
CREATE INDEX
IF NOT EXISTS idx_resource_course ON resource
(course_id);
CREATE INDEX
IF NOT EXISTS idx_resource_type ON resource
(resource_type);
CREATE INDEX
IF NOT EXISTS idx_resource_hashtags ON resource USING gin
(to_tsvector
('english', hashtags));

-- ============================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column
()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW
();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_faculty_updated_at BEFORE
UPDATE ON faculty
  FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column
();

CREATE TRIGGER update_course_updated_at BEFORE
UPDATE ON course
  FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column
();

CREATE TRIGGER update_student_profile_updated_at BEFORE
UPDATE ON student_profile
  FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column
();

CREATE TRIGGER update_study_session_updated_at BEFORE
UPDATE ON study_session
  FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column
();

CREATE TRIGGER update_resource_updated_at BEFORE
UPDATE ON resource
  FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column
();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE course ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session_participant ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource ENABLE ROW LEVEL SECURITY;

-- Faculty Policies (Public Read)
CREATE POLICY "Allow public read access to faculty"
  ON faculty FOR
SELECT TO public USING
(true);

-- Course Policies (Public Read)
CREATE POLICY "Allow public read access to course"
  ON course FOR
SELECT TO public USING
(true);

-- Student Profile Policies
CREATE POLICY "Allow authenticated users to read all profiles"
  ON student_profile FOR
SELECT TO authenticated
USING
(true);

CREATE POLICY "Allow users to update their own profile"
  ON student_profile FOR
UPDATE TO authenticated
  USING (auth.uid() = user_id)
WITH CHECK
(auth.uid
() = user_id);

CREATE POLICY "Allow service role to insert profiles"
  ON student_profile FOR
INSERT TO service_role WITH CHECK (
true);

-- Study Session Policies
CREATE POLICY "Allow authenticated users to read public sessions"
  ON study_session FOR
SELECT TO authenticated
USING
(true);

CREATE POLICY "Allow authenticated users to create sessions"
  ON study_session FOR
INSERT TO authenticated WITH CHECK (
true);

CREATE POLICY "Allow host to update their sessions"
  ON study_session FOR
UPDATE TO authenticated
  USING (host_student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

CREATE POLICY "Allow host to delete their sessions"
  ON study_session FOR
DELETE TO authenticated
  USING (host_student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

-- Study Session Participant Policies
CREATE POLICY "Allow authenticated users to read participants"
  ON study_session_participant FOR
SELECT TO authenticated
USING
(true);

CREATE POLICY "Allow authenticated users to join sessions"
  ON study_session_participant FOR
INSERT TO authenticated WITH CHECK (
true);

CREATE POLICY "Allow users to leave sessions"
  ON study_session_participant FOR
UPDATE TO authenticated
  USING (student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

-- Study Session Request Policies
CREATE POLICY "Allow authenticated users to read their requests"
  ON study_session_request FOR
SELECT TO authenticated
USING
(
    from_student_id IN
(SELECT id
FROM student_profile
WHERE user_id = auth.uid())
OR
    to_student_id IN
(SELECT id
FROM student_profile
WHERE user_id = auth.uid())
);

CREATE POLICY "Allow authenticated users to create requests"
  ON study_session_request FOR
INSERT TO authenticated WITH CHECK (
true);

CREATE POLICY "Allow users to update their requests"
  ON study_session_request FOR
UPDATE TO authenticated
  USING (
    from_student_id IN (SELECT id
  FROM student_profile
  WHERE user_id = auth.uid()) OR
  to_student_id IN (SELECT id
  FROM student_profile
  WHERE user_id = auth.uid())
  );

-- Notification Policies
CREATE POLICY "Allow users to read their own notifications"
  ON notification FOR
SELECT TO authenticated
USING
(student_id IN
(SELECT id
FROM student_profile
WHERE user_id = auth.uid())
);

CREATE POLICY "Allow system to create notifications"
  ON notification FOR
INSERT TO authenticated WITH CHECK (
true);

CREATE POLICY "Allow users to update their own notifications"
  ON notification FOR
UPDATE TO authenticated
  USING (student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

-- Resource Policies
CREATE POLICY "Allow authenticated users to read all resources"
  ON resource FOR
SELECT TO authenticated
USING
(true);

CREATE POLICY "Allow authenticated users to create resources"
  ON resource FOR
INSERT TO authenticated WITH CHECK (
true);

CREATE POLICY "Allow owners to update their resources"
  ON resource FOR
UPDATE TO authenticated
  USING (owner_student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

CREATE POLICY "Allow owners to delete their resources"
  ON resource FOR
DELETE TO authenticated
  USING (owner_student_id IN (SELECT id
FROM student_profile
WHERE user_id = auth.uid()));

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT SELECT ON faculty TO authenticated, anon;
GRANT SELECT ON course TO authenticated, anon;
GRANT ALL ON student_profile TO authenticated, service_role;
GRANT ALL ON study_session TO authenticated, service_role;
GRANT ALL ON study_session_participant TO authenticated, service_role;
GRANT ALL ON study_session_request TO authenticated, service_role;
GRANT ALL ON notification TO authenticated, service_role;
GRANT ALL ON resource TO authenticated, service_role;

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
  (SELECT COUNT(*)
  FROM faculty) as faculty_count,
  (SELECT COUNT(*)
  FROM course) as course_count;

-- ============================================
-- NOTES:
-- - auth.users table is managed by Supabase Auth
-- - student_profile links to auth.users via user_id
-- - Email validation happens in application layer
-- - Student code is extracted from email during registration
-- ============================================
