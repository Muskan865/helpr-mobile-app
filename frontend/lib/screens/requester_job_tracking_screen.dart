import 'package:flutter/material.dart';
import '/widgets/appbar.dart';
import 'worker_public_profile_screen.dart';
import 'chat_screen.dart';
import 'rating_review_screen.dart';

class RequesterJobTrackingScreen extends StatelessWidget {
  final Map job;
  final int requesterId;

  const RequesterJobTrackingScreen({
    super.key,
    required this.job,
    required this.requesterId,
  });

  final List<String> _steps = const [
    "arriving",
    "arrived",
    "in_progress",
    "completed",
  ];

  final Map<String, String> _labels = const {
    "arriving": "Arriving",
    "arrived": "Arrived",
    "in_progress": "In Progress",
    "completed": "Completed",
  };

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? "arriving";
    final currentIndex = _steps.indexOf(status);
    final date = job['date'] != null ? DateTime.tryParse(job['date']) : null;

    return Scaffold(
      appBar: const CustomAppBar(title: "Track Job"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Job info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['service_type'] ?? "",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job['description'] ?? "",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.location_on, job['location'] ?? "—"),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.calendar_today,
                      date != null
                          ? "${date.day}/${date.month}/${date.year}"
                          : "—",
                    ),
                    if (job['bid_amount'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Rs. ${job['bid_amount']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final jobId = job['job_id'] is int
                              ? job['job_id']
                              : int.tryParse(job['job_id']?.toString() ?? '');
                          if (jobId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  jobId: jobId,
                                  currentUserId: requesterId,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Chat with Worker"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status timeline
              const Text(
                "Status",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Column(
                children: List.generate(_steps.length, (index) {
                  final isCompleted = index <= currentIndex;
                  final isLast = index == _steps.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isCompleted
                                ? Colors.black
                                : Colors.grey.shade300,
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 30,
                              color: index < currentIndex
                                  ? Colors.black
                                  : Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _labels[_steps[index]]!,
                          style: TextStyle(
                            color: isCompleted ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Details section
              const Text(
                "Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "WORKER",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerPublicProfileScreen(
                              workerId: (job['worker_id'] as num).toInt(),
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
                              (job['worker_name'] ?? "?")[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['worker_name'] ?? "—",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${job['worker_rating'] ?? '—'}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Rate button — only shows when completed
              if (status == "completed")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RatingReviewScreen(
                            reviewerId: requesterId,
                            revieweeId: (job['worker_id'] as num).toInt(),
                            workerName: job['worker_name'] ?? "Worker",
                            jobId: (job['job_id'] as num).toInt(),
                            profession: job['profession'] ?? "",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Rate Worker"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
