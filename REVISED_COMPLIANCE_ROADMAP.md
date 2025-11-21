# Revised App Store & Play Store Compliance Roadmap

Based on feedback and existing features.

---

## ✅ What You Already Have:
- Privacy Policy screen ✅
- Terms of Service screen ✅
- Basic content guidelines ✅

## ❌ What You Need to Add/Update:
1. Account deletion feature
2. Update Privacy Policy (add deletion instructions)
3. Content reporting system
4. Update Terms of Service (add reporting section)

---

## 🎯 Feature 1: Account Deletion (CRITICAL - 2-3 hours)

### What Gets Deleted When User Deletes Account:

#### Immediate Deletion:
1. **Firebase Auth Account** - Can't sign in anymore
2. **User Document** (`/users/{userId}`)
3. **All User's Portraits**:
   - Portrait documents in Firestore
   - Portrait images in Firebase Storage
4. **All User's Submissions** (`/weekly_sessions/{sessionId}/submissions`)
5. **All User's Votes**:
   - Remove userId from votes arrays in submissions
   - **ONLY for ongoing/future sessions**
   - **DO NOT touch past sessions where awards were already calculated**
6. **Activity Logs** (if any)

#### Awards Handling (Your Decision):
**Option chosen: Remove awards where user won**

When a user deletes their account:
- ❌ Don't show "Deleted User" in awards
- ✅ Remove the award entry entirely
- **Reason**: The portrait is gone, so the award makes no sense

Example:
```
Before deletion:
"Best Likeness" - Jane Doe (portrait #42)

After Jane deletes account:
"Best Likeness" - No winner (portrait deleted)
OR just remove this category win entirely
```

**Implementation**: When deleting submissions, also remove any award entries in past sessions where this user/portrait won.

#### What DOESN'T Get Deleted:
- Other users' data
- Weekly session structure
- Model documents
- **Past votes/awards that are already finalized** (unless user was the winner)

---

### Implementation Steps:

#### Step 1.1: Backend Service - Delete Method
File: `lib/services/user_service.dart`

Add method: `Future<void> deleteUserAccount(String userId)`

**Detailed logic:**
```dart
1. Get all user's portraits
2. Delete each portrait image from Storage
3. Delete each portrait document from Firestore
4. Get all weekly sessions
5. For each session:
   a. Delete user's submissions
   b. Remove user's votes from other submissions
   c. If session has winners and user won, remove that win
6. Delete activity logs (if collection exists)
7. Delete user document
8. Delete Firebase Auth account
9. Sign out user
```

**Error handling:**
- Wrap in try-catch
- Use batched writes for efficiency
- If any step fails, log to Crashlytics
- Return error to UI for user-friendly message

#### Step 1.2: Settings Screen UI
File: `lib/screens/settings_screen.dart`

Add at the bottom (before closing widgets):
```dart
// Danger Zone
const Divider(height: 40),
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: Text(
    'Danger Zone',
    style: TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
),
const SizedBox(height: 8),
ListTile(
  leading: PhosphorIcon(
    PhosphorIconsDuotone.warning,
    color: Colors.red,
  ),
  title: const Text(
    'Delete Account',
    style: TextStyle(color: Colors.red),
  ),
  subtitle: const Text(
    'Permanently delete your account and all data',
  ),
  onTap: () => _showDeleteAccountDialog(context),
),
```

#### Step 1.3: Confirmation Dialogs

**First Dialog - Warning:**
```dart
_showDeleteAccountDialog(BuildContext context) {
  // Get portrait count for display
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This will permanently delete:'),
          SizedBox(height: 12),
          Text('• Your profile and all data'),
          Text('• All ${portraitCount} portraits you\'ve uploaded'),
          Text('• All your submissions and votes'),
          Text('• Any awards you\'ve earned'),
          SizedBox(height: 12),
          Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showPasswordConfirmation(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete Account'),
        ),
      ],
    ),
  );
}
```

**Second Dialog - Re-authentication:**
```dart
_showPasswordConfirmation(BuildContext context) {
  final passwordController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Please enter your password to confirm:'),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Re-authenticate
            // Call delete method
            // Show loading
            // Sign out and go to login
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Confirm'),
        ),
      ],
    ),
  );
}
```

#### Step 1.4: Admin Protection
```dart
// In _showDeleteAccountDialog, check if user is admin:
if (currentUser.isAdmin) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cannot Delete Admin Account'),
      content: Text(
        'Admin accounts cannot be deleted through the app. '
        'Please contact support if you need to delete your admin account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
  return;
}
```

---

## 🎯 Feature 2: Update Privacy Policy (CRITICAL - 30 min)

File: `lib/screens/privacy_policy_screen.dart`

### Changes Needed:

