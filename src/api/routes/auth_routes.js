const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth_controller');

/**
 * @swagger
 * components:
 *   schemas:
 *     Error:
 *       type: object
 *       properties:
 *         error:
 *           type: object
 *           properties:
 *             code:
 *               type: string
 *               description: Error code identifier
 *               example: "VALIDATION_ERROR"
 *             message:
 *               type: string
 *               description: Human-readable error message
 *               example: "Validation failed"
 *             details:
 *               type: string
 *               description: Additional error details
 *             status:
 *               type: integer
 *               description: HTTP status code
 *               example: 400
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new student
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - student_email
 *               - username
 *               - password
 *             properties:
 *               student_email:
 *                 type: string
 *                 format: email
 *                 description: Student email in format student_code@student.tdtu.edu.vn
 *                 example: 523K0013@student.tdtu.edu.vn
 *               username:
 *                 type: string
 *                 description: Custom username for the student
 *                 example: John Doe
 *               password:
 *                 type: string
 *                 format: password
 *                 example: password123
 *     responses:
 *       201:
 *         description: Student registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                     email:
 *                       type: string
 *                     student_code:
 *                       type: string
 *                     username:
 *                       type: string
 *                 profile:
 *                   type: object
 *       400:
 *         description: Bad request - invalid email format, missing fields, or student already exists
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             examples:
 *               validationError:
 *                 summary: Validation failed
 *                 value:
 *                   error:
 *                     code: "VALIDATION_ERROR"
 *                     message: "student_email must be a valid TDTU student email"
 *                     status: 400
 *               registrationFailed:
 *                 summary: Registration failed
 *                 value:
 *                   error:
 *                     code: "REGISTRATION_FAILED"
 *                     message: "Email already registered"
 *                     status: 400
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login with email and password
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: password123
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 session:
 *                   type: object
 *                   properties:
 *                     access_token:
 *                       type: string
 *                       description: JWT access token
 *                     refresh_token:
 *                       type: string
 *                       description: Refresh token
 *                 user:
 *                   type: object
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error:
 *                 code: "VALIDATION_ERROR"
 *                 message: "Email and password are required"
 *                 status: 400
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error:
 *                 code: "LOGIN_FAILED"
 *                 message: "Invalid email or password"
 *                 status: 401
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout current user
 *     tags: [Authentication]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Logout successful
 *       400:
 *         description: Logout failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error:
 *                 code: "LOGOUT_FAILED"
 *                 message: "Failed to logout user"
 *                 status: 400
 */
router.post('/logout', authController.logout);

/**
 * @swagger
 * /api/auth/refresh:
 *   post:
 *     summary: Refresh access token
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refresh_token
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 description: The refresh token received during login
 *     responses:
 *       200:
 *         description: Token refreshed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 session:
 *                   type: object
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error:
 *                 code: "VALIDATION_ERROR"
 *                 message: "Refresh token is required"
 *                 status: 400
 *       401:
 *         description: Invalid or expired refresh token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error:
 *                 code: "REFRESH_TOKEN_FAILED"
 *                 message: "Invalid or expired refresh token"
 *                 status: 401
 */
router.post('/refresh', authController.refreshToken);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get current authenticated user
 *     tags: [Authentication]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: User data retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                     email:
 *                       type: string
 *                     user_metadata:
 *                       type: object
 *       401:
 *         description: Unauthorized - invalid or missing token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             examples:
 *               missingToken:
 *                 summary: Missing authorization token
 *                 value:
 *                   error:
 *                     code: "MISSING_AUTH_TOKEN"
 *                     message: "Authorization token is required"
 *                     status: 401
 *               unauthorized:
 *                 summary: Invalid token
 *                 value:
 *                   error:
 *                     code: "UNAUTHORIZED"
 *                     message: "Invalid or expired token"
 *                     status: 401
 */
router.get('/me', authController.getCurrentUser);

module.exports = router;
