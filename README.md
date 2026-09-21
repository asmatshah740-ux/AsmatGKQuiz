# Asmat's World - GK Quiz (Final Online Architecture)

A Flutter Android app for a daily online General Knowledge quiz.

## Final feature set

- Opening splash: **Welcome To Asmat's World**
- Real email/password signup and login (Supabase Auth)
- 60 fresh online GK questions per app day
- Only one 60-question attempt per user per day
- Continue Quiz resumes the server-side current question
- Interstitial ad opportunity after every 3 answered questions (20 across 60 questions)
- Daily check-in gives +1 free hint
- Extra hint through optional rewarded ad
- Hints Available counter on Home and Quiz screens
- Daily / Weekly / All-Time leaderboard
- My Stats, Check-in History and Settings
- Protected Admin Panel for question editing, AI regeneration and user restrictions
- Server-authoritative scoring and answer validation
- Duplicate answer protection, sequence validation and suspicious-speed flagging
- AI question generation through a Supabase Edge Function using Gemini
- No demo login, no reset demo, no fake leaderboard and no local fake quiz data

## Important

The APK can compile before cloud secrets are added, but it will show **Online Setup Required** until Supabase is configured. Real AdMob IDs should only be added after testing with Google's test ads.

See **FINAL_SETUP.md** for the exact mobile-friendly setup sequence.
