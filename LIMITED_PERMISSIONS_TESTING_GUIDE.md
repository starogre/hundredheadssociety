# Limited Photo Permissions Testing Guide

## 🐛 Bug Fix: Limited Photo Access Support

### What Was Fixed?
The bulk upload feature now properly handles limited photo access on both Android and iOS. Previously, users who selected "Select Photos" (limited access) would see no images in the picker.

### Changes Made

#### 1. **Permission Handling (`lib/screens/add_portrait_screen.dart`)**
- Added explicit handling for `PermissionState.limited`
- Differentiate between `authorized` (full), `limited` (selected), and `denied` states
- Continue to picker even with limited access
- Show helpful messages for each permission state

#### 2. **User Experience Improvements**
- **Full Access:** Proceed normally with no message
- **Limited Access:** Show SnackBar with option to add more photos in Settings
- **Denied Access:** Show SnackBar with option to open Settings
- Added optional informational dialog explaining limited access

#### 3. **Platform Configuration**
- **Android:** Already configured with `READ_MEDIA_VISUAL_USER_SELECTED` for Android 13+
- **iOS:** Already configured with `NSPhotoLibraryUsageDescription`

---

## 🧪 Testing Instructions

### Prerequisites
- **Android:** Device running Android 13 (API 33) or higher
- **iOS:** Device running iOS 14 or higher
- Fresh install or reset photo permissions before testing

---

### Test Case 1: Android 13+ Limited Access

#### Setup:
1. Install the app on Android 13+ device
2. If app was previously installed, go to **Settings > Apps > 100 Heads > Permissions > Photos and videos** and select **Remove permissions**

#### Test Steps:
1. Open the app and navigate to **Add Portrait**
2. Toggle **"Add Multiple"** to ON
3. Tap **"Select Images"**
4. When prompted for photo access, select **"Select photos and videos"** (NOT "Allow all")
5. Choose 3-5 photos from the picker
6. Confirm selection

**Expected Results:**
- ✅ Permission dialog shows with option to select specific photos
- ✅ You can select 3-5 photos from the system picker
- ✅ App's bulk upload picker opens and shows your selected photos
- ✅ SnackBar appears: "You've granted access to selected photos..."
- ✅ You can select images for bulk upload from your limited set
- ✅ Tapping "Settings" in SnackBar opens device settings

#### Additional Test:
1. After initial setup, go back and tap **"Select Images"** again
2. **Expected:** Picker shows only your previously selected photos
3. Tap **"Settings"** from the SnackBar
4. In device settings, add more photos to the allowed set
5. Return to app and tap **"Select Images"** again
6. **Expected:** Picker now shows all photos in your allowed set (old + new)

---

### Test Case 2: iOS 14+ Limited Access

#### Setup:
1. Install the app on iOS 14+ device
2. If app was previously installed:
   - Go to **Settings > 100 Heads > Photos**
   - Select **None** to reset permissions

#### Test Steps:
1. Open the app and navigate to **Add Portrait**
2. Toggle **"Add Multiple"** to ON
3. Tap **"Select Images"**
4. When prompted for photo access, select **"Select Photos..."**
5. Choose 3-5 photos from the system picker
6. Tap **"Done"**

**Expected Results:**
- ✅ Permission dialog shows with "Select Photos..." option
- ✅ System photo picker opens
- ✅ You can select 3-5 photos
- ✅ App's bulk upload picker opens and shows your selected photos
- ✅ SnackBar appears: "You've granted access to selected photos..."
- ✅ You can select images for bulk upload from your limited set
- ✅ Tapping "Settings" in SnackBar opens iOS Settings app

#### Additional Test:
1. After initial setup, go to **Settings > 100 Heads > Photos**
2. Current setting should be **"Selected Photos (3)"** (or however many you chose)
3. Tap **"Selected Photos"**
4. Add 2-3 more photos to the selection
5. Return to app and tap **"Select Images"** again
6. **Expected:** Picker now shows all photos in your allowed set (old + new)

---

### Test Case 3: Full Access (Both Platforms)

#### Android:
1. Install app or reset permissions
2. When prompted, select **"Allow all"**
3. **Expected:** No SnackBar message, picker shows all photos immediately

#### iOS:
1. Install app or reset permissions
2. When prompted, select **"Allow Access to All Photos"**
3. **Expected:** No SnackBar message, picker shows all photos immediately

---

### Test Case 4: Denied Access (Both Platforms)

#### Android:
1. Install app or reset permissions
2. When prompted, select **"Don't allow"**
3. **Expected:**
   - SnackBar: "Photo access permission denied..."
   - "Open Settings" button in SnackBar
   - Picker does NOT open
   - Tapping "Open Settings" opens device settings

