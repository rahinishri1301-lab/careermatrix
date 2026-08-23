// lib/services/backend_repository.dart
//
// Single place every screen goes through to read/write real data from the
// Node/Express + MongoDB backend. Each method calls the matching REST
// endpoint and maps the JSON response onto the existing UI model classes
// (see lib/models/models.dart) so screens keep their original widgets and
// just swap MockData.xxx for BackendRepository.instance.xxx().

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'download_helper.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_native.dart';

class BackendRepository {
  BackendRepository._();
  static final BackendRepository instance = BackendRepository._();
  final ApiClient _api = ApiClient.instance;

  List<Map<String, dynamic>> _list(dynamic res) {
    final data = res['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  /// Returns the merged {user, profile} for the logged-in account, or
  /// throws if not reachable. `profile` is null if the user hasn't filled
  /// one in yet (backend returns 404 for GET /api/profile/me in that case).
  Future<AppUser> getMyAppUser() async {
    final meRes = await _api.get('/auth/me');
    final user = meRes['data']['user'] as Map<String, dynamic>;
    Map<String, dynamic>? profile;
    try {
      final profileRes = await _api.get('/profile/me');
      profile = profileRes['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    return AppUser.fromJson(user, profile: profile);
  }

  Future<Map<String, dynamic>?> getMyProfileRaw() async {
    try {
      final res = await _api.get('/profile/me');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Creates the profile if none exists yet, otherwise updates it.
  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final existing = await getMyProfileRaw();
    if (existing == null) {
      await _api.post('/profile', body: fields);
    } else {
      await _api.put('/profile', body: fields);
    }
  }

  // ---------------------------------------------------------------------
  // Skills
  // ---------------------------------------------------------------------

  Future<List<SkillItem>> getMySkills() async {
    final res = await _api.get('/skills/me');
    return _list(res).map(SkillItem.fromJson).toList();
  }

  Future<void> addSkill({
    required String skillName,
    String category = 'Technical',
    String proficiencyLevel = 'Beginner',
  }) async {
    await _api.post('/skills', body: {
      'skillName': skillName,
      'category': category,
      'proficiencyLevel': proficiencyLevel,
    });
  }

  Future<void> deleteSkill(String id) async {
    await _api.delete('/skills/$id');
  }

  // ---------------------------------------------------------------------
  // Education
  // ---------------------------------------------------------------------

  Future<List<EducationRecord>> getMyEducation() async {
    final res = await _api.get('/education/me');
    return _list(res).map(EducationRecord.fromJson).toList();
  }

  Future<void> addEducation({
    required String institution,
    required String degree,
    String? department,
    String? course,
    required int startYear,
    int? endYear,
    String? grade,
  }) async {
    await _api.post('/education', body: {
      'institution': institution,
      'degree': degree,
      if (department != null && department.isNotEmpty) 'department': department,
      if (course != null && course.isNotEmpty) 'course': course,
      'startYear': startYear,
      if (endYear != null) 'endYear': endYear,
      if (grade != null && grade.isNotEmpty) 'grade': grade,
    });
  }

  Future<void> updateEducation(
    String id, {
    String? institution,
    String? degree,
    String? department,
    String? course,
    int? startYear,
    int? endYear,
    String? grade,
  }) async {
    await _api.put('/education/$id', body: {
      if (institution != null) 'institution': institution,
      if (degree != null) 'degree': degree,
      if (department != null) 'department': department,
      if (course != null) 'course': course,
      if (startYear != null) 'startYear': startYear,
      if (endYear != null) 'endYear': endYear,
      if (grade != null) 'grade': grade,
    });
  }

  Future<void> deleteEducation(String id) async {
    await _api.delete('/education/$id');
  }

  // ---------------------------------------------------------------------
  // Certificates
  // ---------------------------------------------------------------------

  Future<List<CertificateItem>> getMyCertificates() async {
    final res = await _api.get('/certificates/me');
    return _list(res).map(CertificateItem.fromJson).toList();
  }

  Future<void> addCertificate({
    required List<int> bytes,
    required String filename,
    required String title,
    String? issuer,
    DateTime? issueDate,
  }) async {
    await _api.uploadFile(
      '/certificates',
      fieldName: 'certificate',
      bytes: bytes,
      filename: filename,
      fields: {
        'title': title,
        if (issuer != null && issuer.isNotEmpty) 'issuer': issuer,
        if (issueDate != null) 'issueDate': issueDate.toIso8601String(),
      },
    );
  }

  Future<void> deleteCertificate(String id) async {
    await _api.delete('/certificates/$id');
  }

  /// Downloads a certificate.
  /// On native: saves to the app's documents directory and returns the path.
  /// On web: triggers a browser file download and returns the filename.
  Future<String> downloadCertificate(String id, String suggestedFileName) async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/certificates/$id/download');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      String message = 'Could not download certificate (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    String filename = suggestedFileName;
    final disposition = response.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp('filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    return saveDownloadedFile(response.bodyBytes, filename);
  }

  // ---------------------------------------------------------------------
  // Career recommendations
  // ---------------------------------------------------------------------

  /// Fetches the latest saved recommendations; if none exist yet it tries
  /// to generate them (requires the user to have added skills first).
  /// Returns an empty list (never throws) if generation isn't possible yet
  /// so the screen can show a friendly "add skills first" state.
  Future<List<CareerPath>> getCareerPaths() async {
    try {
      final res = await _api.get('/career/recommendations/latest');
      final list = (res['data']['recommendations'] as List?) ?? const [];
      return list.cast<Map<String, dynamic>>().map(CareerPath.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    try {
      final res = await _api.post('/career/recommendations/generate');
      final list = (res['data']['recommendations'] as List?) ?? const [];
      return list.cast<Map<String, dynamic>>().map(CareerPath.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 400) return const []; // no skills added yet
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Candidates (company/alumni/admin browsing students)
  // ---------------------------------------------------------------------

  Future<List<CandidateProfile>> getCandidates({
    String? search,
    String? skill,
    String? domain,
    String? qualification,
    String? experience,
    String? location,
    String? jobId,
    String? internshipId,
  }) async {
    final res = await _api.get('/users/candidates', query: {
      'limit': 50,
      if (search != null && search.isNotEmpty) 'search': search,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
      if (domain != null && domain.isNotEmpty) 'domain': domain,
      if (qualification != null && qualification.isNotEmpty) 'qualification': qualification,
      if (experience != null && experience.isNotEmpty) 'experience': experience,
      if (location != null && location.isNotEmpty) 'location': location,
      if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
      if (internshipId != null && internshipId.isNotEmpty) 'internshipId': internshipId,
    });
    return _list(res).map(CandidateProfile.fromJson).toList();
  }

  /// Real, backend-computed stats for a company's own postings & applications.
  Future<CompanyStats> getCompanyStats() async {
    final res = await _api.get('/jobs/stats/mine');
    final data = res['data'] as Map<String, dynamic>;
    return CompanyStats.fromJson(data);
  }

  Future<({int activePostings, int totalApplications})> getMyPostingStats() async {
    final stats = await getCompanyStats();
    return (
      activePostings: stats.activeOpportunities,
      totalApplications: stats.totalApplications,
    );
  }

  // ---------------------------------------------------------------------
  // Recommended courses (deterministic, skill-gap based)
  // ---------------------------------------------------------------------

  Future<List<CourseRecommendation>> getRecommendedCourses() async {
    final res = await _api.get('/career/courses');
    return _list(res).map(CourseRecommendation.fromJson).toList();
  }

  // ---------------------------------------------------------------------
  // Admin — user management
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllUsersAdmin({String? search, String? role}) async {
    final res = await _api.get('/users', query: {
      'limit': 100,
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
    });
    return _list(res);
  }

  /// Admin-only: create a new account (Student, Alumni, Mentor, Company or
  /// Admin). Stored in MongoDB via the existing User model + bcrypt hashing
  /// (POST /api/users, admin-only route).
  Future<void> createUserAdmin({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    await _api.post('/users', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<void> updateUserAdmin(String userId, {String? role, bool? isActive}) async {
    await _api.put('/users/$userId', body: {
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<void> deleteUserAdmin(String userId) async {
    await _api.delete('/users/$userId');
  }

  // ---------------------------------------------------------------------
  // Mentorship (request/accept/reject) — distinct from session Booking
  // ---------------------------------------------------------------------

  Future<void> sendMentorshipRequest(String mentorId, {String? message}) async {
    await _api.post('/mentorship/$mentorId/request', body: {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<MentorshipRequestItem>> getSentMentorshipRequests() async {
    final res = await _api.get('/mentorship', query: {'role': 'sent'});
    return _list(res).map(MentorshipRequestItem.fromJson).toList();
  }

  Future<List<MentorshipRequestItem>> getReceivedMentorshipRequests() async {
    final res = await _api.get('/mentorship', query: {'role': 'received'});
    return _list(res).map(MentorshipRequestItem.fromJson).toList();
  }

  Future<void> acceptMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/accept');
  }

  Future<void> rejectMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/reject');
  }

  Future<void> cancelMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/cancel');
  }

  // ---------------------------------------------------------------------
  // Profile image
  // ---------------------------------------------------------------------

  Future<void> uploadProfileImage(List<int> bytes, String filename) async {
    await _api.uploadFile('/profile/upload-image', fieldName: 'image', bytes: bytes, filename: filename, method: 'PUT');
  }

  // ---------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------

  Future<List<JobListing>> getJobs() async {
    final res = await _api.get('/jobs', query: {'limit': 50});
    return _list(res).map(JobListing.fromJson).toList();
  }

  Future<void> applyForJob(String jobId) async {
    await _api.post('/jobs/$jobId/apply', body: {});
  }

  /// Job applications submitted by the logged-in student, most recent first.
  Future<List<ApplicationRecord>> getMyJobApplications() async {
    final res = await _api.get('/jobs/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromJobJson(j)).toList();
  }

  /// Posts a new job listing (company/alumni/admin only, enforced server-side).
  Future<void> createJob({
    required String title,
    required String description,
    required String company,
    required String location,
    String jobType = 'Full-time',
    List<String> skillsRequired = const [],
    String qualification = 'Any Graduate',
    String experienceRequired = 'Not specified',
    int? salaryMin,
    int? salaryMax,
    DateTime? applicationDeadline,
  }) async {
    await _api.post('/jobs', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'jobType': jobType,
      'skillsRequired': skillsRequired,
      'qualification': qualification,
      'experienceRequired': experienceRequired,
      if (salaryMin != null || salaryMax != null)
        'salaryRange': {
          if (salaryMin != null) 'min': salaryMin,
          if (salaryMax != null) 'max': salaryMax,
        },
      if (applicationDeadline != null)
        'applicationDeadline': applicationDeadline.toIso8601String(),
    });
  }

  Future<void> updateJob({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _api.put('/jobs/$id', body: data);
  }

  Future<void> deleteJob(String id) async {
    await _api.delete('/jobs/$id');
  }

  Future<void> toggleJobStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus.toLowerCase() == 'open' ? 'Closed' : 'Open';
    await _api.put('/jobs/$id', body: {'status': nextStatus});
  }

  Future<List<JobListing>> getMyPostings() async {
    final jobsRes = await _api.get('/jobs', query: {'postedByMe': 'true', 'limit': 100});
    final jobs = _list(jobsRes).map(JobListing.fromJson).toList();
    final internshipsRes = await _api.get('/internships', query: {'postedByMe': 'true', 'limit': 100});
    final internships = _list(internshipsRes).map(JobListing.fromInternshipJson).toList();
    return [...jobs, ...internships];
  }

  /// Posts a new internship listing (company/alumni/admin only).
  Future<void> createInternship({
    required String title,
    required String description,
    required String company,
    required String location,
    required String duration,
    num? stipend,
    List<String> skillsRequired = const [],
    String qualification = 'Any Student',
    DateTime? applicationDeadline,
  }) async {
    await _api.post('/internships', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'duration': duration,
      if (stipend != null) 'stipend': stipend,
      'skillsRequired': skillsRequired,
      'qualification': qualification,
      if (applicationDeadline != null)
        'applicationDeadline': applicationDeadline.toIso8601String(),
    });
  }

  Future<void> updateInternship({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _api.put('/internships/$id', body: data);
  }

  Future<void> deleteInternship(String id) async {
    await _api.delete('/internships/$id');
  }

  Future<void> toggleInternshipStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus.toLowerCase() == 'open' ? 'Closed' : 'Open';
    await _api.put('/internships/$id', body: {'status': nextStatus});
  }

  // ---------------------------------------------------------------------
  // Internships
  // ---------------------------------------------------------------------

  Future<List<JobListing>> getInternships() async {
    final res = await _api.get('/internships', query: {'limit': 50});
    return _list(res).map(JobListing.fromInternshipJson).toList();
  }

  Future<void> applyForInternship(String internshipId) async {
    await _api.post('/internships/$internshipId/apply', body: {});
  }

  /// Internship applications submitted by the logged-in student, most recent first.
  Future<List<ApplicationRecord>> getMyInternshipApplications() async {
    final res = await _api.get('/internships/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromInternshipJson(j)).toList();
  }

  // ---------------------------------------------------------------------
  // Mentors
  // ---------------------------------------------------------------------

  Future<List<MentorProfile>> getMentors() async {
    final res = await _api.get('/mentors', query: {'limit': 50});
    return _list(res).map(MentorProfile.fromJson).toList();
  }

  Future<void> bookMentorSession({
    required String mentorId,
    required DateTime sessionDate,
    required String sessionTime,
    String? topic,
  }) async {
    await _api.post('/mentors/$mentorId/book', body: {
      'sessionDate': sessionDate.toIso8601String(),
      'sessionTime': sessionTime,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });
  }

  // ---------------------------------------------------------------------
  // Community
  // ---------------------------------------------------------------------

  Future<List<ForumPost>> getForumPosts() async {
    final myId = await AuthService.instance.currentUserId;
    final res = await _api.get('/community/posts', query: {'limit': 50});
    return _list(res).map((j) => ForumPost.fromJson(j, myUserId: myId)).toList();
  }

  Future<void> createPost(String content) async {
    await _api.post('/community/posts', body: {'content': content});
  }

  Future<void> updatePost(String postId, String content) async {
    await _api.put('/community/posts/$postId', body: {'content': content});
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/community/posts/$postId');
  }

  Future<void> toggleLikePost(String postId) async {
    await _api.put('/community/posts/$postId/like');
  }

  Future<List<PostComment>> getPostComments(String postId) async {
    final res = await _api.get('/community/posts/$postId/comments', query: {'limit': 50});
    return _list(res).map(PostComment.fromJson).toList();
  }

  Future<void> addComment(String postId, String text) async {
    await _api.post('/community/posts/$postId/comments', body: {'text': text});
  }

  Future<void> deleteComment(String commentId) async {
    await _api.delete('/community/comments/$commentId');
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<List<NotificationItem>> getNotifications() async {
    final res = await _api.get('/notifications/me', query: {'limit': 50});
    return _list(res).map(NotificationItem.fromJson).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.put('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }

  // ---------------------------------------------------------------------
  // Mock interviews
  // ---------------------------------------------------------------------

  Future<List<InterviewSession>> getInterviewHistory() async {
    final res = await _api.get('/interviews/history/me');
    return _list(res).map(InterviewSession.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> getInterviewQuestions({String? category}) async {
    final res = await _api.get('/interviews/questions', query: {
      'limit': 20,
      if (category != null) 'category': category,
    });
    return _list(res);
  }

  Future<void> saveInterviewResult({
    required String type,
    required List<Map<String, dynamic>> questionsAttempted,
    String? feedback,
  }) async {
    await _api.post('/interviews/results', body: {
      'type': type,
      'questionsAttempted': questionsAttempted,
      if (feedback != null) 'feedback': feedback,
    });
  }

  // ---------------------------------------------------------------------
  // Placement history
  // ---------------------------------------------------------------------

  Future<List<PlacementRecord>> getMyPlacementHistory() async {
    final res = await _api.get('/placements/me');
    return _list(res).map(PlacementRecord.fromJson).toList();
  }

  // ---------------------------------------------------------------------
  // Resume
  // ---------------------------------------------------------------------

  Future<void> uploadResume(List<int> bytes, String filename) async {
    await _api.uploadFile('/resume/upload', fieldName: 'resume', bytes: bytes, filename: filename);
  }

  Future<void> updateResume(List<int> bytes, String filename) async {
    await _api.uploadFile('/resume/update', fieldName: 'resume', bytes: bytes, filename: filename, method: 'PUT');
  }

  Future<void> deleteResume() async {
    await _api.delete('/resume');
  }

  /// Lightweight existence/metadata check — does NOT download file bytes.
  Future<Map<String, dynamic>?> getMyResumeMeta() async {
    try {
      final res = await _api.get('/resume/me');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ResumeAnalysis> getResumeAnalysis() async {
    final res = await _api.get('/resume/analysis');
    return ResumeAnalysis.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Downloads the logged-in user's resume.
  /// On native: saves to the app's documents directory and returns the path.
  /// On web: triggers a browser file download and returns the filename.
  Future<String> downloadResume() async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/resume/download');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      String message = 'Could not download resume (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    String filename = 'resume.pdf';
    final disposition = response.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp('filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    return saveDownloadedFile(response.bodyBytes, filename);
  }

  /// Fetches the logged-in user's resume as raw bytes without triggering a
  /// file download. Used by the in-app PDF preview feature.
  Future<List<int>> getResumeBytes() async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/resume/download');
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      String message = 'Could not fetch resume (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    return response.bodyBytes;
  }

  /// Downloads a specific applicant's resume by file path.
  Future<String> downloadApplicantResume(String resumePath) async {
    final token = await _api.token;
    final normalizedPath = resumePath.replaceAll('\\', '/');
    final fileUrl = normalizedPath.startsWith('http')
        ? normalizedPath
        : '${AppConfig.baseUrl.replaceAll('/api', '')}/$normalizedPath';
    final uri = Uri.parse(fileUrl);
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw ApiException('Could not download resume (${response.statusCode})', response.statusCode);
    }
    final filename = normalizedPath.split('/').last;
    return saveDownloadedFile(response.bodyBytes, filename);
  }

  Future<List<OpportunityApplicant>> getJobApplicants(String jobId) async {
    final res = await _api.get('/jobs/$jobId/applicants');
    return _list(res).map(OpportunityApplicant.fromJson).toList();
  }

  Future<List<OpportunityApplicant>> getInternshipApplicants(String internshipId) async {
    final res = await _api.get('/internships/$internshipId/applicants');
    return _list(res).map(OpportunityApplicant.fromJson).toList();
  }

  Future<void> updateJobApplicationStatus(String appId, String status) async {
    await _api.put('/jobs/applications/$appId/status', body: {'status': status});
  }

  Future<void> updateInternshipApplicationStatus(String appId, String status) async {
    await _api.put('/internships/applications/$appId/status', body: {'status': status});
  }

  Future<List<OpportunityApplicant>> getCompanyReceivedApplications() async {
    final res = await _api.get('/jobs/applications/company');
    return _list(res).map(OpportunityApplicant.fromJson).toList();
  }

  // --- CHAT / MESSAGING ENDPOINTS ---

  Future<ChatConversation> createOrGetConversation(String participantId) async {
    final myId = (await AuthService.instance.currentUserId) ?? '';
    final res = await _api.post('/chat/conversations', body: {'participantId': participantId});
    final data = (res is Map && res['data'] is Map) ? res['data'] as Map<String, dynamic> : <String, dynamic>{};
    return ChatConversation.fromJson(data, myId);
  }

  Future<List<ChatConversation>> getConversations() async {
    final myId = (await AuthService.instance.currentUserId) ?? '';
    final res = await _api.get('/chat/conversations', query: {'limit': 50});
    return _list(res).map((c) => ChatConversation.fromJson(c, myId)).toList();
  }

  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    final myId = (await AuthService.instance.currentUserId) ?? '';
    final res = await _api.get('/chat/conversations/$conversationId/messages', query: {'limit': 100});
    final list = _list(res).map((m) => ChatMessage.fromJson(m, myId)).toList();
    return list.reversed.toList(); // ascending order for UI
  }

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    final myId = (await AuthService.instance.currentUserId) ?? '';
    final res = await _api.post('/chat/conversations/$conversationId/messages', body: {'content': content});
    final data = (res is Map && res['data'] is Map) ? res['data'] as Map<String, dynamic> : <String, dynamic>{};
    return ChatMessage.fromJson(data, myId);
  }

  // --- INTERVIEW SCHEDULING ENDPOINTS ---

  Future<void> scheduleInterview({
    required String candidateId,
    String? jobId,
    String? internshipId,
    required String title,
    required String interviewType,
    required DateTime scheduledDate,
    int durationMinutes = 45,
    String meetingLink = '',
    String location = 'Online Video Call',
    String notes = '',
  }) async {
    await _api.post('/interviews/schedule', body: {
      'candidateId': candidateId,
      if (jobId != null) 'jobId': jobId,
      if (internshipId != null) 'internshipId': internshipId,
      'title': title,
      'interviewType': interviewType,
      'scheduledDate': scheduledDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'meetingLink': meetingLink,
      'location': location,
      'notes': notes,
    });
  }

  Future<List<ScheduledInterviewItem>> getCompanyScheduledInterviews() async {
    final res = await _api.get('/interviews/schedule/company');
    return _list(res).map(ScheduledInterviewItem.fromJson).toList();
  }

  Future<List<ScheduledInterviewItem>> getCandidateScheduledInterviews() async {
    final res = await _api.get('/interviews/schedule/candidate');
    return _list(res).map(ScheduledInterviewItem.fromJson).toList();
  }

  Future<void> updateScheduledInterview({
    required String id,
    String? status,
    DateTime? scheduledDate,
    String? meetingLink,
    String? location,
    String? notes,
    String? interviewType,
  }) async {
    await _api.put('/interviews/schedule/$id', body: {
      if (status != null) 'status': status,
      if (scheduledDate != null) 'scheduledDate': scheduledDate.toIso8601String(),
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (interviewType != null) 'interviewType': interviewType,
    });
  }

  Future<void> cancelScheduledInterview(String id) async {
    await _api.delete('/interviews/schedule/$id');
  }
}