#### 1. Update "Last updated" date
```dart
'Last updated: November 21, 2024'
```

#### 2. Update "Information We Collect" section
**Remove:** "RSVP and session participation data"
**Change to:** "Session participation and voting data"

#### 3. Add NEW section: "Account Deletion"
Add after "Data Security" section:

```dart
const SizedBox(height: 16),
const Text(
  'Account Deletion',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 8),
const Text(
  'You can delete your account and all associated data at any time.\n\n'
  'In-App Deletion:\n'
  '1. Open Settings\n'
  '2. Scroll to bottom and tap "Delete Account"\n'
  '3. Confirm your decision\n'
  '4. Enter your password to verify\n\n'
  'What Gets Deleted:\n'
  '• Your profile (name, email, Instagram, profile picture)\n'
  '• All portraits you\'ve uploaded\n'
  '• All your submissions and votes\n'
  '• Any awards you\'ve earned\n'
  '• Your authentication credentials\n\n'
  'Email Request:\n'
  'If you cannot access the app, email us at:\n'
  'support@100headsociety.com\n'
  'Subject: "Account Deletion Request"\n\n'
  'We will process your request within 30 days.\n\n'
  'Important: Account deletion is permanent and cannot be undone.',
  style: TextStyle(fontSize: 16),
),
```

#### 4. Update "Contact Us" section
```dart
const Text(
  'If you have any questions about this Privacy Policy or wish to '
  'request account deletion, please contact us at:\n\n'
  'Email: support@100headsociety.com\n'
  'Website: https://100headsociety.com\n\n'
  'We respond to all inquiries within 48 hours.',
  style: TextStyle(fontSize: 16),
),
```

---

## 🎯 Feature 3: Update Terms of Service (20 min)

File: `lib/screens/terms_of_service_screen.dart`

### Changes Needed:

#### 1. Update "Last updated" date
```dart
'Last updated: November 21, 2024'
```

#### 2. Update "Content Guidelines" section
Expand to be more specific:

```dart
const Text(
  'Content Guidelines',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 8),
const Text(
  '• All portrait submissions must be original artwork\n'
  '• Portraits must be of consenting models from our sessions\n'
  '• No explicit, offensive, or inappropriate content\n'
  '• No harassment, bullying, or hate speech\n'
  '• No spam, advertising, or commercial content\n'
  '• No copyright violations or stolen artwork\n'
  '• You retain ownership but grant us license to display it\n'
  '• We reserve the right to remove content that violates these terms',
  style: TextStyle(fontSize: 16),
),
```

#### 3. Add NEW section: "Content Reporting"
Add after "Prohibited Activities":

```dart
const SizedBox(height: 16),
const Text(
  'Content Reporting & Moderation',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 8),
const Text(
  '• Users can report inappropriate content or behavior\n'
  '• All reports are reviewed by moderators\n'
  '• False or malicious reports may result in penalties\n'
  '• We investigate all reports promptly and fairly\n'
  '• Actions may include warnings, content removal, or account suspension',
  style: TextStyle(fontSize: 16),
),
```

#### 4. Update "Termination" section
Make it clearer about suspension vs deletion:

```dart
const Text(
  'Termination & Suspension',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 8),
const Text(
  'Account Suspension:\n'
  'We may temporarily suspend accounts for violations. '
  'Suspended users cannot access the app but may request account deletion.\n\n'
  'Account Deletion:\n'
  'You may delete your account at any time through Settings. '
  'We may also permanently delete accounts for serious or repeated violations.\n\n'
  'Appeals:\n'
  'Contact support@100headsociety.com to appeal suspensions or deletions.',
  style: TextStyle(fontSize: 16),
),
```

---

## 🎯 Feature 4: Content Reporting System (5-6 hours)

### User Suspension vs Deletion - Clarified:

#### **Account Suspension (Ban)**:
- User violated rules
- **Cannot sign in** to app
- **Data remains** in database (for evidence/moderation/appeals)
- User **can still request deletion** via email: support@100headsociety.com
- Firestore field: `isSuspended: true`, `suspendedAt: Timestamp`, `suspensionReason: string`