#### iOS:
1. Install app or reset permissions
2. When prompted, select **"Don't Allow"**
3. **Expected:**
   - SnackBar: "Photo access permission denied..."
   - "Open Settings" button in SnackBar
   - Picker does NOT open
   - Tapping "Open Settings" opens iOS Settings app

---

### Test Case 5: Upgrading from Limited to Full

#### Android:
1. Start with limited access (3 photos selected)
2. Tap "Select Images"
3. Tap "Settings" in the SnackBar
4. In device settings, change permission to **"Allow all"**
5. Return to app
6. Tap "Select Images" again
7. **Expected:** Picker now shows ALL photos in device gallery

#### iOS:
1. Start with limited access (3 photos selected)
2. Go to **Settings > 100 Heads > Photos**
3. Change to **"Full Access"**
4. Return to app
5. Tap "Select Images"
6. **Expected:** Picker now shows ALL photos in device library

---

## 🎯 Success Criteria

### Critical (Must Pass):
- [ ] Android 13+ limited access shows selected photos in picker
- [ ] iOS 14+ limited access shows selected photos in picker
- [ ] Users can successfully bulk upload portraits with limited access
- [ ] No crashes when permission is limited
- [ ] SnackBar messages appear for limited and denied states
- [ ] "Settings" button opens device/app settings

### Important (Should Pass):
- [ ] Adding more photos to limited selection works
- [ ] Upgrading from limited to full access works smoothly
- [ ] Full access still works as before (no regression)
- [ ] Denied access shows appropriate messaging

### Nice to Have:
- [ ] Print statements show correct permission state in logs
- [ ] UI is responsive and doesn't freeze during permission requests
- [ ] Multiple back-and-forth between limited and full works correctly

---

## 📋 Known Limitations

1. **iOS PHPicker:** On iOS 14+, if the app uses `PHPickerViewController` (which is the native picker for limited access), users will need to select photos twice:
   - Once to grant limited access to the app
   - Once to select images for bulk upload
   - This is expected behavior and follows iOS guidelines

2. **Android Photo Picker:** On Android 13+, the system photo picker may take a moment to load the first time

3. **Permission Persistence:** Users need to manually add more photos in Settings if they want to expand their limited selection

---

## 🔍 Debug Information

### Logs to Check:
When testing, look for these print statements in the console:

```
Photo permission: AUTHORIZED (full access)
Photo permission: LIMITED (selected photos only)
Photo permission: DENIED
```

### Common Issues:

**Issue:** Picker shows no photos even after granting permission
- **Android:** Make sure device is API 33+ and has photos in gallery
- **iOS:** Make sure device is iOS 14+ and photos were selected in the permission dialog

**Issue:** "Settings" button doesn't open settings
- **Android:** Check that `PhotoManager.openSetting()` is called
- **iOS:** Check that `PhotoManager.openSetting()` is called and app has correct bundle ID

**Issue:** App crashes when opening picker with limited access
- Check console for error messages
- Verify `wechat_assets_picker` version is up to date
- Ensure `photo_manager` is properly initialized

---

## 📝 Technical Details

### Permission States:
- `PermissionState.authorized`: Full access to photo library
- `PermissionState.limited`: Access to selected photos only (iOS 14+, Android 13+)
- `PermissionState.denied`: No access (user explicitly denied or app not authorized)

### Android SDK Versions:
- **Android 13+ (API 33+):** Uses `READ_MEDIA_IMAGES` and `READ_MEDIA_VISUAL_USER_SELECTED`
- **Android 12 and below (API 32-):** Uses `READ_EXTERNAL_STORAGE`

### iOS Versions:
- **iOS 14+:** Supports limited photo library access via PHPicker
- **iOS 13 and below:** Only full access or no access

---

## ✅ Testing Checklist

Before marking this feature as complete, verify:

- [ ] Tested on Android 13 with "Select photos"
- [ ] Tested on Android 13 with "Allow all"
- [ ] Tested on Android 13 with "Don't allow"
- [ ] Tested on iOS 14+ with "Select Photos..."
- [ ] Tested on iOS 14+ with "Allow Access to All Photos"
- [ ] Tested on iOS 14+ with "Don't Allow"
- [ ] Tested adding more photos to limited selection (both platforms)
- [ ] Tested upgrading from limited to full (both platforms)
- [ ] Verified SnackBar messages appear correctly
- [ ] Verified "Settings" button works (both platforms)
- [ ] Verified successful bulk upload with limited access
- [ ] No crashes observed during testing

---

## 🚀 Next Steps

Once testing is complete:
1. Document any issues or unexpected behavior
2. Mark test cases as passed/failed
3. Address any bugs found during testing
4. Update BULK_UPLOAD_UX_PLAN.md with Phase 1 completion status
5. Proceed to Phase 2: Essential UX improvements

