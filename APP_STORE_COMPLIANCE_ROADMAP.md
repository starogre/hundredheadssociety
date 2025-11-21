# App Store & Play Store Compliance Roadmap

## Overview
This branch adds critical features required for Apple App Store and Google Play Store approval.

---

## 🎯 Feature 1: Account Deletion (CRITICAL - REQUIRED)

### What Gets Deleted:
1. **Firebase Auth Account** - User's authentication
2. **User Document** (`/users/{userId}`)
3. **All User's Portraits** (`/portraits` where `userId` matches)
   - Portrait documents in Firestore
   - Portrait images in Firebase Storage
4. **All User's Submissions** (`/weekly_sessions/{sessionId}/submissions` where `userId` matches)
5. **All User's Votes** (remove userId from votes arrays in submissions)
6. **All User's Activity Logs** (`/activity_logs` where `userId` matches)
7. **User's FCM Token** (for push notifications)

### What DOESN'T Get Deleted:
- Model documents (if user was a model)
- Weekly session documents (structure remains)
- Other users' data

### Implementation Steps:

#### Step 1.1: Backend Service (`user_service.dart`)
Create `deleteUserAccount()` method that:
1. Fetches all user's portraits
2. Deletes portrait images from Storage
3. Deletes portrait documents from Firestore
4. Deletes user's submissions from all weekly sessions
5. Removes user's votes from all submissions
6. Deletes activity logs
7. Deletes user document
8. Deletes Firebase Auth account
9. Returns success/error

**Error Handling:**
- Wrap in try-catch
- Use batch operations for efficiency
- Log errors to Crashlytics
- Show user-friendly error messages

#### Step 1.2: UI - Settings Screen
Add "Delete Account" button in Settings:
- Location: Bottom of Settings screen
- Style: Red/destructive button
- Icon: Trash/warning icon
- Label: "Delete Account"

#### Step 1.3: Confirmation Dialog
Two-step confirmation:
1. **First Dialog**: Warning message
   - "Are you sure you want to delete your account?"
   - "This will permanently delete:"
   - "• Your profile and all data"
   - "• All {X} portraits you've uploaded"
   - "• All your submissions and votes"
   - "• This action cannot be undone"
   - Buttons: "Cancel" | "Delete Account"

2. **Second Dialog**: Re-authentication (for security)
   - "Please enter your password to confirm"
   - Password field
   - Buttons: "Cancel" | "Confirm Deletion"

#### Step 1.4: Deletion Process
1. Show loading spinner
2. Re-authenticate user
3. Call deleteUserAccount()
4. On success:
   - Sign out user
   - Navigate to login screen
   - Show "Account deleted successfully" message
5. On error:
   - Show error message
   - Keep user signed in
   - Allow retry

#### Step 1.5: Admin Protection
- Prevent admins from deleting their own accounts
- Show warning: "Admin accounts cannot be deleted. Please contact support."
- Alternatively: Require transferring admin rights first

---

## 🎯 Feature 2: Terms of Service / Community Guidelines (REQUIRED)

### Implementation Steps:

#### Step 2.1: Create Terms of Service Screen
New file: `lib/screens/terms_of_service_screen.dart`

**Content to Include:**
1. **Acceptable Use**
   - Only upload your own artwork
   - Respect other artists
   - No harassment or bullying
   - No inappropriate content

2. **Content Guidelines**
   - Portraits must be of consenting models
   - No explicit or offensive content
   - No copyright violations
   - No spam or advertising

3. **Account Responsibilities**
   - Keep your password secure
   - Don't share accounts
   - Accurate information
   - Age requirement (13+ or 18+)

4. **Voting & Submissions**
   - Honest voting only
   - No vote manipulation
   - One account per person
   - Fair play principles

5. **Consequences**
   - Warning system
   - Temporary suspension
   - Permanent ban
   - Content removal

6. **Disclaimer**
   - Service provided "as is"
   - We reserve right to moderate
   - We can update terms
   - Contact info for questions

#### Step 2.2: Add Navigation
- Settings screen → "Terms of Service"
- Sign up screen → Checkbox to agree to terms
- About screen → Link to terms

#### Step 2.3: Firestore Update
Add field to user document:
- `agreedToTermsAt: Timestamp` (when they agreed)
- `termsVersion: String` (e.g., "1.0")

---

