import '../config/app_config.dart';

/// Core mock models for Career Matrix frontend.

enum UserRole { student, alumni, mentor, company, admin }

extension UserRoleX on UserRole {
  String get key => toString().split('.').last;

  static UserRole fromKey(String value) {
    return UserRole.values.firstWhere(
      (r) => r.key.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }

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
  final String? avatarUrl;
  final int careerHealthScore;
  final int placementReadiness;

  const AppUser({
    required this.name,
    required this.title,
    required this.role,
    required this.avatarInitials,
    this.avatarUrl,
    this.careerHealthScore = 78,
    this.placementReadiness = 64,
  });

  /// Builds an [AppUser] from the backend's `/api/auth/me` + `/api/profile/me`
  /// responses. [careerHealthScore]/[placementReadiness] have no backend
  /// equivalent (no such fields exist in the Mongo schema yet) so they stay
  /// as reasonable placeholders until that feature is added server-side.
  factory AppUser.fromJson(Map<String, dynamic> user, {Map<String, dynamic>? profile}) {
    final name = (user['name'] as String?)?.trim() ?? 'Guest User';
    final role = UserRoleX.fromKey(user['role'] as String? ?? 'student');
    final title = profile != null
        ? [profile['currentPosition'], profile['company']]
            .where((e) => e != null && (e as String).isNotEmpty)
            .join(' · ')
        : '';

    String? avatarUrl;
    final imgPath = profile?['profileImage'] as String?;
    if (imgPath != null && imgPath.trim().isNotEmpty) {
      final clean = imgPath.trim().replaceAll('\\', '/');
      avatarUrl = clean.startsWith('http')
          ? clean
          : '${AppConfig.fileBaseUrl}/${clean.startsWith('/') ? clean.substring(1) : clean}';
    }

    return AppUser(
      name: name,
      title: title.isNotEmpty ? title : role.label,
      role: role,
      avatarInitials: _initialsOf(name),
      avatarUrl: avatarUrl,
    );
  }
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String _timeAgo(String? isoDate) {
  if (isoDate == null) return '';
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
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

  /// Maps one entry of the backend's CareerRecommendation.recommendations[]
  /// (GET /api/career/recommendations/latest) to a [CareerPath].
  factory CareerPath.fromJson(Map<String, dynamic> json) {
    return CareerPath(
      title: json['role'] as String? ?? 'Career Path',
      description: (json['reason'] as String?)?.isNotEmpty == true
          ? json['reason'] as String
          : 'Recommended based on your current skill profile.',
      matchPercent: (json['matchScore'] as num?)?.round() ?? 0,
      keySkills: (json['matchedSkills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      icon: 'insights',
    );
  }
}

class SkillItem {
  final String? id;
  final String name;
  final double progress; // 0..1
  final String level; // Beginner / Intermediate / Advanced
  final bool isGap;

  const SkillItem({
    this.id,
    required this.name,
    required this.progress,
    required this.level,
    this.isGap = false,
  });

  /// Maps a backend Skill document (GET /api/skills/me) to a [SkillItem].
  /// The backend stores a discrete `proficiencyLevel` (no 0..1 progress
  /// value), so progress is derived from it for the progress-bar UI.
  factory SkillItem.fromJson(Map<String, dynamic> json) {
    final level = json['proficiencyLevel'] as String? ?? 'Beginner';
    const progressByLevel = {
      'Beginner': 0.25,
      'Intermediate': 0.55,
      'Advanced': 0.8,
      'Expert': 0.97,
    };
    return SkillItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: json['skillName'] as String? ?? 'Skill',
      progress: progressByLevel[level] ?? 0.25,
      level: level,
      isGap: level == 'Beginner',
    );
  }
}

class EducationRecord {
  final String? id;
  final String institution;
  final String degree;
  final String? department;
  final String? course;
  final int startYear;
  final int? endYear;
  final String? grade;

  const EducationRecord({
    this.id,
    required this.institution,
    required this.degree,
    this.department,
    this.course,
    required this.startYear,
    this.endYear,
    this.grade,
  });

  factory EducationRecord.fromJson(Map<String, dynamic> json) {
    return EducationRecord(
      id: (json['_id'] ?? json['id'])?.toString(),
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      department: json['department'] as String?,
      course: json['course'] as String?,
      startYear: (json['startYear'] as num?)?.toInt() ?? DateTime.now().year,
      endYear: (json['endYear'] as num?)?.toInt(),
      grade: json['grade'] as String?,
    );
  }
}

class CertificateItem {
  final String id;
  final String title;
  final String? issuer;
  final DateTime? issueDate;
  final String originalName;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  const CertificateItem({
    required this.id,
    required this.title,
    this.issuer,
    this.issueDate,
    required this.originalName,
    this.fileSizeBytes,
    this.createdAt,
  });

  factory CertificateItem.fromJson(Map<String, dynamic> json) {
    return CertificateItem(
      id: (json['_id'] ?? json['id']).toString(),
      title: json['title'] as String? ?? 'Certificate',
      issuer: json['issuer'] as String?,
      issueDate: json['issueDate'] != null ? DateTime.tryParse(json['issueDate'] as String) : null,
      originalName: json['originalName'] as String? ?? 'certificate',
      fileSizeBytes: (json['fileSize'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class ApplicationRecord {
  final String id;
  final String type; // 'Job' or 'Internship'
  final String title;
  final String company;
  final String location;
  final String status; // Applied / Shortlisted / Rejected / Selected
  final DateTime? appliedAt;

  const ApplicationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.company,
    required this.location,
    required this.status,
    this.appliedAt,
  });

  factory ApplicationRecord.fromJobJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    return ApplicationRecord(
      id: (json['_id'] ?? json['id']).toString(),
      type: 'Job',
      title: job?['title'] as String? ?? 'Job listing removed',
      company: job?['company'] as String? ?? '—',
      location: job?['location'] as String? ?? '—',
      status: json['status'] as String? ?? 'Applied',
      appliedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  factory ApplicationRecord.fromInternshipJson(Map<String, dynamic> json) {
    final internship = json['internship'] as Map<String, dynamic>?;
    return ApplicationRecord(
      id: (json['_id'] ?? json['id']).toString(),
      type: 'Internship',
      title: internship?['title'] as String? ?? 'Internship listing removed',
      company: internship?['company'] as String? ?? '—',
      location: internship?['location'] as String? ?? '—',
      status: json['status'] as String? ?? 'Applied',
      appliedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
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

  /// Maps a backend course-catalog entry (GET /api/career/courses,
  /// deterministically derived from the user's weak skills) to a
  /// [CourseRecommendation].
  factory CourseRecommendation.fromJson(Map<String, dynamic> json) {
    return CourseRecommendation(
      title: json['title'] as String? ?? 'Course',
      provider: json['provider'] as String? ?? '—',
      duration: json['duration'] as String? ?? '—',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }
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

  final String? id;

  const MentorProfile({
    this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.domain,
    required this.experienceYears,
    required this.matchPercent,
    required this.rating,
    required this.initials,
  });

  /// Maps a backend Mentor document (GET /api/mentors, `user` populated
  /// with name/email/role) to a [MentorProfile]. There's no real
  /// "match %" concept server-side yet, so it's derived from rating as a
  /// reasonable stand-in until a real matching algorithm exists.
  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? 'Mentor';
    final expertise = (json['expertise'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    return MentorProfile(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: name,
      role: json['currentPosition'] as String? ?? 'Mentor',
      company: json['currentCompany'] as String? ?? '—',
      domain: expertise.isNotEmpty ? expertise.first : 'General',
      experienceYears: (json['experienceYears'] as num?)?.round() ?? 0,
      matchPercent: (60 + rating * 8).clamp(0, 99).round(),
      rating: rating,
      initials: _initialsOf(name),
    );
  }
}

class JobListing {
  final String? id;
  final String title;
  final String company;
  final String location;
  final String type; // Full-time, Part-time, Contract, Remote, Internship
  final String salary;
  final int matchPercent;
  final List<String> tags;
  final String postedAgo;
  final String description;
  final String qualification;
  final String experience;
  final String status; // 'Open' or 'Closed'
  final DateTime? applicationDeadline;
  final String? postedBy;

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isClosed => status.toLowerCase() == 'closed';

  const JobListing({
    this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.matchPercent,
    required this.tags,
    required this.postedAgo,
    this.description = '',
    this.qualification = 'Any Graduate',
    this.experience = 'Not specified',
    this.status = 'Open',
    this.applicationDeadline,
    this.postedBy,
  });

  /// Maps a backend Job document (GET /api/jobs) to a [JobListing].
  /// `matchScore` is now computed server-side (real skill-overlap logic)
  /// when the request is authenticated; falls back to a light heuristic
  /// only if the backend didn't include one (e.g. older cached response).
  factory JobListing.fromJson(Map<String, dynamic> json) {
    final tags = (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final salaryRange = json['salaryRange'] as Map<String, dynamic>?;
    String salary = 'Not disclosed';
    if (salaryRange != null && (salaryRange['min'] != null || salaryRange['max'] != null)) {
      final min = salaryRange['min'];
      final max = salaryRange['max'];
      salary = min != null && max != null ? '₹$min - ₹$max' : '₹${min ?? max}';
    } else if (json['salary'] != null && json['salary'].toString().isNotEmpty) {
      salary = json['salary'].toString();
    }
    return JobListing(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Job',
      company: json['company'] as String? ?? '—',
      location: json['location'] as String? ?? '—',
      type: json['jobType'] as String? ?? 'Full-time',
      salary: salary,
      matchPercent: (json['matchScore'] as num?)?.round() ?? (55 + tags.length * 6).clamp(0, 96).round(),
      tags: tags,
      postedAgo: _timeAgo(json['createdAt'] as String?),
      description: json['description'] as String? ?? '',
      qualification: json['qualification'] as String? ?? 'Any Graduate',
      experience: json['experienceRequired'] as String? ?? 'Not specified',
      status: json['status'] as String? ?? 'Open',
      applicationDeadline: json['applicationDeadline'] != null ? DateTime.tryParse(json['applicationDeadline'].toString()) : null,
      postedBy: json['postedBy'] is Map ? (json['postedBy']['_id']?.toString()) : json['postedBy']?.toString(),
    );
  }

  /// Maps a backend Internship document (GET /api/internships) to a
  /// [JobListing] (the UI reuses the same card model for both).
  factory JobListing.fromInternshipJson(Map<String, dynamic> json) {
    final tags = (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final stipend = json['stipend'];
    return JobListing(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Internship',
      company: json['company'] as String? ?? '—',
      location: json['location'] as String? ?? '—',
      type: 'Internship',
      salary: stipend != null && stipend != 0 ? '₹$stipend/mo' : 'Unpaid',
      matchPercent: (json['matchScore'] as num?)?.round() ?? (55 + tags.length * 6).clamp(0, 96).round(),
      tags: tags,
      postedAgo: _timeAgo(json['createdAt'] as String?),
      description: json['description'] as String? ?? '',
      qualification: json['qualification'] as String? ?? 'Any Student',
      experience: json['duration'] as String? ?? 'Not specified',
      status: json['status'] as String? ?? 'Open',
      applicationDeadline: json['applicationDeadline'] != null ? DateTime.tryParse(json['applicationDeadline'].toString()) : null,
      postedBy: json['postedBy'] is Map ? (json['postedBy']['_id']?.toString()) : json['postedBy']?.toString(),
    );
  }
}

class ForumPost {
  final String? id;
  final String author;
  final String role;
  final String title;
  final String preview;
  final int likes;
  final int comments;
  final String timeAgo;
  final bool likedByMe;

  const ForumPost({
    this.id,
    required this.author,
    required this.role,
    required this.title,
    required this.preview,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.likedByMe = false,
  });

  /// Maps a backend Post document (GET /api/community/posts, `user`
  /// populated with name/role) to a [ForumPost]. The backend has a single
  /// `content` field (no separate title), so the first line/sentence is
  /// used as a title and the full content as the preview.
  factory ForumPost.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    final user = json['user'] as Map<String, dynamic>?;
    final content = json['content'] as String? ?? '';
    final firstLine = content.split(RegExp(r'[\n.]')).first.trim();
    final likesList = (json['likes'] as List?) ?? const [];
    return ForumPost(
      id: (json['_id'] ?? json['id'])?.toString(),
      author: user?['name'] as String? ?? 'Community Member',
      role: user?['role'] as String? ?? 'Member',
      title: firstLine.isNotEmpty ? firstLine : 'Community post',
      preview: content,
      likes: (json['likesCount'] as num?)?.toInt() ?? likesList.length,
      comments: (json['commentsCount'] as num?)?.toInt() ?? 0,
      timeAgo: _timeAgo(json['createdAt'] as String?),
      likedByMe: myUserId != null && likesList.any((l) => l.toString() == myUserId),
    );
  }
}

class NotificationItem {
  final String? id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String type; // job, mentor, community, system
  final bool unread;

  const NotificationItem({
    this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
    this.unread = false,
  });

  /// Maps a backend Notification document (GET /api/notifications/me) to a
  /// [NotificationItem].
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final backendType = json['type'] as String? ?? 'Info';
    const typeMap = {
      'JobAlert': 'job',
      'InternshipAlert': 'job',
      'MentorshipRequest': 'mentor',
      'Booking': 'mentor',
      'Community': 'community',
      'Placement': 'system',
      'System': 'system',
      'Info': 'system',
      'Other': 'system',
    };
    return NotificationItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Notification',
      subtitle: json['message'] as String? ?? '',
      timeAgo: _timeAgo(json['createdAt'] as String?),
      type: typeMap[backendType] ?? 'system',
      unread: json['isRead'] != true,
    );
  }
}

class PlacementRecord {
  final String? id;
  final String company;
  final String jobTitle;
  final num? package;
  final String placementType;
  final String? location;
  final String placementDate;
  final String status;
  final String? remarks;

  const PlacementRecord({
    this.id,
    required this.company,
    required this.jobTitle,
    this.package,
    required this.placementType,
    this.location,
    required this.placementDate,
    required this.status,
    this.remarks,
  });

  /// Maps a backend Placement document (GET /api/placements/me) to a
  /// [PlacementRecord].
  factory PlacementRecord.fromJson(Map<String, dynamic> json) {
    return PlacementRecord(
      id: (json['_id'] ?? json['id'])?.toString(),
      company: json['company'] as String? ?? '—',
      jobTitle: json['jobTitle'] as String? ?? '—',
      package: json['package'] as num?,
      placementType: json['placementType'] as String? ?? 'Full-time',
      location: json['location'] as String?,
      placementDate: json['placementDate'] as String? ?? '',
      status: json['status'] as String? ?? 'Applied',
      remarks: json['remarks'] as String?,
    );
  }
}

class InterviewSession {
  final String? id;
  final String title;
  final String type; // Technical / HR
  final String difficulty;
  final int durationMins;
  final int lastScore;

  const InterviewSession({
    this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.durationMins,
    this.lastScore = 0,
  });

  /// Maps a backend MockInterview record (GET /api/interviews/history/me)
  /// to an [InterviewSession] for the "past attempts" list. Backend scores
  /// are 0..10, the UI shows 0..100.
  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'Technical';
    final questions = (json['questionsAttempted'] as List?) ?? const [];
    return InterviewSession(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: '$type Mock Interview',
      type: type,
      difficulty: 'Mixed',
      durationMins: (questions.length * 8).clamp(15, 90),
      lastScore: (((json['overallScore'] as num?)?.toDouble() ?? 0) * 10).round(),
    );
  }
}

class ResumeAnalysis {
  final int score;
  final List<String> strengths;
  final List<String> improvements;

  const ResumeAnalysis({required this.score, required this.strengths, required this.improvements});

  /// Maps the backend's deterministic resume-analysis response
  /// (GET /api/resume/analysis) to a [ResumeAnalysis].
  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      score: (json['score'] as num?)?.round() ?? 0,
      strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      improvements: (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class PostComment {
  final String? id;
  final String author;
  final String text;
  final String timeAgo;

  const PostComment({this.id, required this.author, required this.text, required this.timeAgo});

  /// Maps a backend Comment document (GET /api/community/posts/:id/comments)
  /// to a [PostComment].
  factory PostComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return PostComment(
      id: (json['_id'] ?? json['id'])?.toString(),
      author: user?['name'] as String? ?? 'Community Member',
      text: json['text'] as String? ?? '',
      timeAgo: _timeAgo(json['createdAt'] as String?),
    );
  }
}

class MentorshipRequestItem {
  final String? id;
  final String mentorName;
  final String menteeName;
  final String status; // Pending, Accepted, Rejected, Cancelled
  final String? message;
  final String timeAgo;

  const MentorshipRequestItem({
    this.id,
    required this.mentorName,
    required this.menteeName,
    required this.status,
    this.message,
    required this.timeAgo,
  });

  /// Maps a backend MentorshipRequest document (GET /api/mentorship,
  /// /api/mentorship/history) to a [MentorshipRequestItem]. `mentor.user`
  /// and `requester` are populated with user info server-side.
  factory MentorshipRequestItem.fromJson(Map<String, dynamic> json) {
    final mentor = json['mentor'] as Map<String, dynamic>?;
    final mentorUser = mentor?['user'] as Map<String, dynamic>?;
    final requester = json['requester'] as Map<String, dynamic>?;
    return MentorshipRequestItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      mentorName: mentorUser?['name'] as String? ?? (mentor?['name'] as String?) ?? 'Mentor',
      menteeName: requester?['name'] as String? ?? 'Student',
      status: json['status'] as String? ?? 'Pending',
      message: json['message'] as String?,
      timeAgo: _timeAgo(json['createdAt'] as String?),
    );
  }
}

class CandidateProfile {
  final String? id;
  final String name;
  final String email;
  final String role;
  final String course;
  final String college;
  final String department;
  final String location;
  final String graduationYear;
  final String bio;
  final String phone;
  final int matchPercent;
  final List<String> skills;
  final String initials;

  const CandidateProfile({
    this.id,
    required this.name,
    this.email = '',
    this.role = 'student',
    required this.course,
    required this.college,
    this.department = '—',
    this.location = '—',
    this.graduationYear = '—',
    this.bio = '',
    this.phone = '—',
    required this.matchPercent,
    required this.skills,
    required this.initials,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Candidate';
    final email = json['email'] as String? ?? '';
    final role = json['role'] as String? ?? 'student';
    final skillsRaw = json['skills'] as List?;
    final skillNames = <String>[];
    if (skillsRaw != null) {
      for (final item in skillsRaw) {
        if (item is String) {
          skillNames.add(item);
        } else if (item is Map && item['skillName'] != null) {
          skillNames.add(item['skillName'].toString());
        }
      }
    }
    final profile = json['profile'] as Map<String, dynamic>?;
    final backendMatch = json['matchPercent'] as num?;
    final computedMatch = backendMatch?.toInt() ?? (40 + skillNames.length * 10).clamp(40, 98).round();

    return CandidateProfile(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: name,
      email: email,
      role: role,
      course: profile?['currentPosition'] as String? ?? 'Student',
      college: profile?['company'] as String? ?? '—',
      department: profile?['department'] as String? ?? '—',
      location: profile?['address'] as String? ?? '—',
      graduationYear: profile?['graduationYear'] != null ? profile!['graduationYear'].toString() : '—',
      bio: profile?['bio'] as String? ?? '',
      phone: profile?['phone'] as String? ?? '—',
      matchPercent: computedMatch,
      skills: skillNames,
      initials: _initialsOf(name),
    );
  }
}

class CompanyStats {
  final int totalJobsPosted;
  final int totalInternshipsPosted;
  final int activeOpportunities;
  final int totalApplications;
  final int pendingApplications;
  final int shortlistedCandidates;
  final int selectedCandidates;
  final int rejectedApplications;

  const CompanyStats({
    required this.totalJobsPosted,
    required this.totalInternshipsPosted,
    required this.activeOpportunities,
    required this.totalApplications,
    required this.pendingApplications,
    required this.shortlistedCandidates,
    required this.selectedCandidates,
    required this.rejectedApplications,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      totalJobsPosted: (json['totalJobsPosted'] as num?)?.toInt() ?? 0,
      totalInternshipsPosted: (json['totalInternshipsPosted'] as num?)?.toInt() ?? 0,
      activeOpportunities: (json['activeOpportunities'] as num?)?.toInt() ?? (json['activePostings'] as num?)?.toInt() ?? 0,
      totalApplications: (json['totalApplications'] as num?)?.toInt() ?? 0,
      pendingApplications: (json['pendingApplications'] as num?)?.toInt() ?? 0,
      shortlistedCandidates: (json['shortlistedCandidates'] as num?)?.toInt() ?? 0,
      selectedCandidates: (json['selectedCandidates'] as num?)?.toInt() ?? 0,
      rejectedApplications: (json['rejectedApplications'] as num?)?.toInt() ?? 0,
    );
  }
}

class OpportunityApplicant {
  final String id;
  final String applicantId;
  final String name;
  final String email;
  final String opportunityType; // 'Job' or 'Internship'
  final String opportunityTitle;
  final String coverLetter;
  final String? resumePath;
  final String status; // 'Applied', 'Pending', 'Shortlisted', 'Selected', 'Rejected'
  final DateTime? appliedAt;
  final String department;
  final String graduationYear;
  final String currentPosition;
  final String phone;
  final String bio;
  final List<String> skills;
  final List<StudentCertificate> certificates;

  String get initials => _initialsOf(name);

  const OpportunityApplicant({
    required this.id,
    required this.applicantId,
    required this.name,
    required this.email,
    required this.opportunityType,
    required this.opportunityTitle,
    required this.coverLetter,
    this.resumePath,
    required this.status,
    this.appliedAt,
    this.department = '—',
    this.graduationYear = '—',
    this.currentPosition = 'Student',
    this.phone = '—',
    this.bio = '',
    this.skills = const [],
    this.certificates = const [],
  });

  factory OpportunityApplicant.fromJson(Map<String, dynamic> json) {
    final applicantMap = json['applicant'] is Map ? json['applicant'] as Map<String, dynamic> : <String, dynamic>{};
    final profileMap = json['profile'] is Map ? json['profile'] as Map<String, dynamic> : <String, dynamic>{};
    final skillList = (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final certList = (json['certificates'] as List?)?.map((e) => StudentCertificate.fromJson(e as Map<String, dynamic>)).toList() ?? const [];

    return OpportunityApplicant(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      applicantId: (applicantMap['_id'] ?? applicantMap['id'])?.toString() ?? '',
      name: applicantMap['name'] as String? ?? 'Student Applicant',
      email: applicantMap['email'] as String? ?? '',
      opportunityType: json['opportunityType'] as String? ?? 'Job',
      opportunityTitle: json['opportunityTitle'] as String? ?? 'Opportunity',
      coverLetter: json['coverLetter'] as String? ?? '',
      resumePath: json['resumePath'] as String?,
      status: json['status'] as String? ?? 'Applied',
      appliedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      department: profileMap['department'] as String? ?? '—',
      graduationYear: profileMap['graduationYear'] != null ? profileMap['graduationYear'].toString() : '—',
      currentPosition: profileMap['currentPosition'] as String? ?? 'Student',
      phone: profileMap['phone'] as String? ?? '—',
      bio: profileMap['bio'] as String? ?? '',
      skills: skillList,
      certificates: certList,
    );
  }
}

class StudentCertificate {
  final String id;
  final String title;
  final String issuer;
  final String? filePath;

  const StudentCertificate({
    required this.id,
    required this.title,
    required this.issuer,
    this.filePath,
  });

  factory StudentCertificate.fromJson(Map<String, dynamic> json) {
    return StudentCertificate(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      title: json['title'] as String? ?? 'Certificate',
      issuer: json['issuer'] as String? ?? '—',
      filePath: json['filePath'] as String?,
    );
  }
}

class ChatConversation {
  final String id;
  final String otherParticipantId;
  final String otherParticipantName;
  final String otherParticipantRole;
  final String lastMessageContent;
  final DateTime? lastMessageAt;

  String get initials => _initialsOf(otherParticipantName);

  const ChatConversation({
    required this.id,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.otherParticipantRole,
    required this.lastMessageContent,
    this.lastMessageAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = (json['participants'] as List?) ?? [];
    Map<String, dynamic> other = {};
    for (final p in participants) {
      if (p is Map) {
        final pId = (p['_id'] ?? p['id'])?.toString();
        if (pId != currentUserId) {
          other = p as Map<String, dynamic>;
          break;
        }
      }
    }

    final lastMsg = json['lastMessage'] is Map ? json['lastMessage'] as Map<String, dynamic> : null;
    final lastContent = lastMsg != null ? (lastMsg['content'] as String? ?? 'Message') : 'Started a conversation';

    return ChatConversation(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      otherParticipantId: (other['_id'] ?? other['id'])?.toString() ?? '',
      otherParticipantName: other['name'] as String? ?? 'User',
      otherParticipantRole: (other['role'] as String? ?? 'student').toLowerCase(),
      lastMessageContent: lastContent,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt'].toString()) : null,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime? createdAt;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderMap = json['sender'] is Map ? json['sender'] as Map<String, dynamic> : <String, dynamic>{};
    final sId = (senderMap['_id'] ?? senderMap['id'] ?? json['sender'])?.toString() ?? '';

    return ChatMessage(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      conversationId: (json['conversation'] is Map ? json['conversation']['_id'] : json['conversation'])?.toString() ?? '',
      senderId: sId,
      senderName: senderMap['name'] as String? ?? 'User',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      isMe: sId == currentUserId,
    );
  }
}

class ScheduledInterviewItem {
  final String id;
  final String title;
  final String interviewType;
  final String candidateId;
  final String candidateName;
  final String companyName;
  final String opportunityTitle;
  final DateTime scheduledDate;
  final int durationMinutes;
  final String meetingLink;
  final String location;
  final String notes;
  final String status;

  const ScheduledInterviewItem({
    required this.id,
    required this.title,
    required this.interviewType,
    required this.candidateId,
    required this.candidateName,
    required this.companyName,
    required this.opportunityTitle,
    required this.scheduledDate,
    required this.durationMinutes,
    required this.meetingLink,
    required this.location,
    required this.notes,
    required this.status,
  });

  factory ScheduledInterviewItem.fromJson(Map<String, dynamic> json) {
    final candidateMap = json['candidate'] is Map ? json['candidate'] as Map<String, dynamic> : <String, dynamic>{};
    final companyMap = json['company'] is Map ? json['company'] as Map<String, dynamic> : <String, dynamic>{};
    final jobMap = json['job'] is Map ? json['job'] as Map<String, dynamic> : null;
    final internMap = json['internship'] is Map ? json['internship'] as Map<String, dynamic> : null;

    final oppTitle = jobMap?['title'] as String? ?? (internMap?['title'] as String?) ?? 'Position';
    final compName = companyMap['company'] as String? ?? (companyMap['name'] as String?) ?? 'Company';

    return ScheduledInterviewItem(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      title: json['title'] as String? ?? 'Interview',
      interviewType: json['interviewType'] as String? ?? 'Technical',
      candidateId: (candidateMap['_id'] ?? candidateMap['id'] ?? json['candidate'])?.toString() ?? '',
      candidateName: candidateMap['name'] as String? ?? 'Candidate',
      companyName: compName,
      opportunityTitle: oppTitle,
      scheduledDate: json['scheduledDate'] != null ? DateTime.tryParse(json['scheduledDate'].toString()) ?? DateTime.now() : DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      meetingLink: json['meetingLink'] as String? ?? '',
      location: json['location'] as String? ?? 'Online Video Call',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Scheduled',
    );
  }
}
