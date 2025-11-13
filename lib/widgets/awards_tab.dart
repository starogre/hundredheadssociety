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
      debugPrint('=== STARTING AWARDS CALCULATION FOR USER: ${widget.userId} ===');
      
      // First, try to get cached counts from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final userData = userDoc.data();
      final cachedTrophies = userData?['portraitAwardCount'] as int? ?? 0;
      final cachedCommunityExp = userData?['totalVotesCast'] as int? ?? 0;
      final lastUpdate = userData?['awardsLastCalculated'] as Timestamp?;
      
      // Use cached data if it's less than 5 minutes old
      if (lastUpdate != null) {
        final age = DateTime.now().difference(lastUpdate.toDate());
        if (age.inMinutes < 5) {
          debugPrint('Using cached awards - Age: ${age.inMinutes} minutes');
          if (mounted) {
            setState(() {
              _trophyCount = cachedTrophies;
              _communityExp = cachedCommunityExp;
            });
          }
          debugPrint('Awards loaded from cache - Trophies: $cachedTrophies, Community Exp: $cachedCommunityExp');
          return; // Skip recalculation
        }
      }
      
      debugPrint('Cache miss or stale - Recalculating awards');
      
      // Count trophies by checking weekly sessions (awards are stored there)
      // We need to get all weekly sessions and count how many times this user's portraits won
      int totalTrophies = 0;
      
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('weekly_sessions')
          .get();
      
      debugPrint('Found ${sessionsSnapshot.docs.length} sessions to check for awards');
      
      for (var sessionDoc in sessionsSnapshot.docs) {
        try {
          final sessionData = sessionDoc.data();
          final submissions = sessionData['submissions'];
          
          if (submissions == null) continue;
          
          final submissionsList = List<Map<String, dynamic>>.from(submissions);
          
          // Check each submission to see if it belongs to this user and won awards
          for (var submission in submissionsList) {
            final submissionUserId = submission['userId'] as String?;
            
            if (submissionUserId == widget.userId) {
              // This submission belongs to our user - count their awards
              final votes = submission['votes'];
              if (votes != null) {
                final votesMap = Map<String, dynamic>.from(votes);
                
                // Check each category (likeness, style, fun, topHead)
                for (var category in ['likeness', 'style', 'fun', 'topHead']) {
                  final categoryVotes = votesMap[category];
                  if (categoryVotes != null) {
                    final votesList = List<String>.from(categoryVotes);
                    if (votesList.isNotEmpty) {
                      // Check if this submission won this category
                      int maxVotes = 0;
                      for (var otherSubmission in submissionsList) {
                        final otherVotes = otherSubmission['votes'];
                        if (otherVotes != null) {
                          final otherCategoryVotes = Map<String, dynamic>.from(otherVotes)[category];
                          if (otherCategoryVotes != null) {
                            final otherVotesList = List<String>.from(otherCategoryVotes);
                            if (otherVotesList.length > maxVotes) {
                              maxVotes = otherVotesList.length;
                            }
                          }
                        }
                      }
                      
                      // If this submission has the most votes, it won!
                      if (votesList.length == maxVotes && maxVotes > 0) {
                        totalTrophies++;
                        debugPrint('Found award for user in session ${sessionDoc.id}, category: $category');
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing session ${sessionDoc.id} for awards: $e');
        }
      }
      
      debugPrint('Total trophies counted: $totalTrophies');
      
      // Count community exp (voting activity) - reuse the sessions we already loaded
      debugPrint('Counting community exp from same ${sessionsSnapshot.docs.length} sessions');
      
      int communityExp = 0;
      for (var sessionDoc in sessionsSnapshot.docs) {
        try {
          final sessionData = sessionDoc.data();
          final submissions = sessionData['submissions'];
          
          if (submissions == null) {
            debugPrint('Session ${sessionDoc.id}: No submissions');
            continue;
          }
          
          final submissionsList = List<Map<String, dynamic>>.from(submissions);
          debugPrint('Session ${sessionDoc.id}: ${submissionsList.length} submissions');
          
          for (var submission in submissionsList) {
            final submissionUserId = submission['userId'] as String?;
            final votesData = submission['votes'];
            
            if (votesData == null) {
              continue;
            }
            
            // Skip if this is the user's own submission (can't get community exp from voting for yourself)
            if (submissionUserId == widget.userId) {
              continue;
            }
            
            // Handle both Map<String, dynamic> and Map<String, List> formats
            final votes = Map<String, dynamic>.from(votesData);
            
            // Count how many times this user voted in this submission
            for (var categoryVotes in votes.values) {
              try {
                final voterList = List<String>.from(categoryVotes);
                if (voterList.contains(widget.userId)) {
                  communityExp += 1;
                  debugPrint('Found vote by user in session ${sessionDoc.id}');
                }
              } catch (e) {
                debugPrint('Error parsing votes: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing session ${sessionDoc.id}: $e');
        }
      }
      
      debugPrint('Total community exp: $communityExp');
      debugPrint('=== AWARDS CALCULATION COMPLETE ===');
      
      // Update UI
      if (mounted) {
        setState(() {
          _trophyCount = totalTrophies;
          _communityExp = communityExp;
        });
      }
      
      // Save calculated values to user document for future caching
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'portraitAwardCount': totalTrophies,
          'totalVotesCast': communityExp,
          'awardsLastCalculated': FieldValue.serverTimestamp(),
        });
        debugPrint('Cached awards saved to user document');
      } catch (e) {
        debugPrint('Error saving awards cache: $e');
        // Don't fail if cache save fails
      }
      
      debugPrint('Awards loaded - Trophies: $totalTrophies, Community Exp: $communityExp');
    } catch (e, stackTrace) {
      debugPrint('Error loading awards data: $e');
      debugPrint('Stack trace: $stackTrace');
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
          PhosphorIcon(icon, color: color, size: 32),
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
                      PhosphorIconsRegular.plus,
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
                      PhosphorIcon(_getMerchIcon(item), size: 16, color: AppColors.forestGreen),
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
                            PhosphorIconsRegular.x,
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