import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/user_model.dart';
import '../services/award_service.dart';
import '../services/portrait_service.dart';
import '../theme/app_theme.dart';

class AwardsTab extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const AwardsTab({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  State<AwardsTab> createState() => _AwardsTabState();
}

class _AwardsTabState extends State<AwardsTab> {
  final AwardService _awardService = AwardService();
  
  int _trophyCount = 0;
  int _communityExp = 0;
  List<String> _userMerchItems = [];
  bool _isLoading = true;

  final List<String> _availableMerchItems = [
    'T-Shirt',
    'Tator tot pin',
    'Hydra pin',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadAwardsData(),
        _loadUserMerchItems(),
      ]);
    } catch (e) {
      debugPrint('Error loading awards data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAwardsData() async {
    try {
      // Get user data to read stored award count
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final portraitAwardCount = userData['portraitAwardCount'] ?? 0;
        
        // Count community exp (voting activity) - get all weekly sessions
        final sessionsSnapshot = await FirebaseFirestore.instance
            .collection('weekly_sessions')
            .get();
        
        int communityExp = 0;
        for (var sessionDoc in sessionsSnapshot.docs) {
          final sessionData = sessionDoc.data();
          final submissions = List<Map<String, dynamic>>.from(sessionData['submissions'] ?? []);
          
          for (var submission in submissions) {
            final votes = Map<String, List<String>>.from(submission['votes'] ?? {});
            
            // Count community exp (voting activity)
            for (var categoryVotes in votes.values) {
              if (categoryVotes.contains(widget.userId)) {
                communityExp += 1; // +1 exp per vote
              }
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _trophyCount = portraitAwardCount;
            _communityExp = communityExp;
          });
        }
        
        debugPrint('Awards loaded - Trophies: $portraitAwardCount, Community Exp: $communityExp');
      }
    } catch (e) {
      debugPrint('Error loading awards data: $e');
    }
  }

  Future<void> _loadUserMerchItems() async {
    try {
      // Fetch user's merch items from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final merchItems = List<String>.from(userData['merchItems'] ?? []);
        
        if (mounted) {
          setState(() {
            _userMerchItems = merchItems;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading merch items: $e');
    }
  }

  Future<void> _addMerchItem(String item) async {
    try {
      // Add to user's merch items in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'merchItems': FieldValue.arrayUnion([item]),
      });
      
      setState(() {
        _userMerchItems.add(item);
      });
    } catch (e) {
      debugPrint('Error adding merch item: $e');
    }
  }

  Future<void> _removeMerchItem(String item) async {
    try {
      // Remove from user's merch items in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'merchItems': FieldValue.arrayRemove([item]),
      });
      
      setState(() {
        _userMerchItems.remove(item);
      });
    } catch (e) {
      debugPrint('Error removing merch item: $e');
    }
  }

  void _showAddMerchDialog() {
    String? selectedItem;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Merch'),
        content: DropdownButtonFormField<String>(
          value: selectedItem,
          decoration: const InputDecoration(
            labelText: 'Select Merch Item',
            border: OutlineInputBorder(),
          ),
          items: _availableMerchItems
              .where((item) => !_userMerchItems.contains(item))
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: (value) {
            selectedItem = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedItem != null) {
                _addMerchItem(selectedItem!);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Portrait Trophies',
            _trophyCount.toString(),
            PhosphorIconsDuotone.trophy,
            AppColors.rustyOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Community Exp',
            _communityExp.toString(),
            PhosphorIconsDuotone.star,
            AppColors.forestGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.forestGreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserMerchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rustyOrange),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Merch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
              if (widget.isOwnProfile)
                GestureDetector(
                  onTap: _showAddMerchDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsDuotone.plus,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_userMerchItems.isEmpty)
            const Text(
              'No merch items yet',
              style: TextStyle(
                color: AppColors.forestGreen,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userMerchItems.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.forestGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getMerchIcon(item), size: 16, color: AppColors.forestGreen),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.isOwnProfile) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeMerchItem(item),
                          child: PhosphorIcon(
                            PhosphorIconsDuotone.x,
                            size: 16,
                            color: AppColors.rustyOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  IconData _getMerchIcon(String item) {
    switch (item.toLowerCase()) {
      case 't-shirt':
        return PhosphorIconsDuotone.tShirt;
      case 'tator tot pin':
      case 'hydra pin':
        return PhosphorIconsDuotone.pushPin;
      default:
        return PhosphorIconsDuotone.shoppingBag;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        _buildSummaryCards(),
        const SizedBox(height: 24),

        // User's Merch Items
        _buildUserMerchSection(),
        const SizedBox(height: 24),
      ],
    );
  }
} 