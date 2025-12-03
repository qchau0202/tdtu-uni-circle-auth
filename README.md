# TDTU UniCircle - Auth Service
This project is for Final of SOA course - [AUTH SERVICE]

## Features

- ✅ Student email validation (format: `student_code@student.tdtu.edu.vn`)
- ✅ JWT/OAuth2 authentication via Supabase
- ✅ Automatic student profile creation
- ✅ Student code parsing (faculty ID, academic year extraction)
- ✅ Rate limiting and security middleware
- ✅ Swagger/OpenAPI documentation

## Database Setup

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `database_setup.sql`
5. Run the query to create tables and policies

## Student Email Format

**Required format:** `XYYZNNNNN@student.tdtu.edu.vn`

Example: `523K0013@student.tdtu.edu.vn`

**Format breakdown:**
- **5** (1st character) = Faculty Code (1-9, A-F)
- **23** (2nd-3rd digits) = Year of admission (2023)
- **K** (letter) = Program type (K = regular program)
- **0013** (last 4 digits) = Student index number

**TDTU Faculty Codes:**
- `0` = Foreign Languages (Khoa Ngoại ngữ)
- `1` = Industrial Fine Arts (Khoa Mỹ thuật công nghiệp)
- `2` = Accounting (Khoa Kế toán)
- `3` = Social Sciences & Humanities (Khoa KHXH & Nhân văn)
- `4` = Electrical & Electronics Engineering (Khoa Điện - Điện tử)
- `5` = Information Technology (Khoa Công nghệ thông tin)
- `6` = Applied Sciences (Khoa Khoa học ứng dụng)
- `7` = Business Administration (Khoa Quản trị kinh doanh)
- `8` = Civil Engineering (Khoa Kỹ thuật công trình)
- `9` = Environment & Occupational Safety (Khoa Môi trường & BHLĐ)
- `A` = Labor and Trade Union (Khoa Lao động công đoàn)
- `B` = Finance & Banking (Khoa Tài chính ngân hàng)
- `C` = Mathematics & Statistics (Khoa Toán - Thống kê)
- `D` = Sport Science (Khoa Khoa học thể thao)
- `E` = Law (Khoa Luật)
- `F, G` = International Education (Khoa Giáo dục quốc tế)
- `H` = Pharmacy (Khoa Dược)

## API Endpoints

### POST /api/auth/register
Register a new student

```json
{
  "student_email": "523K0013@student.tdtu.edu.vn",
  "username": "John Doe",
  "password": "securepassword123"
}
```

### POST /api/auth/login
Login with student email and password

```json
{
  "email": "523K0013@student.tdtu.edu.vn",
  "password": "securepassword123"
}
```

### GET /api/auth/me
Get current authenticated user (requires JWT token in Authorization header)

### POST /api/auth/refresh
Refresh access token

### POST /api/auth/logout
Logout current user

## Environment Variables

```env
PORT=3001
NODE_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Running the Service

```bash
npm install
npm run dev
```

## Swagger Documentation

Access at: `http://localhost:3001/api-docs`
