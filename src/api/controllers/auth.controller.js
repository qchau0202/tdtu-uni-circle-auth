const { getSupabaseClient, getSupabaseAdmin } = require('../../infrastructure/database/supabase');

/**
 * Parse student email and extract student information
 * Email format: student_code@student.tdtu.edu.vn
 * Example: 523K0013@student.tdtu.edu.vn
 * 
 * Format breakdown:
 * - First character (5): Faculty code
 * - Next 2 digits (23): Year of admission (2023)
 * - Letter (K): Program type (K = regular program)
 * - Last 4 digits (0013): Student index number
 */
const parseStudentEmail = (email) => {
  // Validate email format: XYY[A-Z]NNNN@student.tdtu.edu.vn
  const emailRegex = /^([0-9A-H]{1})([0-9]{2})([A-Z])([0-9]{4})@student\.tdtu\.edu\.vn$/i;
  const match = email.match(emailRegex);

  if (!match) {
    throw new Error('Invalid student email format. Must be: student_code@student.tdtu.edu.vn (e.g., 523K0013@student.tdtu.edu.vn)');
  }

  const facultyCodeChar = match[1].toUpperCase(); // First character (0-9, A-F)
  const yearDigits = match[2]; // Year digits (23 for 2023)
  const programType = match[3].toUpperCase(); // Program type (K, etc.)
  const studentIndex = match[4]; // Student index (0013)

  const studentCode = `${facultyCodeChar}${yearDigits}${programType}${studentIndex}`.toUpperCase();

  // TDTU Faculty Code Mapping
  const facultyMap = {
    '0': 'FL',   // Khoa Ngoại ngữ
    '1': 'IFA',  // Khoa Mỹ thuật công nghiệp
    '2': 'ACC',  // Khoa Kế toán
    '3': 'SSH',  // Khoa Khoa học xã hội & Nhân văn
    '4': 'EEE',  // Khoa Điện - Điện tử
    '5': 'IT',   // Khoa Công nghệ thông tin
    '6': 'AS',   // Khoa Khoa học ứng dụng
    '7': 'BA',   // Khoa Quản trị kinh doanh
    '8': 'CE',   // Khoa Kỹ thuật công trình
    '9': 'ENV',  // Khoa Môi trường & Bảo hộ lao động
    'A': 'LWU',  // Khoa Lao động công đoàn
    'B': 'FIN',  // Khoa Tài chính ngân hàng
    'C': 'MATH', // Khoa Toán - Thống kê
    'D': 'SPRT', // Khoa Khoa học thể thao
    'E': 'LAW',  // Khoa Luật
    'F': 'IED',  // Khoa Giáo dục quốc tế
    'G': 'IED',  // Khoa Giáo dục quốc tế
    'H': 'PHAR'  // Khoa Dược
  };

  const facultyCode = facultyMap[facultyCodeChar];
  if (!facultyCode) {
    throw new Error(`Invalid faculty code: ${facultyCodeChar}. Must be 0-9 or A-H.`);
  }

  // Convert year: 23 -> 2023, handle edge cases for years 00-99
  const currentCentury = Math.floor(new Date().getFullYear() / 100) * 100;
  const yearNumber = parseInt(yearDigits, 10);
  const fullYear = yearNumber >= 0 && yearNumber <= 99 ? currentCentury + yearNumber : yearNumber;

  return {
    studentCode,
    facultyCode,
    facultyCodeChar,
    academicYear: fullYear.toString(),
    programType,
    studentIndex
  };
};

const register = async (req, res, next) => {
  try {
    const { student_email, username, password } = req.body;

    // Validate required fields
    if (!student_email || !username || !password) {
      return res.status(400).json({
        error: {
          message: 'student_email, username, and password are required',
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

    // Check if student_code already exists in student_profile
    const { data: existingProfile } = await supabase
      .from('student_profile')
      .select('student_code')
      .eq('student_code', studentInfo.studentCode)
      .maybeSingle();

    if (existingProfile) {
      return res.status(400).json({
        error: {
          message: 'Student code already registered',
          status: 400
        }
      });
    }

    // Get faculty_id from faculty table using code
    const { data: facultyData, error: facultyError } = await supabase
      .from('faculty')
      .select('id')
      .eq('code', studentInfo.facultyCode)
      .single();

    if (facultyError || !facultyData) {
      return res.status(400).json({
        error: {
          message: `Faculty not found for code: ${studentInfo.facultyCode}`,
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

    // Generate unique unicircle_profile_slug
    const unicircleProfileSlug = `${username.toLowerCase().replace(/\s+/g, '-')}-${studentInfo.studentCode.toLowerCase()}`;

    // Create student profile
    const { data: profileData, error: profileError } = await supabase
      .from('student_profile')
      .insert({
        user_id: authData.user.id,
        student_code: studentInfo.studentCode,
        faculty_id: facultyData.id,
        academic_year: studentInfo.academicYear,
        username: username,
        unicircle_profile_slug: unicircleProfileSlug,
        bio: null,
        dob: null,
        phone_number: null,
        avatar_url: null,
        social_links: null
      })
      .select()
      .single();

    if (profileError) {
      // Rollback: Delete the auth user if profile creation fails
      await supabase.auth.admin.deleteUser(authData.user.id);

      return res.status(400).json({
        error: {
          message: `Failed to create student profile: ${profileError.message}`,
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

    if (!email || !password) {
      return res.status(400).json({
        error: {
          message: 'Email and password are required',
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

    res.status(200).json({
      message: 'Login successful',
      session: data.session,
      user: data.user
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

    if (!refresh_token) {
      return res.status(400).json({
        error: {
          message: 'Refresh token is required',
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
