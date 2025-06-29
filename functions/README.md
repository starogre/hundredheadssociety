# Weekly Session Automation Cloud Functions

This directory contains Firebase Cloud Functions that automate weekly session management for the Hundred Heads Society app.

## Functions Overview

### 1. **createWeeklySession** (Scheduled)
- **Trigger**: Every Monday at 9:00 AM EST
- **Purpose**: Automatically creates a new weekly session
- **Actions**:
  - Calculates next Monday's date
  - Creates a new session in Firestore
  - Sends notifications to all approved users
  - Sets session as active

### 2. **sendSessionReminders** (Scheduled)
- **Trigger**: Every Sunday at 9:00 AM EST
- **Purpose**: Sends reminders to users who haven't RSVP'd
- **Actions**:
  - Finds the active session for next Monday
  - Identifies users who haven't RSVP'd
  - Sends reminder notifications

### 3. **closeWeeklySession** (Scheduled)
- **Trigger**: Every Monday at 10:00 AM EST (1 hour after session starts)
- **Purpose**: Closes the session and processes results
- **Actions**:
  - Finds and closes the active session
  - Calculates participation statistics
  - Sends completion notifications
  - Updates session with results

### 4. **onUserRSVP** (Firestore Trigger)
- **Trigger**: When a weekly session document is updated
- **Purpose**: Handles RSVP confirmations
- **Actions**:
  - Detects new RSVPs
  - Sends confirmation notifications to new RSVPs

### 5. **onSubmissionAdded** (Firestore Trigger)
- **Trigger**: When a weekly session document is updated
- **Purpose**: Handles new portrait submissions
- **Actions**:
  - Detects new submissions
  - Notifies other session participants

### 6. **testWeeklySessionFunctions** (HTTP Request)
- **Trigger**: Manual HTTP request
- **Purpose**: Testing function for development
- **Actions**:
  - Creates a test session
  - Returns session details

## Setup Instructions

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Deploy Functions
```bash
firebase deploy --only functions
```

### 3. Test Functions Locally
```bash
firebase emulators:start
```

## Firestore Collections Used

### `weeklySessions`
- Stores weekly session data
- Fields: `sessionDate`, `rsvpUserIds`, `submissions`, `createdAt`, `isActive`

### `users`
- Stores user data
- Fields: `id`, `email`, `name`, `status`, `isAdmin`

### `notifications`
- Stores user notifications
- Fields: `userId`, `type`, `title`, `message`, `createdAt`, `read`, `data`

## Notification Types

1. **session_created**: New weekly session created
2. **session_reminder**: Reminder about upcoming session
3. **rsvp_confirmation**: Confirmation of RSVP
4. **new_submission**: New portrait submitted
5. **session_completed**: Session has ended

## Scheduling

Functions use cron syntax for scheduling:
- `0 9 * * 1`: Every Monday at 9:00 AM
- `0 9 * * 0`: Every Sunday at 9:00 AM
- `0 10 * * 1`: Every Monday at 10:00 AM

## Error Handling

All functions include comprehensive error handling:
- Try-catch blocks for all async operations
- Detailed logging for debugging
- Graceful failure handling

## Testing

### Manual Testing
1. Start Firebase emulators
2. Use the test function: `http://localhost:5001/your-project/us-central1/testWeeklySessionFunctions`
3. Check Firestore for created documents

### Automated Testing
```bash
npm test
```

## Monitoring

Functions can be monitored in the Firebase Console:
1. Go to Functions section
2. View execution logs
3. Monitor performance metrics
4. Set up alerts for errors

## Cost Optimization

- Functions use `maxInstances: 10` to limit concurrent executions
- Batch operations for multiple Firestore writes
- Efficient queries with proper indexing

## Security

- Functions use Firebase Admin SDK for secure database access
- Proper authentication checks
- Input validation and sanitization

## Troubleshooting

### Common Issues

1. **Functions not triggering**:
   - Check Firebase project configuration
   - Verify timezone settings
   - Check function deployment status

2. **Permission errors**:
   - Verify Firestore security rules
   - Check function service account permissions

3. **Notification delivery issues**:
   - Verify notification collection exists
   - Check user document structure

### Debug Steps

1. Check Firebase Console logs
2. Use `console.log()` for debugging
3. Test functions locally with emulators
4. Verify Firestore data structure

## Future Enhancements

- Email notifications integration
- Push notifications for mobile
- Advanced analytics and reporting
- Custom notification preferences
- Session templates and themes 