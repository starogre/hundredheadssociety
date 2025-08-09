import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portrait_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/weekly_session_provider.dart';
import '../models/portrait_model.dart';


class SubmitPortraitDialog extends StatefulWidget {
  const SubmitPortraitDialog({super.key});

  @override
  State<SubmitPortraitDialog> createState() => _SubmitPortraitDialogState();
}

class _SubmitPortraitDialogState extends State<SubmitPortraitDialog> {
  PortraitModel? _selectedPortrait;
  final _artistNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _artistNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
    final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    return AlertDialog(
      title: const Text('Submit Your Painting'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a portrait to submit:'),
            const SizedBox(height: 8),
            StreamBuilder<List<PortraitModel>>(
              stream: portraitProvider.getUserPortraits(userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No portraits found. Add a portrait first.');
                }
                final portraits = snapshot.data!;
                return DropdownButtonFormField<PortraitModel>(
                  value: _selectedPortrait,
                  items: portraits.map((portrait) {
                    return DropdownMenuItem<PortraitModel>(
                      value: portrait,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(portrait.imageUrl),
                            radius: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(portrait.title),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPortrait = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a portrait',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Artist Notes (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _artistNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add any notes about your painting...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedPortrait == null
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                  });
                  try {
                    await weeklySessionProvider.submitPortraitForCurrentSession(
                      userId!,
                      _selectedPortrait!,
                      _artistNotesController.text.trim().isEmpty
                          ? null
                          : _artistNotesController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Submission successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
} 