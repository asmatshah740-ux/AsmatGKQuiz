# Asmat's World - GK Quiz (Starter Build)

This is the first runnable Flutter starter for the agreed app concept.

## Included now
- Splash: **Welcome To Asmat's World**
- Login/demo entry
- Daily home dashboard
- Exactly 60 General Knowledge questions
- 1 daily free hint after check-in
- Rewarded-ad placeholder for extra hints
- Interstitial-ad placeholder after every 3 questions (20 breaks across 60 questions)
- Score: +10 per correct answer
- Result screen
- Daily/Weekly/All-Time leaderboard UI
- Daily completion lock (local demo persistence)
- Profile screen
- Demo reset button for development/testing

## Run
If you have Flutter installed:

```bash
flutter create .
flutter pub get
flutter run
```

If `flutter create .` asks to overwrite files, keep the existing `lib/` and `pubspec.yaml` from this package.

## Next integration layer
The current build intentionally uses local/demo services so it runs before you provide cloud/ad credentials. Next we can connect:

1. Firebase Authentication
2. Firestore online question database
3. Server-authoritative scores + anti-cheat
4. Daily/weekly/all-time live leaderboard
5. Google Mobile Ads (real interstitial + rewarded)
6. Gemini/Groq backend for automatically preparing 60 daily GK questions
7. Admin panel and moderation/approval controls

**Important:** AI and ad API keys must stay on the backend, never inside the APK.