#### **Account Deletion**:
- User choice OR admin action
- **All data removed** permanently
- Cannot be undone
- User cannot sign in (account doesn't exist)

#### **Why Suspend Instead of Delete?**:
1. **Evidence**: Keep data for legal/moderation records
2. **Appeals**: User can appeal suspension, explain situation
3. **Temporary**: Some violations warrant temporary punishment, not permanent ban
4. **Repeated offenders**: Track history of violations

#### **Banned User Deleting Account**:
If a banned user wants to delete their account:
1. They email: support@100headsociety.com
2. Admin manually deletes their account
3. OR: Implement a "Delete My Suspended Account" button on sign-in page

**Recommendation**: Add a banner on login screen for suspended users:
```
"Your account is suspended.
Reason: [reason]
To delete your account, email support@100headsociety.com"
```

---

### Implementation Steps:

#### Step 4.1: Firestore Collection
Create: `/reports` collection

Document structure:
```javascript
{
  reportId: auto-generated
  reportType: 'portrait' | 'user' | 'submission'
  reportedItemId: string (portraitId / userId / submissionId)
  reportedUserId: string (user who owns the content)
  reportedUserName: string (for display)
  reporterUserId: string (user who reported)
  reporterName: string (for display)
  reason: string (dropdown selection)
  details: string (optional text)
  status: 'pending' | 'reviewing' | 'resolved' | 'dismissed'
  createdAt: Timestamp
  reviewedAt: Timestamp (optional)
  reviewedBy: string (optional, admin userId)
  resolution: string (optional, admin notes)
  actionTaken: 'none' | 'warning' | 'content_removed' | 'user_suspended' | 'user_deleted'
}
```

#### Step 4.2: Report Service
New file: `lib/services/report_service.dart`

Methods:
```dart
Future<void> reportPortrait({
  required String portraitId,
  required String reportedUserId,
  required String reason,
  String? details,
})

Future<void> reportUser({
  required String reportedUserId,
  required String reason,
  String? details,
})

Future<void> reportSubmission({
  required String sessionId,
  required String submissionId,
  required String reportedUserId,
  required String reason,
  String? details,
})

// Admin only
Future<List<Map>> getPendingReports()
Future<void> resolveReport({
  required String reportId,
  required String resolution,
  required String actionTaken,
})
```

#### Step 4.3: Report Dialog Widget
New file: `lib/widgets/report_dialog.dart`

```dart
class ReportDialog extends StatefulWidget {
  final String reportType; // 'portrait', 'user', 'submission'
  final String itemId;
  final String reportedUserId;
  
  // ... implementation
}
```

Dropdown reasons:
- Inappropriate content
- Spam
- Harassment or bullying
- Copyright violation
- Cheating / Vote manipulation
- Other (requires details)

#### Step 4.4: Add Report Buttons

**In Portrait Details Dialog:**
`lib/widgets/portrait_details_dialog.dart`

Add menu button (3 dots) in AppBar:
```dart
actions: [
  // Only show if NOT your own portrait
  if (portrait.userId != currentUserId)
    PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.red),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
          onTap: () => _showReportDialog(context),
        ),
      ],
    ),
  // ... existing close button
]
```

**In Profile Screen:**
`lib/screens/profile_screen.dart`

Add menu button in AppBar when viewing other users:
```dart
actions: [
  if (widget.userId != currentUserId)
    PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.red),
              SizedBox(width: 8),
              Text('Report User'),
            ],
          ),
          onTap: () => _showReportUserDialog(context),
        ),
      ],
    ),
]
```

**In Weekly Awards Submissions:**
`lib/screens/weekly_sessions_screen.dart`

Add report button to submission cards (if not your own):
```dart
// In submission card
if (submission.userId != currentUserId)
  IconButton(
    icon: Icon(Icons.flag_outlined, size: 20),
    color: Colors.grey,
    onPressed: () => _showReportDialog(context, submission),
  ),
```

#### Step 4.5: Admin Reports Screen
New file: `lib/screens/admin_reports_screen.dart`

Features:
- List all reports (filter by status)
- Tap to view details
- Actions:
  - View reported content/user
  - Delete content
  - Suspend user
  - Dismiss report
  - Add notes

Add to Settings screen (admin only):
```dart
if (currentUser.isAdmin)
  ListTile(
    leading: PhosphorIcon(PhosphorIconsDuotone.flag),
    title: const Text('Content Reports'),
    subtitle: const Text('Review reported content'),
    trailing: Badge showing pending count,
    onTap: () => Navigator.push(...AdminReportsScreen),
  ),
```

#### Step 4.6: User Suspension Feature

**Update user_service.dart:**
```dart
Future<void> suspendUser({
  required String userId,
  required String reason,
  Duration? duration, // null = permanent
}) async {
  await _firestore.collection('users').doc(userId).update({
    'isSuspended': true,
    'suspendedAt': FieldValue.serverTimestamp(),
    'suspensionReason': reason,
    if (duration != null)
      'suspensionEndsAt': Timestamp.fromDate(
        DateTime.now().add(duration),
      ),
  });
}

Future<void> unsuspendUser(String userId) async {
  await _firestore.collection('users').doc(userId).update({
    'isSuspended': false,
    'suspensionReason': FieldValue.delete(),
    'suspendedAt': FieldValue.delete(),
    'suspensionEndsAt': FieldValue.delete(),
  });
}
```

**Update auth_provider.dart:**
Check suspension status on login:
```dart
if (userDoc.data()?['isSuspended'] == true) {
  final reason = userDoc.data()?['suspensionReason'] ?? 'Violation of terms';
  
  // Show dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Account Suspended'),
      content: Text(
        'Your account has been suspended.\n\n'
        'Reason: $reason\n\n'
        'To appeal or delete your account, '
        'email: support@100headsociety.com',
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Sign out
            // Close dialog
            // Go to login
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
  
  // Sign out user
  await _authService.signOut();
  return;
}
```

#### Step 4.7: Firestore Security Rules
Update `firestore.rules`:

```javascript
match /reports/{reportId} {
  // Users can create reports
  allow create: if request.auth != null 
    && request.resource.data.reporterUserId == request.auth.uid
    && request.resource.data.status == 'pending';
  
  // Users can read their own reports
  allow read: if request.auth != null 
    && (resource.data.reporterUserId == request.auth.uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isModerator == true);
  
  // Only admins/mods can update
  allow update: if request.auth != null 
    && (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isModerator == true);
  
  // Only admins can delete
  allow delete: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

---

## 📋 Revised Implementation Order

### Phase 1: Account Deletion (Do First - Most Critical)
**Time: 2-3 hours**

1. ✅ Add `deleteUserAccount()` method to `user_service.dart`
2. ✅ Add "Delete Account" button to Settings
3. ✅ Create warning dialog
4. ✅ Create re-authentication dialog
5. ✅ Add admin protection
6. ✅ Test thoroughly

**Test checklist:**
- [ ] Regular user can delete account
- [ ] All portraits deleted from Storage
- [ ] All portraits deleted from Firestore
- [ ] Submissions removed
- [ ] Votes removed from ongoing sessions
- [ ] Awards removed where user won
- [ ] Can't sign in after deletion
- [ ] Admin accounts protected

---

### Phase 2: Privacy Policy Update (Do Second - Required for Submission)
**Time: 30 minutes**

1. ✅ Update "Last updated" date
2. ✅ Remove "RSVP" reference
3. ✅ Add "Account Deletion" section
4. ✅ Update "Contact Us" section

---

### Phase 3: Terms of Service Update (Do Third - Good to Have)
**Time: 20 minutes**

1. ✅ Update "Last updated" date
2. ✅ Expand "Content Guidelines"
3. ✅ Add "Content Reporting & Moderation" section
4. ✅ Update "Termination" section

**At this point, you can submit to App Store!**

---

### Phase 4: Content Reporting (Do Fourth - Highly Recommended)
**Time: 5-6 hours**

1. ✅ Create `/reports` Firestore collection
2. ✅ Create `report_service.dart`
3. ✅ Create `report_dialog.dart` widget
4. ✅ Add report buttons to portraits
5. ✅ Add report buttons to users
6. ✅ Add report buttons to submissions
7. ✅ Create `admin_reports_screen.dart`
8. ✅ Add suspension logic
9. ✅ Update Firestore security rules
10. ✅ Test reporting flow

**Test checklist:**
- [ ] Can report portraits (not your own)
- [ ] Can report users (not yourself)
- [ ] Can report submissions (not your own)
- [ ] Reports appear in admin panel
- [ ] Admins can resolve reports
- [ ] Suspension logic works
- [ ] Suspended users see message on login

---

## ⏱️ Revised Timeline

- **Phase 1**: 2-3 hours (Account Deletion)
- **Phase 2**: 30 minutes (Privacy Policy)
- **Phase 3**: 20 minutes (Terms of Service)
- **Phase 4**: 5-6 hours (Content Reporting)

**Total Minimum (Phases 1-3):** ~3.5-4 hours ← Can submit after this!
**Total Complete (Phases 1-4):** ~8.5-10 hours ← Ideal for approval

---

## 🚀 After Phase 3 Completion (Minimum for Submission):

1. Test account deletion thoroughly
2. Build version 1.0.9 (15)
3. Upload to TestFlight
4. Test with 1-2 people
5. **Submit to Apple App Store** ✅
6. Upload to Google Play
7. Wait for reviews

**With just account deletion + privacy updates, you should pass review!**

---

## 🎯 After Phase 4 Completion (Ideal):

1. Test reporting system
2. Test suspension system
3. Build version 1.0.9 (15) or 1.1.0 (16)
4. Upload to both stores
5. Submit with confidence
6. **Much higher approval chance!** 🎉

---

## 📞 Post-Launch Support Email

Set up: **support@100headsociety.com**

**Must respond to:**
- Account deletion requests (from suspended users)
- Ban appeals
- Content reports (if user can't access app)
- Privacy questions

**Response time:** Within 24-48 hours (Apple/Google expect this)

---

Ready to start with Phase 1: Account Deletion?

