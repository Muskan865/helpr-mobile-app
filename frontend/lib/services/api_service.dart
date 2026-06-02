import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String baseUrl = "https://helpr-mobile-app.onrender.com";

  static String get apiBase => "$baseUrl/api";

  static String errorMessage(
    Object error, {
    String fallback = "Something went wrong. Please try again.",
  }) {
    final raw = error.toString().replaceFirst("Exception: ", "").trim();
    if (raw.isEmpty) return fallback;

    final lower = raw.toLowerCase();
    if (lower.contains("failed to fetch") ||
        lower.contains("failed host lookup") ||
        lower.contains("connection refused") ||
        lower.contains("socketexception") ||
        lower.contains("clientexception")) {
      return "Can't connect to server. Please make sure backend is running.";
    }

    final parsed = _decodePossibleErrorPayload(raw);
    if (parsed != null && parsed.isNotEmpty) {
      return parsed;
    }

    return raw;
  }

  static String _messageFromResponse(http.Response response, String fallback) {
    final parsed = _decodePossibleErrorPayload(response.body);
    if (parsed != null && parsed.isNotEmpty) {
      return parsed;
    }
    return fallback;
  }

  static String? _decodePossibleErrorPayload(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    Map<String, dynamic>? payload;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    if (payload == null) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final decoded = jsonDecode(trimmed.substring(start, end + 1));
          if (decoded is Map<String, dynamic>) payload = decoded;
        } catch (_) {}
      }
    }

    if (payload != null) {
      final message = payload['message']?.toString().trim();
      final error = payload['error']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
      if (error != null && error.isNotEmpty) return error;
    }

    return null;
  }

  // ---------------- AUTH ----------------
  static Future<Map<String, dynamic>> login(
    String contact,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contact_number": contact,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(response, "Unable to log in. Please try again."),
      );
    }
  }

  static Future<Map<String, dynamic>> signup(
    String name,
    String contactNumber,
    String email,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": name,
        "contact_number": contactNumber,
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(response, "Unable to sign up right now."),
      );
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/check-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["exists"] == true;
    } else {
      throw ApiException(
        _messageFromResponse(response, "Unable to verify email right now."),
      );
    }
  }

  static Future<Map<String, dynamic>> requestPasswordReset(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/request-password-reset"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(response, "Unable to request OTP right now."),
      );
    }
  }

  static Future<Map<String, dynamic>> confirmPasswordReset(
    String email,
    String otpCode,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/confirm-password-reset"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp_code": otpCode,
        "password": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(response, "Unable to reset password right now."),
      );
    }
  }

  // ---------------- WORKER DASHBOARD ----------------

  static Future<List<dynamic>> getWorkerJobs(int workerId) async {
    final res = await http.get(
      Uri.parse("$apiBase/worker/$workerId/jobs"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load jobs right now.");
    }
  }

  static Future<List<dynamic>> getWorkerBids(int workerId) async {
    final res = await http.get(
      Uri.parse("$apiBase/worker/$workerId/bids"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load bids right now.");
    }
  }

  static Future<Map<String, dynamic>> getWorkerProfile(int workerId) async {
    final res = await http.get(
      Uri.parse("$apiBase/worker/$workerId/profile"),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load profile right now.");
    }
  }

  static Future<List<dynamic>> getAllRequests() async {
    final response = await http.get(Uri.parse("$apiBase/worker/requests"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw const ApiException("Couldn't load requests right now.");
    }
  }

  static Future<List<dynamic>> getMatchingRequests(int workerId) async {
    final res = await http.get(
      Uri.parse("$apiBase/worker/$workerId/matching-requests"),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load matching requests right now.");
    }
  }

  static Future<void> placeBid({
    required int requestId,
    required int workerId,
    required int amount,
    required String todaydate,
    required String todaytime,
  }) async {
    final response = await http.post(
      Uri.parse("$apiBase/worker/$workerId/place-bid"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "request_id": requestId,
        "bid_amount": amount,
        "bid_date": todaydate,
        "bid_time": todaytime,
        "status": "pending",
      }),
    );

    if (response.statusCode != 200) {
      print("Bid error body: ${response.body}"); // Add this
      throw ApiException(
        _messageFromResponse(response, "Couldn't place your bid right now."),
      );
    }
  }

  // ---------------- WORKER PROFILE CREATION ----------------

  static Future<Map<String, dynamic>> createWorkerProfile(
    int userId,
    String profession,
    String skills,
    int experience,
  ) async {
    final res = await http.post(
      Uri.parse("$apiBase/worker/profile"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "profession": profession,
        "skills": skills,
        "experience_years": experience,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ApiException(
        _messageFromResponse(
          res,
          "Couldn't save worker profile details right now.",
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> updateWorkerDetails(
    int userId,
    String profession,
    String skills,
    int experience,
  ) async {
    final res = await http.put(
      Uri.parse("$apiBase/profile/worker/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "profession": profession,
        "skills": skills,
        "experience_years": experience,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ApiException(
        _messageFromResponse(
          res,
          "Couldn't update worker details right now.",
        ),
      );
    }
  }

  // ---------------- PROFILE COMPLETION ----------------

  static Future<Map<String, dynamic>> completeWorkerProfile(
    int userId,
    String profession,
    String skills,
    int experienceYears,
    XFile? profilePicture,
  ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$apiBase/profile-completion/worker"),
    );

    request.fields["userId"] = userId.toString();
    request.fields["profession"] = profession;
    request.fields["skills"] = skills;
    request.fields["experience_years"] = experienceYears.toString();

    if (profilePicture != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "profile_picture",
          await profilePicture.readAsBytes(),
          filename: profilePicture.name,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(
          response,
          "Couldn't complete worker profile right now.",
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> completeRequesterProfile(
    int userId,
    XFile? profilePicture,
  ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$apiBase/profile-completion/requester"),
    );

    request.fields["userId"] = userId.toString();

    if (profilePicture != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "profile_picture",
          await profilePicture.readAsBytes(),
          filename: profilePicture.name,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        _messageFromResponse(
          response,
          "Couldn't complete requester profile right now.",
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final res = await http.get(
      Uri.parse("$apiBase/profile/user/$userId"),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load user profile right now.");
    }
  }

  static Future<void> submitReview({
  required int reviewerId,
  required int revieweeId,
  required int rating,
  required String comment,
}) async {
  final response = await http.post(
    Uri.parse("$apiBase/worker/review"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "reviewer_id": reviewerId,
      "reviewee_id": revieweeId,
      "rating": rating,
      "comment": comment,
    }),
  );

  if (response.statusCode != 200) {
    throw ApiException(
      _messageFromResponse(response, "Couldn't submit review right now."),
    );
  }
}

static Future<void> cancelBid(int bidId) async {
    final response = await http.delete(Uri.parse("$apiBase/worker/bid/$bidId"));

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(response, "Couldn't cancel bid right now."),
      );
    }
  }

  static Future<void> updateJobStatus(int jobId, String status) async {
    final response = await http.put(
      Uri.parse("$apiBase/worker/job/$jobId/status"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(response, "Couldn't update job status right now."),
      );
    }
  }
  // Get Requester ongoing jobs (for chat list)
static Future<List<dynamic>> getRequesterJobs(int requesterId) async {
  final response = await http.get(
    Uri.parse("$apiBase/requester/$requesterId/jobs"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw ApiException(
      _messageFromResponse(response, "Couldn't load your chats right now."),
    );
  }
}
  static Future<List<dynamic>> getWorkerRatings(int workerId) async {
  final response = await http.get(
    Uri.parse("$apiBase/worker/$workerId/ratings"),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw ApiException(
      _messageFromResponse(response, "Couldn't load ratings right now."),
    );
  }
}

// ---------------- REQUESTER: SERVICE REQUESTS ----------------
 
  static Future<void> postServiceRequest({
    required int requesterId,
    required String serviceType,
    required String description,
    required String date,
    required String time,
    required String location,
  }) async {
    final res = await http.post(
      Uri.parse("$apiBase/requester/request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requester_id": requesterId,
        "service_type": serviceType,
        "description": description,
        "date": date,
        "time": time,
        "location": location,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(res, "Couldn't post your request right now."),
      );
    }
  }
 
  static Future<List<dynamic>> getAllOpenRequests() async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/requests/open"),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getRequesterOpenRequests(int requesterId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/$requesterId/requests/open"),
    );
    return jsonDecode(res.body);
  }
 
  // ---------------- REQUESTER: BIDS ----------------
 
  static Future<List<dynamic>> getRequesterBids(int requesterId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/$requesterId/bids"),
    );
    return jsonDecode(res.body);
  }
 
  static Future<void> acceptBid(int bidId) async {
    final res = await http.put(
      Uri.parse("$apiBase/requester/bid/$bidId/accept"),
      headers: {"Content-Type": "application/json"},
    );
    if (res.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(res, "Couldn't accept bid right now."),
      );
    }
  }
 
  // ---------------- REQUESTER: JOBS ----------------
 
  static Future<List<dynamic>> getRequesterActiveJobs(
      int requesterId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/$requesterId/active-jobs"),
    );
    return jsonDecode(res.body);
  }
 
  static Future<List<dynamic>> getRequesterJobHistory(
      int requesterId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/$requesterId/job-history"),
    );
    return jsonDecode(res.body);
  }
 
  // ---------------- REQUESTER: WORKER PUBLIC PROFILE ----------------
 
  static Future<Map<String, dynamic>> getWorkerPublicProfile(
      int workerId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/worker/$workerId/profile"),
    );
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    } else {
      throw const ApiException("Couldn't load worker profile right now.");
    }
  }
 
  // ---------------- REQUESTER: RATINGS ----------------
 
  static Future<void> submitRating({
    required int reviewerId,
    required int revieweeId,
    required double rating,
    required String comment,
    required int jobId,
  }) async {
    final res = await http.post(
      Uri.parse("$apiBase/requester/rating"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "reviewer_id": reviewerId,
        "reviewee_id": revieweeId,
        "rating": rating,
        "comment": comment,
        "job_id": jobId,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(res, "Couldn't submit rating right now."),
      );
    }
  }
 
  static Future<List<dynamic>> getRequesterRatings(
      int requesterId) async {
    final res = await http.get(
      Uri.parse("$apiBase/requester/$requesterId/ratings"),
    );
    return jsonDecode(res.body);
  }

  static bool isAllowedProfileImage(XFile file) {
  final ext = file.name.split('.').last.toLowerCase();
  return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
}

}
