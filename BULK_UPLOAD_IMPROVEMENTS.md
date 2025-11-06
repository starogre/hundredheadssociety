# Bulk Portrait Upload Improvements

## What Changed

### Replaced Custom Gallery Picker with WeChat Assets Picker

**Before:**
- Custom `BulkImageGridPicker` widget using `photo_manager`
- Only showed "Recent" album (hardcoded)
- Limited to 200 images per page
- Flashing issues on Android
- No album selection

**After:**
- Using `wechat_assets_picker` package (v9.8.0)
- Native-like gallery experience
- **Full album selection** - users can browse all their albums
- **No arbitrary limits** - can select up to max allowed (100 - portraits completed)
- Better performance and reliability on both platforms
- Familiar UI that users expect

## Key Features

### 1. **Album Selection**
Users can now:
- See all their photo albums (Camera Roll, Screenshots, Downloads, etc.)
- Switch between albums easily
- Browse their entire photo library

### 2. **Better Permission Handling**
- Graceful permission requests
- Opens settings if permission denied
- Clear error messages

### 3. **Improved Android Support**
- Android 13+ (API 33+): Uses new photo picker permissions
  - `READ_MEDIA_IMAGES` - For reading images
  - `READ_MEDIA_VISUAL_USER_SELECTED` - For partial photo access
- Android 10-12: Uses `READ_EXTERNAL_STORAGE`
- Android 9 and below: Includes `WRITE_EXTERNAL_STORAGE`

### 4. **iOS Optimization**
- Uses iOS 14+ `PHPickerViewController` under the hood
- Native iOS photo picker experience
- Better memory management

## Testing Guide

### Android Testing

#### Test on Different Android Versions:
1. **Android 13+ (API 33+)**
   - Test "Select photos" vs "Allow all photos" permission
   - Verify partial selection works
   - Check album switching

2. **Android 10-12**
   - Verify storage permission request
   - Test multi-select functionality

3. **Android 9 and below**
   - Ensure storage permissions work
   - Check read/write access

#### Testing Steps:
1. Open the app
2. Navigate to Add Portrait screen
3. Toggle "Add Multiple" switch
4. Tap "Select Images"
5. **Test Album Selection:**
   - Tap on "Recent" (or album name) at the top
   - Switch to different albums (Screenshots, Camera, Downloads)
   - Verify all albums show their contents
6. Select multiple images (try 10+, 20+, 50+)
7. Verify images load in the portrait cards
8. Test uploading the batch

### iOS Testing

#### Testing Steps:
1. Open the app
2. Navigate to Add Portrait screen
3. Toggle "Add Multiple" switch
4. Tap "Select Images"
5. **Test Album Selection:**
   - Verify native iOS picker appears
   - Tap "Albums" at the bottom
   - Browse different albums
   - Select photos from various albums
6. Select multiple images (try 10+, 20+, 50+)
7. Verify images load in the portrait cards
8. Test uploading the batch

### Edge Cases to Test

1. **Permission Denied:**
   - Deny photo permission
   - Verify app shows message and opens settings

2. **Large Selection:**
   - Try selecting max allowed portraits (e.g., if user has 50 completed, select 50)
   - Verify it caps at the limit

3. **Memory Handling:**
   - Select 50+ high-resolution images
   - Verify app doesn't crash
   - Check upload progress

4. **Network Issues:**
   - Start upload, then disable network
   - Verify error handling
   - Check which portraits uploaded successfully

5. **Background/Foreground:**
   - Start upload
   - Switch to another app
   - Return to verify upload continues/resumes

## Technical Details

### Code Changes

**File: `lib/screens/add_portrait_screen.dart`**
- Added `wechat_assets_picker` import
- Removed `bulk_image_grid_picker.dart` import
- Replaced `BulkImageGridPicker` navigation with `AssetPicker.pickAssets()`
- Improved permission handling with better error messages
- Added try-catch for robust error handling

**File: `pubspec.yaml`**
- Added `wechat_assets_picker: ^9.4.0` dependency

**File: `android/app/src/main/AndroidManifest.xml`**
- Updated photo permissions for Android 13+
- Added `READ_MEDIA_VISUAL_USER_SELECTED` for partial access
- Added `maxSdkVersion` constraints for legacy permissions

**File: `ios/Runner/Info.plist`**
- Already had proper permissions (no changes needed)

### Performance Improvements

1. **Lazy Loading:** Images are loaded on-demand, not all at once
2. **Thumbnail Generation:** Uses efficient thumbnails in picker
3. **Memory Management:** Better handling of large image sets
4. **Native UI:** Leverages platform-optimized pickers

## Known Limitations

1. **Max Selection:** Still limited by available portrait slots (100 - completed)
2. **Sequential Upload:** Uploads happen one at a time (parallel upload is a future enhancement)
3. **No Image Reordering:** Once selected, images can't be reordered (future enhancement)

## Future Enhancements

1. **Parallel Uploads:** Upload multiple images simultaneously
2. **Image Compression:** Optimize images before upload to save bandwidth
3. **Drag & Drop Reordering:** Let users reorder selected images
4. **Bulk Settings:** Apply same description/model to all images
5. **Save Draft:** Save selections and resume later
6. **Upload Queue:** Better handling of failed uploads with retry

## Troubleshooting

### Android: "No albums showing"
- Ensure app has storage/media permissions
- Check Settings > Apps > 100 Heads > Permissions
- Grant "Photos and videos" or "Files and media" permission

### iOS: "Can't access photos"
- Go to Settings > 100 Heads > Photos
- Select "Full Access" or "Selected Photos"

### "Flashing screen" on Android
- This was caused by the old custom picker
- Should be resolved with `wechat_assets_picker`
- If it persists, check device OS version and permissions

### "Upload fails midway"
- Check internet connection
- Verify Firebase Storage rules
- Check Crashlytics for error logs
- Note which portrait failed (look at progress indicator)

## Version Info

- **Flutter SDK:** 3.8.1+
- **wechat_assets_picker:** 9.8.0
- **photo_manager:** 3.7.1 (still used for permission handling)
- **Min Android SDK:** 21
- **Min iOS Version:** 11.0