## 🎯 Feature 3: Content Reporting System (REQUIRED for UGC)

### What Can Be Reported:
1. **Portraits** - Inappropriate images
2. **Users** - Abusive behavior
3. **Submissions** - Cheating/manipulation

### Implementation Steps:

#### Step 3.1: Report Button UI

**For Portraits:**
- In portrait details dialog
- Location: Menu (3 dots) → "Report"
- Only show if NOT your own portrait

**For Users:**
- In profile screen
- Location: Menu (3 dots) → "Report User"
- Only show if NOT yourself

**For Submissions:**
- In weekly awards submission cards
- Location: Menu (3 dots) → "Report"
- Only show if NOT your own submission

#### Step 3.2: Report Dialog
- Title: "Report [Portrait/User/Submission]"
- Dropdown: Select reason
  - Inappropriate content
  - Spam
  - Harassment
  - Copyright violation
  - Cheating
  - Other
- Text field: Additional details (optional)
- Buttons: "Cancel" | "Submit Report"

#### Step 3.3: Firestore Collection
New collection: `/reports`

Document structure:
```
{
  reportId: string (auto-generated)
  reportType: 'portrait' | 'user' | 'submission'
  reportedItemId: string
  reportedUserId: string
  reporterUserId: string
  reason: string
  details: string (optional)
  status: 'pending' | 'reviewed' | 'resolved' | 'dismissed'
  createdAt: Timestamp
  reviewedAt: Timestamp (optional)
  reviewedBy: string (optional, admin userId)
  resolution: string (optional)
}
```

#### Step 3.4: Report Service
New file: `lib/services/report_service.dart`

Methods:
- `reportPortrait()`
- `reportUser()`
- `reportSubmission()`
- `getReports()` (admin only)
- `updateReportStatus()` (admin only)

#### Step 3.5: Admin Reports Screen
New file: `lib/screens/admin_reports_screen.dart`

Features:
- List all pending reports
- Filter by type/status
- View report details
- Actions:
  - View reported content
  - Delete content
  - Ban user
  - Dismiss report
  - Mark as resolved

#### Step 3.6: Firestore Security Rules
```javascript
match /reports/{reportId} {
  // Users can create reports
  allow create: if request.auth != null 
    && request.resource.data.reporterUserId == request.auth.uid;
  
  // Users can read their own reports
  allow read: if request.auth != null 
    && (resource.data.reporterUserId == request.auth.uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
  
  // Only admins can update/delete
  allow update, delete: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

---

## 🎯 Feature 4: Update Privacy Policy (REQUIRED)

### Additions Needed:

#### Section 1: Data Collection (Update Existing)
Add clarity:
- "We collect photos you upload for portrait tracking"
- "We collect your name and Instagram handle for your profile"
- "We collect email for authentication and communication"
- "We collect voting data to calculate awards"

#### Section 2: Data Usage (Update Existing)
Add clarity:
- "Photos are used to display your portfolio"
- "Name and Instagram are shown to other users"
- "Email is used for account recovery and notifications"
- "Voting data is used for community awards"

#### Section 3: Data Sharing (NEW)
Add:
- "We do NOT sell your data to third parties"
- "We use Firebase (Google) for hosting and authentication"
- "Your photos and profile are visible to other app users"
- "Admins can view content for moderation purposes"

#### Section 4: Account Deletion (NEW - CRITICAL)
Add:
```markdown
## How to Delete Your Account and Data

You can request deletion of your account and all associated data at any time.

### In-App Deletion:
1. Open the app and go to Settings
2. Scroll to the bottom and tap "Delete Account"
3. Confirm your decision
4. Enter your password to verify
5. Your account and all data will be permanently deleted

### What Gets Deleted:
- Your user profile (name, email, Instagram, profile picture)
- All portraits you've uploaded (images and data)
- All your submissions to weekly awards
- All your votes on other submissions
- Your account authentication credentials

### Email Request:
If you cannot access the app, you can email us at:
support@100headsociety.com

Subject: "Account Deletion Request"

We will delete your account and all data within 30 days of your request.

