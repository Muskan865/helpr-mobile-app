import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'post_request_screen.dart';
import 'received_bids_screen.dart';
import 'requester_active_jobs_screen.dart';
import 'requester_job_history_screen.dart';
import 'requester_job_tracking_screen.dart';
import 'requester_open_requests_screen.dart';
import 'chat_list_screen.dart';  
import 'requester_ratings_screen.dart';

class RequesterDashboard extends StatefulWidget {
  final int? userId;

  const RequesterDashboard({super.key, this.userId});

  @override
  State<RequesterDashboard> createState() => _RequesterDashboardState();
}

class _RequesterDashboardState extends State<RequesterDashboard> {
  Map<String, dynamic>? profile;
  List<dynamic> activeJobs = [];
  List<dynamic> receivedBids = [];
  bool isLoading = true;
  String? error;
  late int requesterId;

  @override
  void initState() {
    super.initState();
    requesterId = widget.userId ?? 4;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      profile = await ApiService.getUserProfile(requesterId);
    } catch (e) {
      print("Error fetching requester profile: $e");
    }

    try {
      final jobs = await ApiService.getRequesterActiveJobs(requesterId);
      activeJobs = jobs;
    } catch (e) {
      print("Error fetching active jobs: $e");
    }

    try {
      final bids = await ApiService.getRequesterBids(requesterId);
      receivedBids = bids;
    } catch (e) {
      print("Error fetching bids: $e");
    }

    setState(() => isLoading = false);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final name = profile?['full_name'] ?? "User";
    final initials = name
        .split(" ")
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : "")
        .join()
        .toUpperCase();
    final String? pictureBase64 = profile?['profile_picture'];
    Uint8List? imageBytes;
    if (pictureBase64 != null && pictureBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(pictureBase64);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Blue theme
        elevation: 0.5,
        shadowColor: Colors.blue.shade200,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          "Helpr",
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.white),
                    onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatListScreen(
                          userId: requesterId,
                          isRequester: true,
                        ),
                      ),
                    );
                  },
                ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.amber, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          imageBytes != null ? MemoryImage(imageBytes) : null,
                      child: imageBytes == null
                          ? Text(
                              initials,
                              style: GoogleFonts.nunito(
                                color: Colors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Requester",
                          style: GoogleFonts.nunito(
                              color: Colors.blue.shade100, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              const SizedBox(height: 10),

              _drawerItem(Icons.person_2_outlined, "Profile", onTap: () {
                Navigator.pushNamed(context, '/requesterProfile',
                    arguments: {'userId': requesterId});
              }),
              _drawerItem(Icons.history, "History", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequesterJobHistoryScreen(
                        requesterId: requesterId),
                  ),
                );
              }),
               _drawerItem(Icons.star_outline, "My Ratings", onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequesterRatingsScreen(
                        requesterId: requesterId),
                  ),
                );
              }),
              _drawerItem(Icons.edit_note_outlined, "Post a Request",
                  onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PostRequestScreen(requesterId: requesterId),
                  ),
                ).then((_) => _fetchData());
              }),

              const Spacer(),
              const Divider(height: 1),
              _drawerItem(Icons.logout, "Logout", onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: GoogleFonts.nunito(
                            color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined,
                        color: Color(0xFF1E3A8A), size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PostRequestScreen(requesterId: requesterId),
                        ),
                      ).then((_) => _fetchData());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Received Bids Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceivedBidsScreen(
                          requesterId: requesterId),
                    ),
                  ).then((_) => _fetchData());
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Received bids",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            receivedBids.isEmpty
                                ? "No bids yet"
                                : "Tap to review",
                            style: GoogleFonts.nunito(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        child: Text(
                          "${receivedBids.length}",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Browse Active Requests Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequesterOpenRequestsScreen(
                            requesterId: requesterId),
                      ),
                    ).then((_) => _fetchData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Browse Active Requests",
                    style:
                        GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            //  const SizedBox(height: 20),

              // // Post a Request Button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) =>
              //               PostRequestScreen(requesterId: requesterId),
              //         ),
              //       ).then((_) => _fetchData());
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.black,
              //       foregroundColor: Colors.white,
              //       elevation: 0,
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(12)),
              //     ),
              //     child: Text(
              //       "+ Post a Request",
              //       style:
              //           GoogleFonts.nunito(fontWeight: FontWeight.w600),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 20),

              // ACTIVE JOBS section label
              Text(
                "ACTIVE JOBS",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // Show active jobs inline
              if (activeJobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No active jobs right now.",
                    style: GoogleFonts.nunito(
                        color: Colors.grey, fontSize: 14),
                  ),
                )
              else
                ...activeJobs.map(
                      (job) => _activeJobCard(context, job),
                    ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeJobCard(BuildContext context, Map job) {
    final status = job['status'] ?? "arriving";
    final statusLabels = {
      "arriving": "Arriving",
      "arrived": "Arrived",
      "in_progress": "In Progress",
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequesterJobTrackingScreen(
              job: job,
              requesterId: requesterId,
            ),
          ),
        ).then((_) => _fetchData());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['service_type'] ?? "",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${job['worker_name'] ?? '—'} • ${job['location'] ?? ''}",
                    style: GoogleFonts.nunito(
                        color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabels[status] ?? status,
                style: GoogleFonts.nunito(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _drawerItem(IconData icon, String label,
      {VoidCallback? onTap, bool badge = false}) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.grey.shade700),
          if (badge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      onTap: onTap ?? () {},
    );
  }
}
