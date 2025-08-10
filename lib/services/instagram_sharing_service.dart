import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class InstagramSharingService {
  static final ScreenshotController _screenshotController = ScreenshotController();

  /// Share a portrait to Instagram with custom story template
  static Future<void> sharePortraitToInstagram({
    required PortraitModel portrait,
    required UserModel artist,
    List<String>? awards,
    String? artistInstagram,
  }) async {
    try {
      // Create the story template
      final Uint8List? imageBytes = await _createStoryTemplate(
        portrait: portrait,
        artist: artist,
        awards: awards,
        artistInstagram: artistInstagram,
      );

      if (imageBytes != null) {
        // Save the image temporarily
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/100heads_story_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Share to Instagram
        await Share.shareXFiles(
          [XFile(filePath)],
          text: _generateCaption(portrait, artist, awards, artistInstagram),
          subject: 'Check out this amazing portrait from 100 Heads Society!',
        );
      }
    } catch (e) {
      debugPrint('Error sharing to Instagram: $e');
      rethrow;
    }
  }

  /// Create a custom story template with app branding
  static Future<Uint8List?> _createStoryTemplate({
    required PortraitModel portrait,
    required UserModel artist,
    List<String>? awards,
    String? artistInstagram,
  }) async {
    try {
      final Widget storyWidget = _buildStoryWidget(
        portrait: portrait,
        artist: artist,
        awards: awards,
        artistInstagram: artistInstagram,
      );

             return await _screenshotController.captureFromWidget(
         storyWidget,
         delay: const Duration(milliseconds: 500), // Increased delay for image loading
         pixelRatio: 3.0, // High quality for Instagram
         context: null,
       );
    } catch (e) {
      debugPrint('Error creating story template: $e');
      return null;
    }
  }

  /// Build the story widget with custom design
  static Widget _buildStoryWidget({
    required PortraitModel portrait,
    required UserModel artist,
    List<String>? awards,
    String? artistInstagram,
  }) {
    return Container(
      width: 1080, // Instagram story dimensions (9:16 ratio)
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cream,
            AppColors.forestGreen.withValues(alpha: 0.1),
            AppColors.rustyOrange.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                // Header with logo and branding
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Portrait image
                Expanded(
                  child: _buildPortraitSection(portrait),
                ),
                
                const SizedBox(height: 40),
                
                // Artist info and awards
                _buildArtistSection(artist, awards, artistInstagram),
                
                const SizedBox(height: 40),
                
                // Footer with hashtags
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the header section with app branding
  static Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
             child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           // App logo
           Container(
             width: 60,
             height: 60,
             decoration: BoxDecoration(
               color: AppColors.forestGreen,
               borderRadius: BorderRadius.circular(15),
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(15),
               child: Image.asset(
                 'assets/splash_logo.gif',
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) {
                   return const Center(
                     child: Text(
                       '100',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   );
                 },
               ),
             ),
           ),
           const SizedBox(height: 10),
           Text(
             '100 Heads Society',
             style: const TextStyle(
               fontSize: 20,
               fontWeight: FontWeight.bold,
               color: AppColors.forestGreen,
             ),
             textAlign: TextAlign.center,
           ),
           Text(
             'Portrait Art Community',
             style: const TextStyle(
               fontSize: 12,
               color: AppColors.rustyOrange,
               fontWeight: FontWeight.w500,
             ),
             textAlign: TextAlign.center,
           ),
         ],
       ),
    );
  }

  /// Build the portrait section
  static Widget _buildPortraitSection(PortraitModel portrait) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          portrait.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.error,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the artist section with awards
  static Widget _buildArtistSection(
    UserModel artist,
    List<String>? awards,
    String? artistInstagram,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Artist name and Instagram
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.palette,
                    color: AppColors.forestGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      artist.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (artistInstagram != null) ...[
                const SizedBox(height: 5),
                Text(
                  '@${artistInstagram.replaceAll('@', '')}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.rustyOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          
          if (awards != null && awards.isNotEmpty) ...[
            const SizedBox(height: 15),
            // Awards section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.rustyOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.rustyOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppColors.rustyOrange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Awards Won',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.rustyOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                                       children: awards.map((award) {
                     // Get emoji for award category
                     String emoji = '🏆';
                     switch (award.toLowerCase()) {
                       case 'likeness':
                         emoji = '👤';
                         break;
                       case 'style':
                         emoji = '🎨';
                         break;
                       case 'fun':
                         emoji = '😄';
                         break;
                       case 'tophead':
                         emoji = '👑';
                         break;
                     }
                     
                     return Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: AppColors.rustyOrange,
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Text(
                         '$emoji $award',
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     );
                   }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the footer with hashtags
  static Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.forestGreen.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '#100HeadsSociety #PortraitArt #ArtCommunity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '@100headsociety',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate caption for sharing
  static String _generateCaption(
    PortraitModel portrait,
    UserModel artist,
    List<String>? awards,
    String? artistInstagram,
  ) {
    final StringBuffer caption = StringBuffer();
    
    caption.write('🎨 Amazing portrait by ${artist.name}');
    
    if (artistInstagram != null) {
      caption.write(' (@${artistInstagram.replaceAll('@', '')})');
    }
    
    if (awards != null && awards.isNotEmpty) {
      caption.write('\n🏆 Awards: ${awards.join(', ')}');
    }
    
    caption.write('\n\n#100HeadsSociety #PortraitArt #ArtCommunity @100headsociety');
    
    return caption.toString();
  }
}

/// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.forestGreen.withValues(alpha: 0.05)
      ..strokeWidth = 2;

    // Draw subtle pattern
    for (int i = 0; i < size.width; i += 100) {
      for (int j = 0; j < size.height; j += 100) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
