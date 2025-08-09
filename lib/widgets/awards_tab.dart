import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/award_service.dart';
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
      // For now, we'll use a placeholder approach since we need to get all portraits first
      // In a real implementation, we'd need to get all user portraits and then check awards for each
      if (mounted) {
        setState(() {
          _trophyCount = 0; // Placeholder - would need to implement proper counting
          // Community exp is based on voting activity (placeholder for now)
          _communityExp = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading awards data: $e');
    }
  }

  Future<void> _loadUserMerchItems() async {
    try {
      // This would typically fetch from user's merch items in Firestore
      // For now, we'll use a placeholder
      if (mounted) {
        setState(() {
          _userMerchItems = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading merch items: $e');
    }
  }

  Future<void> _addMerchItem(String item) async {
    try {
      // This would typically add to user's merch items in Firestore
      setState(() {
        _userMerchItems.add(item);
      });
    } catch (e) {
      debugPrint('Error adding merch item: $e');
    }
  }

  Future<void> _removeMerchItem(String item) async {
    try {
      // This would typically remove from user's merch items in Firestore
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
            Icons.emoji_events,
            AppColors.rustyOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Community Exp',
            _communityExp.toString(),
            Icons.star,
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
                    child: const Icon(
                      Icons.add,
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
                          child: const Icon(
                            Icons.close,
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
        return Icons.checkroom;
      case 'tator tot pin':
      case 'hydra pin':
        return Icons.push_pin;
      default:
        return Icons.shopping_bag;
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