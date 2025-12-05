class Student {
    constructor(data) {
        this.id = data.id;
        this.student_code = data.student_code;
        this.email = data.email;
        this.created_at = data.created_at;
    }

    static fromDatabase(data) {
        return new Student(data);
    }

    toJSON() {
        return {
            id: this.id,
            student_code: this.student_code,
            email: this.email,
            created_at: this.created_at
        };
    }
}

module.exports = Student;
