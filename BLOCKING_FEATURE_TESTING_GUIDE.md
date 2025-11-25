# 🧪 User Blocking Feature - Testing Guide

## **Prerequisites Before Testing**

1. ✅ Deploy Firestore security rules (see `FIRESTORE_RULES_BLOCKS.md`)
2. ✅ Build and install the app on test device
3. ✅ Have 2 test accounts ready:
   - **Test User A** (the blocker)
   - **Test User B** (the blocked user)

---

## **Test Scenario 1: Block a User**

### **Steps:**
1. Sign in as **Test User A**
2. Navigate to Community tab or Weekly Awards
3. Find a portrait/submission by **Test User B**
4. Tap on **Test User B's** name to open their profile
5. Tap the **flag icon** in the AppBar
6. Verify dialog shows:
   - ✅ "Block [User B]" button (red)
   - ✅ "Report [User B]" button (outlined)
   - ✅ "Cancel" button
7. Tap **"Block [User B]"**
8. Verify confirmation dialog appears:
   - ✅ Title: "Block [User B]?"
   - ✅ Message explains consequences
   - ✅ "Cancel" and "Block" buttons
9. Tap **"Block"**
10. Verify:
    - ✅ SnackBar: "[User B] has been blocked"
    - ✅ Profile screen pops back
    
### **Expected Result:**
✅ User B is now blocked by User A

---

## **Test Scenario 2: View Blocked User's Profile**

### **Steps (Continue as Test User A):**
1. Navigate back to **Test User B's** profile
2. Verify:
   - ✅ Flag icon still shows in AppBar
   - ✅ Block status message displays:
     - Icon: User with minus sign (duotone)
     - Title: "You've blocked [User B]"
     - Description: "You won't see their portraits and they won't see yours"
   - ✅ **No tabs visible** (Portraits/Awards tabs hidden)
   - ✅ **No portraits displayed**
   - ✅ Only profile header, stats, and block message visible

3. Tap the **flag icon** again
4. Verify dialog now shows:
   - ✅ "Unblock [User B]" button (green)
   - ✅ No "Report" button (hidden when blocked)
   - ✅ "Cancel" button

### **Expected Result:**
✅ Blocked user's profile shows block status, no content visible

---

## **Test Scenario 3: Verify Blocked User is Hidden in All Screens**

### **Steps (Continue as Test User A):**

#### **A. Community Screen:**
1. Navigate to **Community** tab
2. Scroll through portraits
3. Verify:
   - ✅ **Test User B's** portraits are **not visible**
   - ✅ Other users' portraits still show normally

#### **B. Weekly Awards - Submissions Tab:**
1. Navigate to **Weekly Awards** → **Submissions**
2. Scroll through submissions
3. Verify:
   - ✅ **Test User B's** submissions are **not visible**
   - ✅ Other users' submissions still show normally
   - ✅ Can still vote on other submissions

#### **C. Weekly Awards - Awards Tab:**
1. Navigate to **Weekly Awards** → **Awards** (when winners are announced)
2. Check award categories
3. Verify:
   - ✅ **Test User B** does not appear in any award categories
   - ✅ If Test User B was the only winner in a category, that category is hidden
   - ✅ Other users' awards still display normally

#### **D. Search/Discovery:**
1. Try to find **Test User B** in Community
2. Try to navigate to their profile via direct link (if possible)
3. Verify:
   - ✅ Cannot see their content anywhere
   - ✅ Profile shows block message if accessed directly

### **Expected Result:**
✅ Blocked user is completely hidden from all content screens

---

## **Test Scenario 4: View from Blocked User's Perspective**

### **Steps:**
1. Sign out of **Test User A**
2. Sign in as **Test User B**
3. Navigate to **Test User A's** profile
4. Verify:
   - ✅ Block status message displays:
     - Icon: User with minus sign (duotone)
     - Title: "[User A] has blocked you"
     - Description: "You cannot view their portraits or interact with their content"
   - ✅ **No tabs visible**
   - ✅ **No portraits displayed**
   - ✅ Flag icon is **hidden** (User B cannot report User A while blocked)

