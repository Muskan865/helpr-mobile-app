import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '/widgets/appbar.dart';
import 'worker_public_profile_screen.dart';
import 'post_request_screen.dart';

class RequesterJobHistoryScreen extends StatefulWidget {
  final int requesterId;

  const RequesterJobHistoryScreen({super.key, required this.requesterId});

  @override
  State<RequesterJobHistoryScreen> createState() =>
      _RequesterJobHistoryScreenState();
}

class _RequesterJobHistoryScreenState
    extends State<RequesterJobHistoryScreen> {
  List<dynamic> pastJobs = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final result =
          await ApiService.getRequesterJobHistory(widget.requesterId);
      setState(() {
        pastJobs = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load job history";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Job History"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Job History",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              // Flexible(
                              //   child: ElevatedButton.icon(
                              //     onPressed: () {
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (_) => PostRequestScreen(
                              //             requesterId: widget.requesterId,
                              //           ),
                              //         ),
                              //       );
                              //     },
                              //     icon: const Icon(Icons.add, size: 16),
                              //     label: const Text("Create Request"),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.black,
                              //       foregroundColor: Colors.white,
                              //       shape: RoundedRectangleBorder(
                              //           borderRadius:
                              //               BorderRadius.circular(20)),
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 14, vertical: 8),
                              //       textStyle:
                              //           const TextStyle(fontSize: 13),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (pastJobs.isEmpty)
                            const Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  "No completed jobs yet.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ...pastJobs.map((job) => _jobCard(job)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _jobCard(Map job) {
    final date = job['date'] != null
        ? DateTime.tryParse(job['date']?.toString() ?? '')
        : null;

    final workerIdValue = job['worker_id'];
    final workerId = workerIdValue != null
        ? (workerIdValue is int ? workerIdValue : int.tryParse(workerIdValue.toString()))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job['service_type']?.toString() ?? "",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(job['location']?.toString() ?? "—",
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  date != null
                      ? "${date.day}/${date.month}/${date.year} • ${job['time']?.toString() ?? ''}"
                      : "—",
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Worker row
          if (workerId != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerPublicProfileScreen(
                      workerId: workerId,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (job['worker_name']?.toString() ?? "?").isNotEmpty
                          ? job['worker_name'].toString()[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['worker_name']?.toString() ?? "—",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        Text(
                          job['profession']?.toString() ?? "",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        "${job['worker_rating']?.toString() ?? '—'}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios,
                      size: 13, color: Colors.grey),
                ],
              ),
            ),

          if (job['my_rating'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) {
                              final rating = job['my_rating'] is num ? (job['my_rating'] as num).toInt() : int.tryParse(job['my_rating'].toString()) ?? 0;
                              return Icon(
                                i < rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            },
                          ),
                        ),
                        if (job['my_comment'] != null &&
                            job['my_comment'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            job['my_comment'].toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
