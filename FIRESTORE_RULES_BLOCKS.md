# Firestore Security Rules for Blocks Collection

## **IMPORTANT: Add these rules to Firebase Console**

These security rules are **required for Apple App Store approval** to ensure users can only manage their own blocks.

---

## **Rules to Add**

Add this section to your `firestore.rules` file **after the Models collection and before the closing braces**:

```javascript
    // Blocks collection - User blocking system
    match /blocks/{blockId} {
      // Allow users to create blocks where they are the blocker
      // blockId format: "blockerId_blockedUserId"
      allow create: if request.auth != null 
        && blockId == request.auth.uid + '_' + request.resource.data.blockedUser
        && request.resource.data.blockedBy == request.auth.uid
        && request.resource.data.blockedUser is string
        && request.resource.data.createdAt == request.time;
      
      // Allow users to read blocks where they are involved (either blocker or blocked)
      allow read: if request.auth != null 
        && (resource.data.blockedBy == request.auth.uid 
            || resource.data.blockedUser == request.auth.uid);
      
      // Allow users to delete blocks they created (unblock)
      allow delete: if request.auth != null 
        && resource.data.blockedBy == request.auth.uid;
      
      // No updates allowed - blocks are immutable
    }
```

---

## **How to Apply**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Find the `// Models collection` section
5. **Add the blocks collection rules above** after the Models section
6. Click **Publish** to deploy

---

## **What These Rules Do**

### **Create Rule** ✅
```javascript
allow create: if request.auth != null 
  && blockId == request.auth.uid + '_' + request.resource.data.blockedUser
  && request.resource.data.blockedBy == request.auth.uid
```

**Ensures:**
- Only authenticated users can create blocks
- Document ID matches pattern: `blockerId_blockedUserId`
- User can only create blocks where they are the blocker
- Prevents users from creating fake blocks as someone else

---

### **Read Rule** ✅
```javascript
allow read: if request.auth != null 
  && (resource.data.blockedBy == request.auth.uid 
      || resource.data.blockedUser == request.auth.uid)
```

**Ensures:**
- Users can only read blocks where they are involved
- Users who blocked someone can see their block list
- Users who are blocked can check if they're blocked (for app logic)
- Privacy: Users cannot see other people's block relationships

---

### **Delete Rule** ✅
```javascript
allow delete: if request.auth != null 
  && resource.data.blockedBy == request.auth.uid
```

**Ensures:**
- Only the blocker can remove the block (unblock)
- Blocked users cannot remove blocks against them
- Prevents abuse

---

### **No Update Rule** ✅
**Blocks are immutable** - you can only create or delete them, not modify them.

---

## **Testing the Rules**

After adding the rules, test them in the Firebase Console:

### **Test 1: Create Block**
```javascript
// Authenticated as user "user123"
set /blocks/user123_user456 {
  blockedBy: "user123",
  blockedUser: "user456",
  createdAt: request.time
}
// Expected: ALLOW
```

### **Test 2: Create Invalid Block (Wrong blocker)**
```javascript
// Authenticated as user "user123"
set /blocks/user123_user456 {
  blockedBy: "user999",  // Wrong!
  blockedUser: "user456",
  createdAt: request.time
}
// Expected: DENY
```

### **Test 3: Read Own Block**
```javascript
// Authenticated as user "user123"
get /blocks/user123_user456
// Expected: ALLOW (user123 is the blocker)
```

### **Test 4: Read Someone Else's Block**
```javascript
// Authenticated as user "user123"
get /blocks/user999_user888
// Expected: DENY (user123 not involved)
```

### **Test 5: Delete Own Block (Unblock)**
```javascript
// Authenticated as user "user123"
delete /blocks/user123_user456
// Expected: ALLOW
```

### **Test 6: Delete Someone Else's Block**
```javascript
// Authenticated as user "user456"
delete /blocks/user123_user456
// Expected: DENY (user456 is blocked, not blocker)
```

---

## **Why This is Required for Apple**

Apple App Store requires apps with user-generated content to have:

1. ✅ **Block functionality** - Implemented
2. ✅ **Content reporting** - Implemented
3. ✅ **Secure block system** - **These rules ensure this!**

Without these security rules, users could:
- Create fake blocks as other users
- See everyone's block lists (privacy violation)
- Delete blocks they didn't create
- **Apple will reject the app for insufficient blocking security**

---

## **Current Rules Status**

✅ **Reports collection** - Already added  
⚠️ **Blocks collection** - **ADD THESE NOW**

Once added, your blocking feature will be **fully secure and Apple-compliant**! 🎉