5. Navigate to **Community** tab
6. Verify:
   - ✅ **Test User A's** portraits are **not visible**

7. Navigate to **Weekly Awards**
8. Verify:
   - ✅ **Test User A's** submissions are **not visible**
   - ✅ **Test User A** does not appear in awards

### **Expected Result:**
✅ Blocked user cannot see blocker's content anywhere

---

## **Test Scenario 5: Unblock a User**

### **Steps:**
1. Sign out of **Test User B**
2. Sign in as **Test User A**
3. Navigate to **Test User B's** profile
4. Tap the **flag icon**
5. Verify dialog shows:
   - ✅ "Unblock [User B]" button (green)
   - ✅ "Cancel" button
6. Tap **"Unblock [User B]"**
7. Verify:
   - ✅ SnackBar: "[User B] has been unblocked"
   - ✅ Profile screen pops back

8. Navigate back to **Test User B's** profile
9. Verify:
   - ✅ **No block message**
   - ✅ **Tabs are visible** (Portraits/Awards)
   - ✅ **Portraits are displayed**
   - ✅ Flag icon shows "Block or Report" options again

10. Navigate to **Community** tab
11. Verify:
    - ✅ **Test User B's** portraits are **now visible**

12. Navigate to **Weekly Awards**
13. Verify:
    - ✅ **Test User B's** submissions/awards are **now visible**

### **Expected Result:**
✅ Unblocking restores all content visibility

---

## **Test Scenario 6: Block and Report**

### **Steps (as Test User A):**
1. Navigate to a different user's profile (**Test User C**)
2. Tap the **flag icon**
3. Tap **"Report [User C]"** (don't block)
4. Select a reason: "Inappropriate content"
5. Add details: "Test report"
6. Tap **"Submit Report"**
7. Verify:
   - ✅ SnackBar: "Report submitted successfully"
   - ✅ Dialog closes
   - ✅ User C is **NOT blocked** (only reported)
   - ✅ User C's content still visible

8. Now tap the **flag icon** again
9. Tap **"Block [User C]"**
10. Confirm blocking
11. Verify:
    - ✅ User C is now blocked
    - ✅ Previous report still exists (check admin reports screen if admin)
    - ✅ User C's content now hidden

### **Expected Result:**
✅ Block and report are independent actions

---

## **Test Scenario 7: Firestore Security Validation**

### **Steps (Firebase Console):**
1. Go to **Firestore Database** in Firebase Console
2. Navigate to `blocks` collection
3. Verify document structure:
   - ✅ Document ID: `testUserA_testUserB`
   - ✅ Field `blockedBy`: `testUserA`
   - ✅ Field `blockedUser`: `testUserB`
   - ✅ Field `createdAt`: (timestamp)
   - ✅ **Only 3-4 fields** (no extra data)

4. Go to **Firestore Rules** tab
5. Click **"Rules Simulator"**
6. Test rule (as testUserA):
   ```javascript
   // Authenticated as testUserA
   get /blocks/testUserA_testUserB
   ```
   - ✅ Expected: **ALLOW**

7. Test rule (as testUserC - unrelated user):
   ```javascript
   // Authenticated as testUserC
   get /blocks/testUserA_testUserB
   ```
   - ✅ Expected: **DENY**

8. Test invalid create (wrong blocker):
   ```javascript
   // Authenticated as testUserA
   set /blocks/testUserA_testUserD {
     blockedBy: "testUserC",  // Wrong!
     blockedUser: "testUserD"
   }
   ```
   - ✅ Expected: **DENY**

### **Expected Result:**
✅ Security rules prevent unauthorized access/manipulation

---

## **Test Scenario 8: Edge Cases**

### **A. Block User With Many Portraits:**
1. Block a user who has uploaded many portraits (20+)
2. Navigate to Community
3. Scroll through all portraits
4. Verify:
   - ✅ None of blocked user's portraits appear
   - ✅ No performance issues or lag

### **B. Block User With Active Submissions:**
1. During an active voting period, block a user with submissions
2. Navigate to Submissions tab
3. Verify:
   - ✅ Their submissions don't appear
   - ✅ Vote counts on other submissions still accurate

### **C. Block User Who Won Awards:**
1. Block a user who has won multiple awards
2. Navigate to Awards tab (when winners shown)
3. Navigate to Past Awards tab
4. Verify:
   - ✅ Their wins are hidden from current awards
   - ✅ Their wins are hidden from past awards
   - ✅ Categories with only their wins are hidden entirely

### **D. Mutual Blocking:**
1. User A blocks User B
2. User B blocks User A (simulate with 2 devices/accounts)
3. Verify from both perspectives:
   - ✅ Neither can see each other's content
   - ✅ Both see block status messages on profiles
   - ✅ Both are hidden from each other in all screens

### **E. Block Then Unblock Quickly:**
1. Block a user
2. Immediately unblock them (within seconds)
3. Navigate to various screens
4. Verify:
   - ✅ Content reappears correctly
   - ✅ No stale data or caching issues
   - ✅ Block status updates immediately

---

## **Test Scenario 9: Real-time Updates**

### **Steps (2 devices/accounts needed):**
1. **Device A** (User A): View User B's profile (not blocked)
2. **Device B** (User C): Block User B
3. **Device A**: Refresh Community screen
4. Verify:
   - ✅ User A still sees User B's content (User A didn't block them)

