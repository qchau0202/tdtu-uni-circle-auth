/**
 * Validate register input
 * @param {Object} data
 */
const validateRegisterInput = (data) => {
    const { student_email, username, password } = data;
    if (!student_email || !username || !password) {
        throw new Error('student_email, username, and password are required');
    }
};

/**
 * Validate login input
 * @param {Object} data
 */
const validateLoginInput = (data) => {
    const { email, password } = data;
    if (!email || !password) {
        throw new Error('Email and password are required');
    }
};

/**
 * Validate refresh token input
 * @param {Object} data
 */
const validateRefreshTokenInput = (data) => {
    const { refresh_token } = data;
    if (!refresh_token) {
        throw new Error('Refresh token is required');
    }
};

module.exports = {
    validateRegisterInput,
    validateLoginInput,
    validateRefreshTokenInput
};
