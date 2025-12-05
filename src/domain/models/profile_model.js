class Profile {
    constructor(data) {
        this.id = data.id;
        this.student_id = data.student_id;
        this.display_name = data.display_name;
        this.dob = data.dob;
        this.phone_number = data.phone_number;
        this.faculty = data.faculty;
        this.academic_year = data.academic_year;
        this.bio = data.bio;
        this.avatar_url = data.avatar_url;
        this.social_links = data.social_links;
        this.updated_at = data.updated_at;
        this.student = data.student;
    }

    static fromDatabase(data) {
        return new Profile(data);
    }

    toJSON() {
        return {
            id: this.id,
            student_id: this.student_id,
            display_name: this.display_name,
            dob: this.dob,
            phone_number: this.phone_number,
            faculty: this.faculty,
            academic_year: this.academic_year,
            bio: this.bio,
            avatar_url: this.avatar_url,
            social_links: this.social_links,
            updated_at: this.updated_at,
            student: this.student
        };
    }
}

module.exports = Profile;
