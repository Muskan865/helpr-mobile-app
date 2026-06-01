import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import '/widgets/appbar.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map job;
  final int workerId;

  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.workerId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late String currentStatus;

  final List<String> steps = [
    "arriving",
    "arrived",
    "in_progress",
    "completed",
  ];

  final Map<String, String> labels = {
    "arriving": "Arriving",
    "arrived": "Arrived",
    "in_progress": "In Progress",
    "completed": "Completed",
  };

  @override
  void initState() {
    super.initState();
    currentStatus = widget.job['status'] ?? "arriving";
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.job['date'] != null
        ? DateTime.parse(widget.job['date'])
        : null;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Job Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job['service_type'] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(widget.job['description'] ?? ""),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.job['location'] ?? "-"),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        date != null
                            ? "${date.day}/${date.month}/${date.year}"
                            : "-",
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // const Icon(Icons.attach_money, size: 16),
                      // const SizedBox(width: 6),
                      Text("Rs. ${widget.job['bid_amount'] ?? "-"}"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final jobId = widget.job['id'] is int
                            ? widget.job['id']
                            : int.tryParse(widget.job['id']?.toString() ?? '');
                        if (jobId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                jobId: jobId,
                                currentUserId: widget.workerId,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat with Client"),
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

            const Text(
              "Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            buildTimeline(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: currentStatus == "completed" ? null : updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Update Status"),
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  Widget buildTimeline() {
    int currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Circle
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCompleted
                      ? Colors.black
                      : Colors.grey.shade300,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          "${index + 1}",
                          style: const TextStyle(fontSize: 10),
                        ),
                ),

                // Line
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

            // Label
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                labels[steps[index]]!,
                style: TextStyle(
                  color: isCompleted ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void updateStatus() async {
    int currentIndex = steps.indexOf(currentStatus);

    if (currentStatus == "completed") {
      showReviewDialog(widget.workerId, widget.job['client_id']);
      return;
    }

    String nextStatus = steps[currentIndex + 1];
    try {
      final int? jobId = widget.job['id'] is int
          ? widget.job['id']
          : int.tryParse(widget.job['id']?.toString() ?? '');

      if (jobId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to update this job right now.")),
        );
        return;
      }

      await ApiService.updateJobStatus(jobId, nextStatus);

      setState(() {
        currentStatus = nextStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to ${labels[nextStatus]}")),
      );

      if (nextStatus == "completed") {
        showReviewDialog(widget.workerId, widget.job['client_id']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiService.errorMessage(e))));
    }
  }

  void showReviewDialog(int reviewerId, int revieweeId) {
    final reviewController = TextEditingController();
    double rating = 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Rate Client"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Give a rating"),

                  const SizedBox(height: 10),

                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: rating.toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        rating = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      labelText: "Write a review",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.submitReview(
                        reviewerId: reviewerId,
                        revieweeId: revieweeId,
                        rating: rating.toInt(),
                        comment: reviewController.text,
                      );

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Review submitted")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to submit review"),
                        ),
                      );
                    }
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
