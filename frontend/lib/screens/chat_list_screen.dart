import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final int userId;
  final bool isRequester;

  const ChatListScreen({
    super.key,
    required this.userId,
    required this.isRequester,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    try {
      if (widget.isRequester) {
        jobs = await ApiService.getRequesterJobs(widget.userId);
      } else {
        final all = await ApiService.getWorkerJobs(widget.userId);
        jobs = all
            .where((j) => (j['status'] ?? '').toString().toLowerCase() != 'completed')
            .toList();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.errorMessage(e))),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Messages",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? Center(
                  child: Text(
                    "No active jobs with chat",
                    style: GoogleFonts.nunito(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final dynamic jobIdRaw = job['job_id'] ?? job['id'];
                    final int? jobId = jobIdRaw is int
                        ? jobIdRaw
                        : int.tryParse(jobIdRaw?.toString() ?? '');

                    final String title = widget.isRequester
                        ? "${job['worker_name'] ?? 'Worker'}"
                        : "${job['client_name'] ?? 'Client'}";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.work_outline,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        job['location'] ?? "",
                        style: GoogleFonts.nunito(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (jobId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Chat is not available for this job yet."),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              jobId: jobId,
                              currentUserId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}