# Bulk Upload UX Improvements Plan

## 🐛 Critical Bug: Limited Photo Permissions

### Problem:
When users grant "limited" photo access (select specific photos on Android/iOS), the bulk upload picker doesn't show any images. Only works with "full" permissions.

### Root Cause:
The `wechat_assets_picker` (or underlying `photo_manager`) may not be properly requesting or accessing the limited selection that the user granted.

### Solution Options:

#### Option A: Request Limited Photo Access Properly
```dart
// When requesting permission, handle limited access
final PermissionState permission = await PhotoManager.requestPermissionExtend(
  requestOption: PermissionRequestOption(
    iosAccessLevel: IosAccessLevel.readWrite, // or .addOnly
    androidMediaLocation: true,
  ),
);

// Check if user granted limited access
if (permission == PermissionState.limited) {
  // Show message: "You've selected X photos. Add more in Settings?"
  // Still allow picking from the limited set
}
```

#### Option B: Use Native Platform Pickers for Limited Access
- iOS 14+: Use `PHPickerViewController` (built into wechat_assets_picker)
- Android 13+: Use Photo Picker
- These automatically handle limited access

#### Option C: Detect Limited Access & Guide User
```dart
if (permission == PermissionState.limited) {
  // Show dialog: "You've granted access to specific photos"
  // Button: "Select More Photos" -> opens settings
  // Button: "Continue with Selected" -> uses limited set
}
```

### Recommended Fix:
**Combination of A + C**
1. Properly handle `PermissionState.limited`
2. Show user-friendly message about limited access
3. Provide option to select more photos via settings
4. Still allow using the limited photo set they granted

---

## 🎨 UX Improvements

### 1. Preview & Edit Before Upload

**Current Issues:**
- Can't preview all selected images at once
- Can't edit descriptions/models after selection
- No way to remove individual images without starting over
- Can't reorder images

**Proposed UX:**

#### A. Better Preview Grid
```
┌─────────────────────────────────────┐
│  Selected: 12 images                 │
│  [Select More] [Clear All]          │
├─────────────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ 1  │ │ 2  │ │ 3  │ │ 4  │       │
│  │[x] │ │[x] │ │[x] │ │[x] │       │
│  └────┘ └────┘ └────┘ └────┘       │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ 5  │ │ 6  │ │ 7  │ │ 8  │       │
│  │[x] │ │[x] │ │[x] │ │[x] │       │
│  └────┘ └────┘ └────┘ └────┘       │
└─────────────────────────────────────┘
```

Features:
- ✅ Small [x] button on each thumbnail to remove
- ✅ Number badge showing portrait order
- ✅ Tap image to expand and edit
- ✅ "Select More" button to add additional images

#### B. Drag & Reorder
```dart
// Use ReorderableListView or custom drag implementation
ReorderableGridView.builder(
  onReorder: (oldIndex, newIndex) {
    setState(() {
      // Reorder images, descriptions, models, weeks
      final item = _bulkImages.removeAt(oldIndex);
      _bulkImages.insert(newIndex, item);
      // Update week numbers based on new order
    });
  },
)
```

#### C. Quick Edit Modal
When user taps an image:
```
┌─────────────────────────────────────┐
│  Edit Portrait #3                    │
├─────────────────────────────────────┤
│  [Image Preview]                     │
│                                      │
│  Week: 3                             │
│                                      │
│  Description (optional)              │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  └──────────────────────────────┘   │
│                                      │
│  Model                               │
│  [Model Dropdown ▼]                  │
│                                      │
│  [Remove Image] [Save]               │
└─────────────────────────────────────┘
```

### 2. Bulk Actions

**Apply to All:**
```
┌─────────────────────────────────────┐
│  Quick Actions                       │
├─────────────────────────────────────┤
│  Model: [Same for All ▼]            │
│  Description: [Same for All]        │
│                                      │
│  [Apply to All]                      │
└─────────────────────────────────────┘
```

Features:
- Set same model for all images
- Set same description for all images
- Set description pattern (e.g., "Week {week}" auto-fills)

### 3. Better Week Assignment

**Current:** Auto-assigns to fill gaps (1, 2, 3...)
**Proposed:** Show week numbers clearly with option to customize

```
Portrait #1 → Week 1
Portrait #2 → Week 2
Portrait #3 → Week 3

[Auto-assign weeks] [Custom week assignment]
```

### 4. Upload Progress Improvements (Instagram-Style Background Upload)

**Current:**
- Shows "Uploading X of Y"
- Linear progress bar
- User stuck on upload screen

**Proposed:**
```
┌─────────────────────────────────────┐
│  ⏳ Uploading 5 of 12 portraits... ▼ │  ← Persistent top bar
│  ████████░░░░░░░░  42%              │
└─────────────────────────────────────┘

   [User can navigate anywhere in app]

On "My Heads" (Profile) screen:
┌─────────────────────────────────────┐
│  ⏳ Uploading 5 of 12 portraits... ▼ │  ← Same bar follows
│  ████████░░░░░░░░  42%              │
└─────────────────────────────────────┘

Tap to expand:
┌─────────────────────────────────────┐
│  Uploading 5 of 12 portraits...      │
├─────────────────────────────────────┤
│  ████████░░░░░░░░  42%              │
│                                      │
│  ✅ Portrait 1 - Week 1              │
│  ✅ Portrait 2 - Week 2              │
│  ✅ Portrait 3 - Week 3              │
│  ✅ Portrait 4 - Week 4              │
│  ⏳ Portrait 5 - Week 5 (uploading...)│
│  ⏸ Portrait 6 - Week 6 (waiting...)  │
│  ⏸ Portrait 7 - Week 7 (waiting...)  │
│                                      │
│  [Cancel Upload]                     │
└─────────────────────────────────────┘
```

