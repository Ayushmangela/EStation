import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerCareView extends StatelessWidget {
  const CustomerCareView({super.key});

  Future<void> _launchUrl(Uri url, BuildContext context) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      appBar: AppBar(
        title: Text(
          'Support Center',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "Get in Touch"),
          const SizedBox(height: 12),
          _buildContactOption(
            context,
            icon: Icons.phone_outlined,
            title: "Call Us",
            subtitle: "Speak with a representative",
            color: Colors.blue,
            onTap: () => _launchUrl(Uri.parse('tel:+919969148543'), context),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            context,
            icon: Icons.email_outlined,
            title: "Email Us",
            subtitle: "Get support via email",
            color: Colors.red,
            onTap: () => _launchUrl(Uri.parse('mailto:mheetsingh2005@gmail.com'), context),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            context,
            icon: Icons.chat_bubble_outline,
            title: "Live Chat",
            subtitle: "Chat with a support agent",
            color: Colors.green,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat is not available yet.')),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, "Frequently Asked Questions"),
          const SizedBox(height: 12),
          _buildFaqItem("How do I reset my password?", "You can reset your password from the login screen using the 'Forgot Password?' link. An email will be sent to you with instructions."),
          _buildFaqItem("How do I update my profile?", "Navigate to the 'Profile' tab from the main menu. You will find an 'Edit Profile' option to update your name and other details."),
          _buildFaqItem("How do I view my booking history?", "Your past and upcoming bookings are available in the 'Schedule' tab. You can view details for each booking there."),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.support_agent_rounded,
            color: Colors.green[800],
            size: 60,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We are here to help!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contact us or find answers in the FAQ section below.",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(), // Remove default borders
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        iconColor: Colors.green,
        collapsedIconColor: Colors.grey[700],
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
