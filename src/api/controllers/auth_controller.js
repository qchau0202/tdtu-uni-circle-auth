const { getSupabaseClient, getSupabaseAdmin } = require('../../infrastructure/database/supabase');
const { parseStudentEmail } = require('../validators/student_validator');
const { validateRegisterInput, validateLoginInput, validateRefreshTokenInput } = require('../validators/auth_validator');

const register = async (req, res, next) => {
  try {
    const { student_email, username, password } = req.body;

    // Validate required fields
    try {
      validateRegisterInput(req.body);
    } catch (error) {
      return res.status(400).json({
        error: {
          message: error.message,
          status: 400
        }
      });
    }

    // Parse and validate student email
    let studentInfo;
    try {
      studentInfo = parseStudentEmail(student_email);
    } catch (error) {
      return res.status(400).json({
        error: {
          message: error.message,
          status: 400
        }
      });
    }

    const supabase = getSupabaseAdmin();

    // Check if student_code already exists in students table
    const { data: existingStudent } = await supabase
      .from('students')
      .select('student_code')
      .eq('student_code', studentInfo.studentCode)
      .maybeSingle();

    if (existingStudent) {
      return res.status(400).json({
        error: {
          message: 'Student code already registered',
          status: 400
        }
      });
    }

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: student_email,
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
      return res.status(400).json({
        error: {
          message: authError.message,
          status: 400
        }
      });
    }

    // Insert into students table
    const { data: studentData, error: studentError } = await supabase
      .from('students')
      .insert({
        id: authData.user.id,
        student_code: studentInfo.studentCode,
        email: student_email
      })
      .select()
      .single();

    if (studentError) {
      // Rollback: Delete the auth user if student creation fails
      await supabase.auth.admin.deleteUser(authData.user.id);

      return res.status(400).json({
        error: {
          message: `Failed to create student record: ${studentError.message}`,
          status: 400
        }
      });
    }

    // Create profile
    const { data: profileData, error: profileError } = await supabase
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
      // Rollback: Delete the student and auth user if profile creation fails
      await supabase.from('students').delete().eq('id', authData.user.id);
      await supabase.auth.admin.deleteUser(authData.user.id);

      return res.status(400).json({
        error: {
          message: `Failed to create profile: ${profileError.message}`,
          status: 400
        }
      });
    }

    res.status(201).json({
      message: 'Student registered successfully',
      user: {
        id: authData.user.id,
        email: authData.user.email,
        student_code: studentInfo.studentCode,
        username: username
      },
      profile: profileData
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    try {
      validateLoginInput(req.body);
    } catch (error) {
      return res.status(400).json({
        error: {
          message: error.message,
          status: 400
        }
      });
    }

    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      return res.status(401).json({
        error: {
          message: error.message,
          status: 401
        }
      });
    }

    // Fetch profile data
    const { data: profileData } = await supabase
      .from('profiles')
      .select(`
        *,
        student:students(id, student_code, email)
      `)
      .eq('student_id', data.user.id)
      .single();

    res.status(200).json({
      message: 'Login successful',
      session: data.session,
      user: data.user,
      profile: profileData
    });
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { error } = await supabase.auth.signOut();

    if (error) {
      return res.status(400).json({
        error: {
          message: error.message,
          status: 400
        }
      });
    }

    res.status(200).json({
      message: 'Logout successful'
    });
  } catch (error) {
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;

    try {
      validateRefreshTokenInput(req.body);
    } catch (error) {
      return res.status(400).json({
        error: {
          message: error.message,
          status: 400
        }
      });
    }

    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.refreshSession({
      refresh_token
    });

    if (error) {
      return res.status(401).json({
        error: {
          message: error.message,
          status: 401
        }
      });
    }

    res.status(200).json({
      message: 'Token refreshed successfully',
      session: data.session
    });
  } catch (error) {
    next(error);
  }
};

const getCurrentUser = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: {
          message: 'Authorization token is required',
          status: 401
        }
      });
    }

    const token = authHeader.substring(7);
    const supabase = getSupabaseClient();

    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error) {
      return res.status(401).json({
        error: {
          message: error.message,
          status: 401
        }
      });
    }

    res.status(200).json({
      user
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  logout,
  refreshToken,
  getCurrentUser
};
