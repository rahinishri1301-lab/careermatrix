// lib/services/backend_repository.dart
//
// Single place every screen goes through to read/write real data from the
// Node/Express + MongoDB backend. Each method calls the matching REST
// endpoint and maps the JSON response onto the existing UI model classes
// (see lib/models/models.dart) so screens keep their original widgets and
// just swap MockData.xxx for BackendRepository.instance.xxx().

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import '../utils/file_saver.dart';
import 'api_client.dart';
import 'auth_service.dart';

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
    // /profile/me doesn't depend on /auth/me's response (both are resolved
    // from the JWT server-side), so fire them together instead of
    // sequentially — this was adding a full extra network round-trip to
    // every dashboard load for no reason.
    final results = await Future.wait([
      _api.get('/auth/me'),
      _fetchOptionalProfile(),
    ]);
    final user = (results[0] as Map<String, dynamic>)['data']['user'] as Map<String, dynamic>;
    final profile = results[1] as Map<String, dynamic>?;
    return AppUser.fromJson(user, profile: profile);
  }

  Future<Map<String, dynamic>?> _fetchOptionalProfile() async {
    try {
      final res = await _api.get('/profile/me');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
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

  Future<void> updateSkill(
    String id, {
    required String skillName,
    required String category,
    required String proficiencyLevel,
  }) async {
    await _api.put('/skills/$id', body: {
      'skillName': skillName,
      'category': category,
      'proficiencyLevel': proficiencyLevel,
    });
  }

  Future<void> deleteSkill(String id) async {
    await _api.delete('/skills/$id');
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

  Future<List<CandidateProfile>> getCandidates({String? skill}) async {
    final res = await _api.get('/users/candidates', query: {
      'limit': 50,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
    });
    return _list(res).map(CandidateProfile.fromJson).toList();
  }

  // ---------------------------------------------------------------------
  // Alumni directory (student-facing browse + profile view)
  // ---------------------------------------------------------------------

  Future<List<AlumniProfile>> getAlumni({String? search}) async {
    final res = await _api.get('/users/alumni', query: {
      'limit': 50,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return _list(res).map(AlumniProfile.fromJson).toList();
  }

  /// Fetches any user's Profile document by their User id
  /// (GET /api/profile/:userId) — used for viewing an alumni's, mentor's,
  /// or student's profile from someone else's account. Returns null if
  /// that user hasn't filled in a profile yet (backend 404s in that case).
  Future<Map<String, dynamic>?> getUserProfileRaw(String userId) async {
    try {
      final res = await _api.get('/profile/$userId');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Chat (used for "send a question" to an alumni — mentorship-request
  // flow doesn't apply since MentorshipRequest.mentor only references the
  // Mentor collection, not arbitrary alumni User accounts)
  // ---------------------------------------------------------------------

  /// Creates (or reuses the existing) 1:1 conversation with [participantId]
  /// and returns its id.
  Future<String> startConversation(String participantId) async {
    final res = await _api.post('/chat/conversations', body: {'participantId': participantId});
    final data = res['data'] as Map<String, dynamic>;
    return (data['_id'] ?? data['id']).toString();
  }

  Future<void> sendChatMessage(String conversationId, String content) async {
    await _api.post('/chat/conversations/$conversationId/messages', body: {'content': content});
  }

  /// Real, backend-computed stats for a company's own postings.
  Future<({int activePostings, int totalApplications})> getMyPostingStats() async {
    final res = await _api.get('/jobs/stats/mine');
    final data = res['data'] as Map<String, dynamic>;
    return (
      activePostings: (data['activePostings'] as num?)?.toInt() ?? 0,
      totalApplications: (data['totalApplications'] as num?)?.toInt() ?? 0,
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

  Future<List<ApplicationRecord>> getMyJobApplications() async {
    final res = await _api.get('/jobs/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromJson(j, isInternship: false)).toList();
  }

  /// Posts a new job listing (company/alumni/admin only, enforced server-side).
  /// jobType must be one of Full-time/Part-time/Contract/Remote.
  Future<void> createJob({
    required String title,
    required String description,
    required String company,
    required String location,
    String jobType = 'Full-time',
    List<String> skillsRequired = const [],
    int? salaryMin,
    int? salaryMax,
  }) async {
    await _api.post('/jobs', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'jobType': jobType,
      'skillsRequired': skillsRequired,
      if (salaryMin != null || salaryMax != null)
        'salaryRange': {
          if (salaryMin != null) 'min': salaryMin,
          if (salaryMax != null) 'max': salaryMax,
        },
    });
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
  }) async {
    await _api.post('/internships', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'duration': duration,
      if (stipend != null) 'stipend': stipend,
      'skillsRequired': skillsRequired,
    });
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

  Future<List<ApplicationRecord>> getMyInternshipApplications() async {
    final res = await _api.get('/internships/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromJson(j, isInternship: true)).toList();
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

  /// The logged-in user's own Mentor profile (throws 404 via ApiException
  /// if they haven't registered as a mentor yet).
  Future<Map<String, dynamic>> getMyMentorProfile() async {
    final res = await _api.get('/mentors/me/profile');
    return res['data'] as Map<String, dynamic>;
  }

  /// Real booking history split into asStudent/asMentor by the backend.
  Future<Map<String, List<Map<String, dynamic>>>> getBookingHistory() async {
    final res = await _api.get('/mentors/bookings/history');
    final data = res['data'] as Map<String, dynamic>;
    return {
      'asStudent': ((data['asStudent'] as List?) ?? const []).cast<Map<String, dynamic>>(),
      'asMentor': ((data['asMentor'] as List?) ?? const []).cast<Map<String, dynamic>>(),
    };
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

  /// Fetches raw PDF bytes from the inline /resume/view endpoint.
  /// Used by the in-app PDF viewer — does NOT save a file to disk.
  Future<List<int>> getResumeViewBytes() async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/resume/view');
    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      String message = 'Could not load resume (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
    return response.bodyBytes;
  }

  /// Opens the resume inline in a new tab (Web only).
  Future<void> viewResumeInNewTab() async {
    final token = await _api.token;
    final url = '${AppConfig.baseUrl}/resume/view?token=$token';
    openUrlInNewTab(url);
  }

  // ---------------------------------------------------------------------
  // Certificates
  // ---------------------------------------------------------------------

  Future<List<CertificateItem>> getMyCertificates() async {
    final res = await _api.get('/certificates/me');
    return _list(res).map(CertificateItem.fromJson).toList();
  }

  Future<void> uploadCertificate({
    required List<int> bytes,
    required String filename,
    required String title,
    String? issuer,
  }) async {
    await _api.uploadFile(
      '/certificates',
      fieldName: 'certificate',
      bytes: bytes,
      filename: filename,
      fields: {
        'title': title,
        if (issuer != null && issuer.isNotEmpty) 'issuer': issuer,
      },
    );
  }

  Future<void> deleteCertificate(String id) async {
    await _api.delete('/certificates/$id');
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

  /// Downloads a file (resume or certificate) and saves it to the app's
  /// documents directory. Returns the local file path on success.
  Future<String> downloadResume() async {
    return _downloadFile('/resume/download', fallbackFilename: 'resume.pdf');
  }

  Future<String> downloadCertificate(String id, {required String fallbackFilename}) async {
    return _downloadFile('/certificates/$id/download', fallbackFilename: fallbackFilename);
  }

  Future<Uint8List> getCertificateBytes(String id) async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/certificates/$id/download');
    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw ApiException('Unable to preview this certificate.', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<String> _downloadFile(String path, {required String fallbackFilename}) async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final response = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      String message = 'Could not download file (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }

    String filename = fallbackFilename;
    final disposition = response.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }

    return saveAndOpenFile(response.bodyBytes, filename);
  }
}
