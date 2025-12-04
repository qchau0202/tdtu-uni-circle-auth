/**
 * TDTU Faculty Code Mapping
 */
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

module.exports = {
    facultyMap,
    parseStudentEmail
};
