
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerCareView extends StatefulWidget {
  const CustomerCareView({super.key});

  @override
  State<CustomerCareView> createState() => _CustomerCareViewState();
}

class _CustomerCareViewState extends State<CustomerCareView> {
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Care'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildContactSection(),
          const SizedBox(height: 24),
          _buildFaqSection(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contact Us",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactTile(
              icon: Icons.phone,
              title: "Call Us",
              subtitle: "Speak with a representative",
              onTap: () {
                _launchUrl(Uri.parse('tel:+919969148543'));
              },
            ),
            const Divider(),
            _buildContactTile(
              icon: Icons.email,
              title: "Email Us",
              subtitle: "Get support via email",
              onTap: () {
                _launchUrl(Uri.parse('mailto:mheetsingh2005@gmail.com'));
              },
            ),
            const Divider(),
            _buildContactTile(
              icon: Icons.chat_bubble,
              title: "Live Chat",
              subtitle: "Chat with a support agent",
              onTap: () {
                // Handle chat functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Frequently Asked Questions",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFaqItem("How do I reset my password?", "You can reset your password from the login screen..."),
            const Divider(),
            _buildFaqItem("How do I update my profile?", "You can update your profile from the profile screen..."),
            const Divider(),
            _buildFaqItem("How do I view my booking history?", "You can view your booking history from the bookings screen..."),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
