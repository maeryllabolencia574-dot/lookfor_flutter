import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';


class AboutAppScreen extends StatelessWidget {
  Future<void> _openUrl(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}
  const AboutAppScreen({super.key});
/*Widget _buildback({
    required IconData icon,
    required String text,
    IconData? trailingIcon,
    Color? trailingColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          
          child: Row(
            children: [
              Icon(icon, size: 30, color: const Color(0xFF005BAB)),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              if (trailingIcon != null)
                Icon(trailingIcon,
                    color: trailingColor ?? Colors.grey),
            ],
          ),
        ),
      ),
    );
  }*/
  Widget _buildOption({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: const Color(0xFF005BAB)),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              const Icon(Icons.arrow_forward_ios, color: Colors.grey)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About the App'),
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
           /* _buildback(
              icon: Icons.arrow_back,
              text: "Back",
              //trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),*/
            const SizedBox(height: 20),
            
            // 🔹 Title
            const Text(
              "ABOUT THE APP",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Look",
                  style: GoogleFonts.greatVibes(
                    fontSize: 60,
                    color: const Color(0xFF005BAB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "For",
                  style: GoogleFonts.greatVibes(
                    fontSize: 60,
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 🔹 Options list
            _buildOption(
              icon: Icons.auto_awesome,
              text: "Version",
              onTap: () {
                Navigator.pushNamed(context, '/version');
              },
            ),

            _buildOption(
              icon: Icons.shield_outlined,
              text: "Security Features",
              onTap: () {
                _openUrl("https://www.lookforlostandfound.com/c/a26e5a70-842d-5491-9b8c-b61a8ca8b966");
              },
            ),

            _buildOption(
              icon: Icons.help_outline,
              text: "FAQs",
              onTap: () {
                //open website
                _openUrl("https://www.lookforlostandfound.com/c/faq");
              },
            ),

            _buildOption(
              icon: Icons.article_outlined,
              text: "Terms & Conditions",
              onTap: () {
                _openUrl("https://www.lookforlostandfound.com/c/terms");
              },
            ),

            _buildOption(
              icon: Icons.lock_outline,
              text: "Data Privacy Policy",
              onTap: () {
                _openUrl("https://www.lookforlostandfound.com/c/privacy");
              },
            ),

            const Spacer(),

           
          ],
        ),
      ),

    );
  }
}
