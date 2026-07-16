/// Core mock models for Career Matrix frontend.

enum UserRole { student, alumni, mentor, company, admin }

extension UserRoleX on UserRole {
  String get key => toString().split('.').last;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.alumni:
        return 'Alumni';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.company:
        return 'Company';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get tagline {
    switch (this) {
      case UserRole.student:
        return 'Discover your ideal career path';
      case UserRole.alumni:
        return 'Give back, mentor & network';
      case UserRole.mentor:
        return 'Guide the next generation';
      case UserRole.company:
        return 'Hire top emerging talent';
      case UserRole.admin:
        return 'Manage the ecosystem';
    }
  }
}

class AppUser {
  final String name;
  final String title;
  final UserRole role;
  final String avatarInitials;
  final int careerHealthScore;
  final int placementReadiness;

  const AppUser({
    required this.name,
    required this.title,
    required this.role,
    required this.avatarInitials,
    this.careerHealthScore = 78,
    this.placementReadiness = 64,
  });
}

class CareerPath {
  final String title;
  final String description;
  final int matchPercent;
  final List<String> keySkills;
  final String icon; // material icon codepoint name key

  const CareerPath({
    required this.title,
    required this.description,
    required this.matchPercent,
    required this.keySkills,
    required this.icon,
  });
}

class SkillItem {
  final String name;
  final double progress; // 0..1
  final String level; // Beginner / Intermediate / Advanced
  final bool isGap;

  const SkillItem({
    required this.name,
    required this.progress,
    required this.level,
    this.isGap = false,
  });
}

class CourseRecommendation {
  final String title;
  final String provider;
  final String duration;
  final double rating;

  const CourseRecommendation({
    required this.title,
    required this.provider,
    required this.duration,
    required this.rating,
  });
}

class MentorProfile {
  final String name;
  final String role;
  final String company;
  final String domain;
  final int experienceYears;
  final int matchPercent;
  final double rating;
  final String initials;

  const MentorProfile({
    required this.name,
    required this.role,
    required this.company,
    required this.domain,
    required this.experienceYears,
    required this.matchPercent,
    required this.rating,
    required this.initials,
  });
}

class JobListing {
  final String title;
  final String company;
  final String location;
  final String type; // Full-time, Internship
  final String salary;
  final int matchPercent;
  final List<String> tags;
  final String postedAgo;

  const JobListing({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.matchPercent,
    required this.tags,
    required this.postedAgo,
  });
}

class ForumPost {
  final String author;
  final String role;
  final String title;
  final String preview;
  final int likes;
  final int comments;
  final String timeAgo;

  const ForumPost({
    required this.author,
    required this.role,
    required this.title,
    required this.preview,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class NotificationItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final String type; // job, mentor, community, system
  final bool unread;

  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
    this.unread = false,
  });
}

class InterviewSession {
  final String title;
  final String type; // Technical / HR
  final String difficulty;
  final int durationMins;
  final int lastScore;

  const InterviewSession({
    required this.title,
    required this.type,
    required this.difficulty,
    required this.durationMins,
    this.lastScore = 0,
  });
}

class CandidateProfile {
  final String name;
  final String course;
  final String college;
  final int matchPercent;
  final List<String> skills;
  final String initials;

  const CandidateProfile({
    required this.name,
    required this.course,
    required this.college,
    required this.matchPercent,
    required this.skills,
    required this.initials,
  });
}
