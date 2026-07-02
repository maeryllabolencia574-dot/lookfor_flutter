import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  Widget _buildback({
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
  }
 /* Widget _buildOption({
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
  }*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        
        child: Column(
          
          children: [
             /*_buildback(
              icon: Icons.arrow_back,
              text: "",
              //trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),*/
            const SizedBox(height: 20),
            
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
            const SizedBox(height: 25),

            // 🔹 Menu Items
            _menuItem(
              icon: Icons.call,
              text: "Contact Us",
              onTap: () {
                Navigator.pushNamed(context, '/contact');
              },
            ),
            _menuItem(
              icon: Icons.chat_bubble,
              text: "Let\u2019s Chat",
              onTap: () {
                Navigator.pushNamed(context, '/lets-chat');
              },
            ),
            _menuItem(
              icon: Icons.info,
              text: "About the App",
              onTap: () {
                 Navigator.pushNamed(context, '/about');
              },
            ),

            const SizedBox(height: 30),

            

            const SizedBox(height: 25),

            // 🔹 Terms Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text.rich(
                TextSpan(
                  text: "By using this service, you agree to the ",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  children: [
                    
                    TextSpan(
                      text: "Terms and Conditions",
                      style: const TextStyle(
                        color: Color(0xFF005BAB),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, '/terms');
                        },
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // 🔹 Bottom Navigation
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
                  GestureDetector(
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
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, color:Color(0xFF005BAB)),
                      SizedBox(height: 4),
                      Text("More"),
                      
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable Menu Item
  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        child: ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(text),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
