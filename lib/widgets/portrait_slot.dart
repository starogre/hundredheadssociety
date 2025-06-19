import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/portrait_model.dart';

class PortraitSlot extends StatelessWidget {
  final int weekNumber;
  final PortraitModel? portrait;
  final bool isCompleted;
  final VoidCallback onTap;

  const PortraitSlot({
    super.key,
    required this.weekNumber,
    this.portrait,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.blue.shade200 : Colors.grey.shade400,
            width: 1,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Portrait image or placeholder
            if (isCompleted && portrait != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: portrait!.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.error,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.add_a_photo,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),

            // Week number overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.blue.shade600 : Colors.grey.shade600,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Text(
                  '$weekNumber',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Completion indicator
            if (isCompleted)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 