Features:
- ✅ **Persistent progress bar at top of screen**
- ✅ **User can navigate away while uploading**
- ✅ **Progress bar visible on Add Portrait AND Profile screens**
- ✅ **Tap to expand for detailed view**
- ✅ Show individual upload status
- ✅ Clear visual feedback
- ✅ Option to cancel
- ✅ Show which ones failed with retry option
- ✅ Continue upload in background
- ✅ Handle app backgrounding/foregrounding

### 5. Error Handling

**Failed Uploads:**
```
┌─────────────────────────────────────┐
│  ⚠️ 2 portraits failed to upload     │
├─────────────────────────────────────┤
│  ❌ Portrait 5 - Network error       │
│     [Retry] [Remove]                 │
│                                      │
│  ❌ Portrait 8 - File too large      │
│     [Retry] [Remove]                 │
│                                      │
│  ✅ 10 portraits uploaded successfully│
│                                      │
│  [Retry All] [Close]                 │
└─────────────────────────────────────┘
```

### 6. Save Draft

**Feature:** Save bulk upload as draft
```dart
// Save to local storage or Firestore
class BulkUploadDraft {
  List<String> imagePaths;
  List<String> descriptions;
  List<String?> modelIds;
  List<int> weekNumbers;
  DateTime savedAt;
}

// Load on return
if (hasSavedDraft) {
  showDialog: "You have an unfinished upload. Continue?"
}
```

---

## 📋 Implementation Priority

### Phase 1: Critical Bug Fix (Do First!)
1. ✅ Fix limited photo permissions issue
2. ✅ Test on Android 13+ with limited access
3. ✅ Test on iOS 14+ with limited access

### Phase 2: Essential UX (Next)
1. ✅ Add remove button on each image thumbnail
2. ✅ Better preview grid layout
3. ✅ "Select More" button to add additional images
4. ✅ Quick edit modal for each image
5. ✅ Background upload with persistent progress bar (Instagram-style)

### Phase 3: Nice to Have
1. ⏳ Drag & reorder functionality
2. ⏳ Bulk actions (apply model/description to all)
3. ⏳ Better upload progress with individual status
4. ⏳ Error handling with retry

### Phase 4: Advanced
1. ⏳ Save draft functionality
2. ⏳ Image compression before upload
3. ⏳ Parallel uploads (multiple at once)

---

## 🔧 Technical Implementation Notes

### File: `lib/screens/add_portrait_screen.dart`

#### Fix Limited Permissions:
```dart
Future<void> _pickBulkImages() async {
  try {
    // Check permission state
    final PermissionState permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    
    // Handle all permission states
    if (permission == PermissionState.authorized) {
      // Full access - proceed normally
      _openImagePicker();
    } else if (permission == PermissionState.limited) {
      // Limited access - show message but still allow picking
      _showLimitedAccessDialog();
      _openImagePicker(); // Still open picker with limited access
    } else {
      // Denied - show settings dialog
      _showPermissionDeniedDialog();
    }
  } catch (e) {
    // Handle error
  }
}
```

#### Better UI:
```dart
// Replace current ListView with GridView
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: _bulkImages.length,
  itemBuilder: (context, i) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _editImage(i),
          child: Image.file(_bulkImages[i], fit: BoxFit.cover),
        ),
        // Number badge
        Positioned(
          top: 4,
          left: 4,
          child: CircleAvatar(
            radius: 12,
            child: Text('${i + 1}'),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(i),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16),
            ),
          ),
        ),
      ],
    );
  },
)
```

---

## 📝 User Flow

### Current Flow:
1. Toggle "Add Multiple"
2. Tap "Select Images"
3. Picker opens (if permissions allow)
4. Select images
5. See long scrolling list of cards
6. Fill in details for each
7. Tap "Submit All"
8. Wait for upload

### Improved Flow:
1. Toggle "Add Multiple"
2. Tap "Select Images"
3. **NEW:** Handle limited permissions gracefully
4. **NEW:** See grid preview of selected images
5. **NEW:** Option to "Select More" or remove individual images
6. **NEW:** Tap image to edit individually
7. **NEW:** Use "Apply to All" for bulk edits
8. **NEW:** Drag to reorder if needed
9. Review final order and details
10. Tap "Upload All"
11. **NEW:** See detailed upload progress
12. **NEW:** Handle errors with retry option

---

## 🧪 Testing Checklist

### Permissions:
- [ ] Android 13+ with "Select photos" (limited)
- [ ] Android 13+ with "Allow all"
- [ ] Android 12 and below
- [ ] iOS 14+ with "Selected Photos" (limited)
- [ ] iOS 14+ with "All Photos"
- [ ] iOS 13 and below

### UX:
- [ ] Select images, remove one, continue
- [ ] Select images, add more, continue
- [ ] Edit individual image details
- [ ] Apply model to all images
- [ ] Reorder images (if implemented)
- [ ] Upload with some failures, retry
- [ ] Cancel upload mid-way

---

## 🎯 Success Metrics

1. **Bug Fix:** Users with limited permissions can see and select their granted photos
2. **UX:** Users can easily manage their bulk selection before uploading
3. **UX:** Users can fix errors without re-uploading everything
4. **UX:** Upload process is clear and transparent