### Important Notes:
- Account deletion is permanent and cannot be undone
- You will lose access to your portrait history
- Any awards you've earned will be removed
- This does not affect physical session attendance records
```

#### Section 5: User Rights (NEW)
Add:
- Right to access your data
- Right to delete your data
- Right to correct your data
- Right to export your data (optional, nice to have)

#### Section 6: Children's Privacy (NEW - if allowing 13+)
Add:
- "Our app is not intended for children under 13"
- OR "Users ages 13-17 must have parental consent"
- "We do not knowingly collect data from children under 13"

#### Section 7: Contact Information (Update)
Make sure it's clear:
- Email: support@100headsociety.com
- Website: https://100headsociety.com
- Response time: "We respond within 48 hours"

---

## 🎯 Feature 5: Data Export (OPTIONAL - Nice to Have)

### Implementation:
Allow users to download all their data in JSON format:
- Profile info
- List of all portrait URLs
- Voting history
- Submission history

### UI:
- Settings → "Download My Data"
- Generates a JSON file
- Downloads to device

---

## 📋 Implementation Order

### Phase 1: Critical Features (Do First)
1. ✅ Account Deletion backend service
2. ✅ Account Deletion UI (Settings button)
3. ✅ Confirmation dialogs with re-auth
4. ✅ Terms of Service screen
5. ✅ Update Privacy Policy (add deletion section)

### Phase 2: Content Safety (Do Second)
6. ✅ Report button for portraits
7. ✅ Report button for users
8. ✅ Report button for submissions
9. ✅ Report dialog UI
10. ✅ Report service & Firestore collection
11. ✅ Admin reports screen

### Phase 3: Polish (Do Third)
12. ✅ Add Terms link to signup
13. ✅ Add Terms checkbox requirement
14. ✅ Update Firestore security rules
15. ✅ Test all features thoroughly

---

## 🧪 Testing Checklist

### Account Deletion Testing:
- [ ] Regular user can delete account
- [ ] All portraits are deleted
- [ ] User can't sign in after deletion
- [ ] Email is freed up for new account
- [ ] Admin accounts can't be deleted (or require special flow)
- [ ] Error handling works (network issues, etc.)

### Reporting Testing:
- [ ] Can report portraits
- [ ] Can report users
- [ ] Can report submissions
- [ ] Can't report own content
- [ ] Reports appear in admin panel
- [ ] Admins can resolve reports

### Privacy Policy:
- [ ] All sections are accurate
- [ ] Account deletion instructions are clear
- [ ] Contact info is correct
- [ ] Link works from app

### Terms of Service:
- [ ] Content is clear and fair
- [ ] Accessible from multiple places
- [ ] Users agree during signup

---

## 📱 App Store Connect Preparation

After implementing these features:

### Update App Screenshots:
- Include Settings screen showing "Delete Account"
- Show Terms of Service is accessible

### Update App Description:
- Mention content moderation
- Mention user safety features

### App Review Notes:
```
Privacy & Safety Features:

1. Account Deletion:
   Users can delete their accounts at any time via Settings → Delete Account.
   All user data (profile, portraits, votes, submissions) is permanently deleted.

2. Content Reporting:
   Users can report inappropriate content or users via the report button.
   Admins review all reports and take appropriate action.

3. Terms of Service:
   Users must agree to community guidelines during signup.
   Guidelines outline acceptable use and consequences.

4. Data Privacy:
   Full privacy policy available at: https://100headsociety.com/privacy
   Users can request data deletion at any time.

Test Account:
Email: reviewer@100headssociety.com
Password: [provide secure password]

This account has sample data for testing all features.
```

---

## ⏱️ Estimated Timeline

- **Account Deletion**: 2-3 hours
- **Terms of Service**: 1 hour
- **Privacy Policy Update**: 30 minutes
- **Content Reporting**: 3-4 hours
- **Admin Reports Screen**: 2 hours
- **Testing**: 1-2 hours
- **Documentation**: 30 minutes

**Total: 10-13 hours of work**

---

## 🚀 After Completion

1. Commit all changes
2. Merge to master
3. Build new version (1.0.8 build 14 or 1.0.9 build 15)
4. Upload to TestFlight
5. Upload to Google Play
6. Test with beta testers
7. Submit for review on both platforms
8. Monitor for feedback

---

## 📞 Support After Launch

Set up:
- support@100headsociety.com email
- Monitor inbox daily
- Respond to deletion requests within 24-48 hours
- Track reports in admin panel
- Regular moderation schedule

---

Ready to implement? We'll go feature by feature, starting with Account Deletion.

