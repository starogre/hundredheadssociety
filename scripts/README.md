# User Data Repair Tools

This directory contains tools to repair user data inconsistencies that can occur when user documents are overwritten or corrupted.

## Problem Description

The issue occurs when the fallback user creation mechanism in the authentication system overwrites existing user data. This can happen when:

1. Someone attempts to sign up with an existing email address
2. The Firebase Auth signup fails (email already exists)
3. The fallback mechanism creates a new user document with default values
4. This overwrites the existing user's data, including admin privileges and portrait associations

## Symptoms

- User name changes to "User"
- Admin/moderator privileges are lost
- Profile picture is lost
- `portraitIds` array becomes empty
- Portraits still show in profile (because they're queried by `userId`, not `portraitIds`)

## Solutions

### 1. Standalone Repair Script

Run the standalone Dart script to repair user data:

```bash
# Make the script executable
chmod +x scripts/run_repair_script.sh

# Run the repair script
./scripts/run_repair_script.sh
```

Or run directly with Dart:

```bash
dart run scripts/repair_user_data.dart
```

**Before running, update these values in the script:**
- `userEmail`: The email address of the user to repair
- `restoreAdmin`: Whether to restore admin privileges
- `restoreModerator`: Whether to restore moderator privileges  
- `correctName`: The correct name for the user

### 2. In-App Repair Tool

The app includes a built-in repair tool accessible to admins:

1. Navigate to the User Data Repair screen (add to admin menu)
2. Enter the user's email address
3. Check the consistency of their data
4. Run the repair if needed

### 3. Programmatic Repair

Use the `UserDataRepairService` in your code:

```dart
final repairService = UserDataRepairService();

// Repair by email
final result = await repairService.repairUserDataByEmail(
  email: 'user@example.com',
  restoreAdmin: true,
  restoreModerator: true,
  correctName: 'Correct Name',
);

// Check consistency
final check = await repairService.checkUserDataConsistency(userId);
```

## What Gets Repaired

The repair tools will:

1. **Find all portraits** associated with the user's `userId`
2. **Rebuild the `portraitIds` array** with the correct portrait IDs
3. **Update `portraitsCompleted` count** to match actual portrait count
4. **Restore admin privileges** (if requested)
5. **Restore moderator privileges** (if requested)
6. **Update the user's name** (if provided)

## Prevention

The root cause has been fixed by updating the fallback user creation logic to:

1. **Check for existing users by email** before creating new documents
2. **Prevent overwriting existing data** by checking if documents already exist
3. **Detect UID mismatches** and report data inconsistencies instead of creating new documents

## Files Modified

- `lib/providers/auth_provider.dart` - Fixed fallback user creation logic
- `lib/services/auth_service.dart` - Added safety checks and new methods
- `lib/services/user_data_repair_service.dart` - New repair service
- `lib/screens/user_data_repair_screen.dart` - New repair UI
- `scripts/repair_user_data.dart` - Standalone repair script
- `scripts/run_repair_script.sh` - Script runner

## Testing

After running the repair:

1. Check that portraits display correctly in the user's profile
2. Verify admin/moderator privileges are restored
3. Confirm the user's name is correct
4. Check that the `portraitIds` array contains the correct IDs
5. Verify that `portraitsCompleted` matches the actual count

## Troubleshooting

If the repair fails:

1. Check Firebase permissions
2. Verify the user exists in the database
3. Check for network connectivity issues
4. Review the console logs for detailed error messages

## Future Improvements

- Add batch repair functionality for multiple users
- Add data validation and integrity checks
- Create automated monitoring for data inconsistencies
- Add rollback functionality for failed repairs
