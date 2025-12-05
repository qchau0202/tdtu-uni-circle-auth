const { validateRegisterInput, validateLoginInput, validateRefreshTokenInput } = require('../validators/auth_validator');
const authService = require('../../domain/services/auth_service');

const register = async (req, res, next) => {
  try {
    const { student_email, username, password } = req.body;

    // Validate required fields
    try {
      validateRegisterInput(req.body);
    } catch (error) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: error.message,
          status: 400
        }
      });
    }

    const result = await authService.register(student_email, username, password);

    res.status(201).json({
      message: 'Student registered successfully',
      user: result.user,
      profile: result.profile
    });
  } catch (error) {
    return res.status(400).json({
      error: {
        code: 'REGISTRATION_FAILED',
        message: error.message,
        status: 400
      }
    });
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
          code: 'VALIDATION_ERROR',
          message: error.message,
          status: 400
        }
      });
    }

    const result = await authService.login(email, password);

    res.status(200).json({
      message: 'Login successful',
      session: result.session,
      user: result.user,
      profile: result.profile
    });
  } catch (error) {
    return res.status(401).json({
      error: {
        code: 'LOGIN_FAILED',
        message: error.message,
        status: 401
      }
    });
  }
};

const logout = async (req, res, next) => {
  try {
    await authService.logout();

    res.status(200).json({
      message: 'Logout successful'
    });
  } catch (error) {
    return res.status(400).json({
      error: {
        code: 'LOGOUT_FAILED',
        message: error.message,
        status: 400
      }
    });
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
          code: 'VALIDATION_ERROR',
          message: error.message,
          status: 400
        }
      });
    }

    const session = await authService.refreshToken(refresh_token);

    res.status(200).json({
      message: 'Token refreshed successfully',
      session
    });
  } catch (error) {
    return res.status(401).json({
      error: {
        code: 'REFRESH_TOKEN_FAILED',
        message: error.message,
        status: 401
      }
    });
  }
};

const getCurrentUser = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: {
          code: 'MISSING_AUTH_TOKEN',
          message: 'Authorization token is required',
          status: 401
        }
      });
    }

    const token = authHeader.substring(7);
    const user = await authService.getCurrentUser(token);

    res.status(200).json({
      user
    });
  } catch (error) {
    return res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: error.message,
        status: 401
      }
    });
  }
};

module.exports = {
  register,
  login,
  logout,
  refreshToken,
  getCurrentUser
};
