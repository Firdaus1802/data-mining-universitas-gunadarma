import 'package:flutter/material.dart';

class OnbordingContent extends StatelessWidget {
  const OnbordingContent({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.isActive,
    this.customWidget,
  });

  final String title, description, image;
  final bool isActive;
  final Widget? customWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column( 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          if (customWidget != null)
            SizedBox(
              height: 220,
              child: Center(child: customWidget!),
            )
          else if (image.contains('gunadarma'))
            Image.asset(
              image,
              height: 220,
              fit: BoxFit.contain,
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: image.endsWith('.jpg')
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(image.endsWith('.jpg') ? 20 : 0),
                child: Image.asset(
                  image,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const Spacer(flex: 1),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2D35),
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Plus Jakarta",
                fontSize: 14,
                color: Color(0xFF6E6E7A),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
