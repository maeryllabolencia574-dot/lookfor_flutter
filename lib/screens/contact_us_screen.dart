import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsScreen extends StatelessWidget {
  Future<void> _openUrl(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}

  const ContactUsScreen({super.key});
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

              if (trailingIcon != null)
                Icon(trailingIcon,
                    color: trailingColor ?? Colors.grey),
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
        title: const Text('Contact Us'),
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            
            /*
            _buildback(
              icon: Icons.arrow_back,
              text: "Back",
              //trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/more');
              },
            ),*/
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

            // 🔹 Options
            _buildOption(
              icon: Icons.chat_bubble,
              text: "Send Us a Message",
              trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                // lookfor web
                _openUrl("https://www.lookforlostandfound.com/c/a26e5a70-842d-5491-9b8c-b61a8ca8b966");
              },
            ),

            _buildOption(
              icon: Icons.help_outline,
              text: "Go to Help Support",
              trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                // lookfor web
                _openUrl("https://www.lookforlostandfound.com/c/a26e5a70-842d-5491-9b8c-b61a8ca8b966");
              },
            ),

            _buildOption(
              icon: Icons.phone,
              text: "Call Hotline",
              trailingIcon: Icons.call,
              trailingColor: Colors.green,
              onTap: () {
                // TODO: call function
                _openUrl("tel:+639274686576");
              },
            ),

            _buildOption(
              icon: Icons.location_on,
              text: "Visit the Office",
              trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                //lookfor web
                _openUrl("https://www.lookforlostandfound.com/c/a26e5a70-842d-5491-9b8c-b61a8ca8b966");
              },
            ),

            const SizedBox(height: 20),

            

            const Spacer(),

            // 🔹 Bottom Navigation Style
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, color: Colors.grey),
                        SizedBox(height: 4),
                        Text("Login"),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/more');
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Icon(Icons.more_horiz, color: Color(0xFF005BAB)),
                        SizedBox(height: 4),
                      Text("More"),
                    ],
                  ),
              )],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
