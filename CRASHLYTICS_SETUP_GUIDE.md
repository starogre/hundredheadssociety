# Firebase Crashlytics Setup Guide

## ✅ What's Been Implemented

### **1. Dependencies Added**
- `firebase_crashlytics: ^4.1.3` added to `pubspec.yaml`

### **2. Main App Initialization**
- Added Crashlytics initialization in `main.dart`
- Set up global error handlers for Flutter and platform errors
- All uncaught errors will now be automatically reported

### **3. Custom Crash Logging Service**
- Created `lib/services/crashlytics_service.dart`
- Provides organized methods for different types of errors:
  - `recordAuthError()` - Authentication issues
  - `recordRsvpError()` - RSVP-specific problems
  - `recordPushNotificationError()` - Push notification issues
  - `setUserContext()` - Set user information for crash reports

### **4. Enhanced Error Reporting**
- **AuthProvider**: Now logs initialization and user data loading errors
- **WeeklySessionProvider**: Logs RSVP operation errors
- **User Context**: Automatically sets user ID and email in crash reports

## 🚀 How This Helps with the Current Issue

### **Before Crashlytics:**
- User crashes → No information about what caused it
- Stuck on splash screen → No way to debug
- No crash reports → Can't identify patterns

### **After Crashlytics:**
- **Real-time crash reports** with stack traces
- **User-specific data** (which user is crashing)
- **Detailed context** (what operation was happening)
- **Custom error logging** for RSVP and auth issues

## 📊 What You'll See in Firebase Console

### **Crash Reports Will Include:**
1. **Stack traces** showing exactly where the crash occurred
2. **User information** (UID, email, display name)
3. **Custom keys** with context:
   - `error_type`: "auth_error", "rsvp_error", etc.
   - `user_id`: The crashing user's ID
   - `action`: What operation was being performed
   - `session_id`: For RSVP-related crashes

### **Example Crash Report:**
```
Error: AuthProvider _loadUserData
User: user123@example.com
Custom Keys:
  - error_type: auth_error
  - user_id: abc123
  - action: load_user_data
  - user_email: user123@example.com
```

## 🔧 Next Steps

### **1. Deploy the App**
```bash
flutter build apk --release
# or
flutter build ios --release
```

### **2. Enable Crashlytics in Firebase Console**
1. Go to Firebase Console → Crashlytics
2. Enable Crashlytics for your project
3. Wait for the first crash report (can take a few minutes)

### **3. Test the Integration**
- Have the user try to open the app
- If it crashes, you'll get a detailed report
- If it shows the error screen, you'll get non-fatal error reports

### **4. Monitor Crash Reports**
- Check Firebase Console → Crashlytics regularly
- Look for patterns in crashes
- Use the user context to identify specific users having issues

## 🎯 Specific Benefits for Your Current Issue

### **For the User Stuck on Splash Screen:**
1. **If it's still crashing**: You'll get the exact stack trace
2. **If it shows error screen**: You'll get non-fatal error reports with context
3. **User identification**: You'll know exactly which user is having issues

### **For RSVP Push Notification Issues:**
1. **Navigation crashes**: Will be logged with push notification context
2. **RSVP operation failures**: Will be logged with session and user context
3. **Pattern identification**: You can see if multiple users have the same issue

## 📱 Testing the Integration

### **Test 1: Force a Crash (Development Only)**
```dart
// Add this temporarily to test Crashlytics
await CrashlyticsService.testCrash();
```

### **Test 2: Log a Custom Error**
```dart
// Log a non-fatal error
await CrashlyticsService.recordAuthError(
  Exception('Test error'),
  StackTrace.current,
  userId: 'test_user',
  email: 'test@example.com',
  action: 'test_action',
);
```

## 🚨 Important Notes

1. **Crashlytics only works in release builds** - Debug builds won't send reports
2. **First report can take 5-10 minutes** to appear in Firebase Console
3. **User consent**: Make sure your privacy policy covers crash reporting
4. **Data retention**: Crashlytics data is retained for 90 days by default

## 🔍 Debugging the Current User's Issue

Once deployed, you should be able to:

1. **See exactly where the crash occurs** in the stack trace
2. **Identify the specific error** causing the initialization failure
3. **Get user context** to confirm it's the right user
4. **Track if the fix resolves the issue** by monitoring crash frequency

The combination of the error handling fixes + Crashlytics will give you complete visibility into what's happening with the user's app.
