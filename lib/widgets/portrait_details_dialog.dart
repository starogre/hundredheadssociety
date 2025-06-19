import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class PortraitDetailsDialog extends StatelessWidget {
  final PortraitModel portrait;
  final UserModel? user;

  const PortraitDetailsDialog({
    super.key,
    required this.portrait,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              image: DecorationImage(
                image: CachedNetworkImageProvider(portrait.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  portrait.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (portrait.description != null && portrait.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    portrait.description!,
                    style: TextStyle(
                      color: AppColors.forestGreen.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.forestGreen,
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user?.name ?? 'Anonymous',
                        style: TextStyle(
                          color: AppColors.forestGreen.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Week \\${portrait.weekNumber}',
                      style: TextStyle(
                        color: AppColors.rustyOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 