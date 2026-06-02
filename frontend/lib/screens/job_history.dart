import 'package:flutter/material.dart';
import 'package:helpr/widgets/appbar.dart';

class BrowsePastJobs extends StatefulWidget {
  final List<dynamic> pastJobs;

  const BrowsePastJobs({super.key, required this.pastJobs});

  @override
  State<BrowsePastJobs> createState() => _BrowsePastJobsState();
}

class _BrowsePastJobsState extends State<BrowsePastJobs> {
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Job History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (widget.pastJobs.isEmpty)
              const Text("No nearby requests")
            else
              ...widget.pastJobs.map(
                (job) => requestCard(
                  job['service_type'] ?? "",
                  job['description'] ?? "",
                  "${job['location'] ?? "-"}",
                  _formatDate(job['date']),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "-";
    final dateString = rawDate.toString();

    try {
      final date = DateTime.parse(dateString);
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Widget requestCard(
     String title,
     String description,
     String location,
     String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 6),
              Text(location),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text(date),
            ],
          ),
          const SizedBox(height: 6),

        ],
      ),
    );
  }
}
