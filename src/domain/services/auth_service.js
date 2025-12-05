const { getSupabaseAdmin } = require('../../infrastructure/database/supabase');
const Student = require('../models/student_model');
const Profile = require('../models/profile_model');
const { parseStudentEmail } = require('../../api/validators/student_validator');

class AuthService {
    constructor() {
        this.supabase = getSupabaseAdmin();
    }

    async register(studentEmail, username, password) {
        // Parse and validate student email
        const studentInfo = parseStudentEmail(studentEmail);

        // Check if student_code already exists
        const { data: existingStudent } = await this.supabase
            .from('students')
            .select('student_code')
            .eq('student_code', studentInfo.studentCode)
            .maybeSingle();

        if (existingStudent) {
            throw new Error('Student code already registered');
        }

        // Create user in Supabase Auth
        const { data: authData, error: authError } = await this.supabase.auth.admin.createUser({
            email: studentEmail,
            password,
            email_confirm: true,
            user_metadata: {
                username,
                student_code: studentInfo.studentCode,
                faculty_code: studentInfo.facultyCode,
                academic_year: studentInfo.academicYear
            }
        });

        if (authError) {
            throw new Error(authError.message);
        }

        try {
            // Insert into students table
            const { data: studentData, error: studentError } = await this.supabase
                .from('students')
                .insert({
                    id: authData.user.id,
                    student_code: studentInfo.studentCode,
                    email: studentEmail
                })
                .select()
                .single();

            if (studentError) {
                throw new Error(`Failed to create student record: ${studentError.message}`);
            }

            // Create profile
            const { data: profileData, error: profileError } = await this.supabase
                .from('profiles')
                .insert({
                    student_id: authData.user.id,
                    display_name: username,
                    dob: null,
                    phone_number: null,
                    faculty: null,
                    academic_year: studentInfo.academicYear,
                    bio: null,
                    avatar_url: null,
                    social_links: null
                })
                .select()
                .single();

            if (profileError) {
                throw new Error(`Failed to create profile: ${profileError.message}`);
            }

            return {
                user: {
                    id: authData.user.id,
                    email: authData.user.email,
                    student_code: studentInfo.studentCode,
                    username: username
                },
                profile: Profile.fromDatabase(profileData)
            };
        } catch (error) {
            // Rollback: Delete the auth user if student/profile creation fails
            await this.supabase.auth.admin.deleteUser(authData.user.id);
            throw error;
        }
    }

    async login(email, password) {
        const { data, error } = await this.supabase.auth.signInWithPassword({
            email,
            password
        });

        if (error) {
            throw new Error(error.message);
        }

        // Fetch profile data
        const { data: profileData } = await this.supabase
            .from('profiles')
            .select(`
        *,
        student:students(id, student_code, email)
      `)
            .eq('student_id', data.user.id)
            .single();

        return {
            session: data.session,
            user: data.user,
            profile: profileData ? Profile.fromDatabase(profileData) : null
        };
    }

    async logout() {
        const { error } = await this.supabase.auth.signOut();

        if (error) {
            throw new Error(error.message);
        }

        return true;
    }

    async refreshToken(refreshToken) {
        const { data, error } = await this.supabase.auth.refreshSession({
            refresh_token: refreshToken
        });

        if (error) {
            throw new Error(error.message);
        }

        return data.session;
    }

    async getCurrentUser(token) {
        const { data: { user }, error } = await this.supabase.auth.getUser(token);

        if (error) {
            throw new Error(error.message);
        }

        return user;
    }
}

module.exports = new AuthService();