5. **Device A**: Block User B
6. Verify:
   - ✅ User B's content disappears immediately from Community
   - ✅ User B's profile shows block message
   - ✅ No app restart required

---

## **✅ Testing Checklist**

Use this checklist to confirm all features work:

### **Core Blocking:**
- [ ] Can block a user from their profile
- [ ] Confirmation dialog appears before blocking
- [ ] Success message shows after blocking
- [ ] Can unblock a user from their profile
- [ ] Success message shows after unblocking

### **Profile View (Blocked User):**
- [ ] Block status message displays correctly
- [ ] Duotone icon shows
- [ ] Tabs are hidden
- [ ] Portraits are hidden
- [ ] Can access unblock via flag icon

### **Profile View (Blocked By User):**
- [ ] "Has blocked you" message displays
- [ ] Duotone icon shows
- [ ] Tabs are hidden
- [ ] Portraits are hidden
- [ ] Flag icon is hidden (cannot report while blocked)

### **Content Filtering:**
- [ ] Community: Blocked users' portraits hidden
- [ ] Weekly Awards Submissions: Blocked users' submissions hidden
- [ ] Weekly Awards Winners: Blocked users' awards hidden
- [ ] Profile: Blocked users' portraits tab hidden

### **Block/Report Integration:**
- [ ] Flag icon opens block/report dialog
- [ ] Can choose to block OR report
- [ ] Can block AND report (separate actions)
- [ ] Report option hidden when already blocked

### **Security:**
- [ ] Firestore rules deployed
- [ ] Rules simulator tests pass
- [ ] Cannot create blocks as other users
- [ ] Cannot see other users' block lists
- [ ] Can only delete own blocks

---

## **🐛 Known Issues to Watch For**

### **Potential Issues:**
1. **Stale data after unblock** - Content should reappear immediately
2. **Performance with many blocks** - Should handle 50+ blocks smoothly
3. **Race conditions** - Block/unblock in quick succession should work
4. **Real-time updates** - Changes should reflect without app restart

### **If You Find Issues:**
1. Note the exact steps to reproduce
2. Check Firestore Console for data
3. Check app logs for errors
4. Verify Firestore rules are deployed

---

## **📋 Final Validation**

Before submitting to Apple:

1. ✅ All test scenarios pass
2. ✅ Firestore security rules deployed and tested
3. ✅ No console errors or warnings
4. ✅ Block/unblock works on both iOS and Android
5. ✅ Performance is acceptable (no lag)
6. ✅ Content filtering works across all screens
7. ✅ Block status messages display correctly
8. ✅ Report feature still works independently

---

## **🚀 Ready for Apple Submission!**

Once all tests pass:
- ✅ Blocking feature is fully functional
- ✅ Security rules protect user privacy
- ✅ Meets Apple App Store requirements
- ✅ Users can block and unblock seamlessly
- ✅ Content filtering works everywhere

**You can now confidently submit to Apple App Store!** 🎉

