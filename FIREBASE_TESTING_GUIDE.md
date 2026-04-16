# Quick Testing Guide - Firebase Google Sign-In

## ✅ Pre-Test Checklist

Before running the app, verify:

- [x] Firebase project created
- [x] Google authentication enabled in Firebase Console
- [x] SHA-1 fingerprint added to Firebase Console: `FB:43:31:E2:4C:95:CF:3B:04:6C:98:75:BD:8A:49:74:45:E0:31:DF`
- [x] `google-services.json` placed in `android/app/`
- [x] `GoogleService-Info.plist` placed in `ios/Runner/`
- [x] Gradle files updated with Google Services plugin
- [x] Dependencies installed with `flutter pub get`
- [x] Code files updated (AuthService, LoginScreen)

---

## 🚀 Testing Steps

### Test 1: Build & Run the App

```bash
cd "c:\Users\Anil\Desktop\Study Planner\habit_tracker_app"
flutter clean
flutter pub get
flutter run
```

**Expected Result**:
- App launches successfully
- Login screen displays with gradient background
- "Sign in with Google" button visible
- No red error messages

**Console Output Should Show**:
```
✅ Successfully signed in: user@gmail.com
```

---

### Test 2: Test Successful Google Sign-In

1. **Tap "Sign in with Google"** button
2. **Select a Google account** (or add one)
3. **Grant OAuth permissions** if prompted
4. **Wait for authentication**

**Expected Result**:
- "Signing In..." text appears with loading indicator
- No errors shown
- Dashboard screen loads after 2-3 seconds
- User info displayed on dashboard

**Console Output**:
```
📱 Initiating Google Sign-In...
✅ Firebase authentication successful: user@gmail.com
🔍 Checking backend user...
👤 Creating new user in backend...
✅ User created successfully in backend
🚀 Navigating to dashboard...
```

---

### Test 3: Test Error Handling - Cancel Sign-In

1. **Tap "Sign in with Google"**
2. **Cancel** the account selection dialog
3. **Verify error handling**

**Expected Result**:
- Error message: "Sign-in cancelled by user"
- Error dialog appears
- User stays on login screen
- Can retry sign-in

---

### Test 4: Test Error Handling - Network Error

1. **Turn off WiFi/mobile data**
2. **Tap "Sign in with Google"**
3. **Wait for timeout/error**

**Expected Result**:
- Error message about network
- Error dialog displays
- User can enable network and retry

---

### Test 5: Verify Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **Habit Tracker App** project
3. Go to **Authentication** → **Users** tab
4. **Confirm your user appears** in the list

**Expected**:
- Your Google account email listed
- Sign-in timestamp shown
- Last login timestamp updated

---

### Test 6: Test Sign-Out (Optional)

*Requires dashboard sign-out button implementation*

1. **Sign in successfully**
2. **Navigate to Dashboard**
3. **Tap Sign Out button** (if available)
4. **Verify logged out**

**Expected Result**:
- Returns to login screen
- Can sign in again with different account

---

## 🔍 Troubleshooting Checklist

### If app crashes or won't start:
- [ ] Check Firebase initialization in console logs
- [ ] Verify `google-services.json` exists and is valid JSON
- [ ] Run `flutter pub get` again
- [ ] Try `flutter clean && flutter pub get`

### If Google Sign-In doesn't work:
- [ ] Verify SHA-1 fingerprint in Firebase Console
- [ ] Check that Google authentication provider is enabled
- [ ] Verify account selector dialog opens (Google bug if not)
- [ ] Check console logs for specific error codes

### If backend user creation fails:
- [ ] Check that FastAPI backend is running
- [ ] Verify API endpoint URL in `api_service.dart`
- [ ] Check backend logs for errors
- [ ] Verify user creation API endpoint exists

### If navigation to dashboard fails:
- [ ] Verify `DashboardScreen` is properly implemented
- [ ] Check that `User` model is complete
- [ ] Verify backend returns user object correctly

---

## 📊 Expected Console Logs

### Successful Sign-In:
```
📱 Initiating Google Sign-In...
✅ Firebase authentication successful: anil@gmail.com
🔍 Checking backend user...
👤 Creating new user in backend...
✅ User created successfully in backend
🚀 Navigating to dashboard...
```

### Cancelled Sign-In:
```
📱 Initiating Google Sign-In...
❌ Sign-in error: Sign-in cancelled by user
```

### Network Error:
```
📱 Initiating Google Sign-In...
❌ Sign-in error: Network error. Please check your connection
```

---

## 🎯 Success Indicators

✅ **Ready for Production When**:
- App launches without crashes
- Google Sign-In button works consistently
- All error scenarios handled gracefully
- User data syncs to backend
- Firebase Console shows authenticated users
- Dashboard displays after sign-in
- No console errors or exceptions

---

## 📝 Test Results Log

| Test | Status | Notes |
|------|--------|-------|
| App Build | ☐ | |
| Successful Sign-In | ☐ | |
| Error - Cancelled | ☐ | |
| Error - Network | ☐ | |
| Firebase Console | ☐ | |
| Sign-Out | ☐ | |

---

## 💡 Tips for Debugging

1. **Enable verbose logging**:
   ```bash
   flutter run -v
   ```

2. **Watch logs in real-time**:
   ```bash
   flutter logs
   ```

3. **Check Firebase Console**:
   - Monitor Authentication activity in real-time
   - Check error reporting
   - Review user list updates

4. **Test on Device**:
   - Use physical Android device for more reliable results
   - Emulators sometimes have Google Play Services issues

5. **Check Build Gradle**:
   - Verify `android/app/build.gradle.kts` has Google Services plugin
   - Verify `android/build.gradle.kts` has classpath dependency

---

## 🎉 Once Tests Pass

You're ready to:
1. ✅ Add more features (AI chat, notifications, etc.)
2. ✅ Deploy to production
3. ✅ Publish to Google Play Store
4. ✅ Publish to Apple App Store

**Next Feature**: Implement AI Chatbot Integration with Gemini API

---

*Created: April 2026*
*Project: Daily Habit Tracker - Firebase Setup*
