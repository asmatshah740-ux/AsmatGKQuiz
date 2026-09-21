# FINAL SETUP - Mobile Friendly

This project is code-complete for the online architecture, but three external services must be connected before production use: Supabase, Gemini API, and AdMob.

## 1. Create a Supabase project

Create a free Supabase project. In the SQL Editor, run:

`supabase/migrations/001_final_schema.sql`

Then copy the project **URL** and **anon public key** from Supabase project settings.

## 2. Deploy the two Edge Functions

Deploy these folders as Supabase Edge Functions:

- `supabase/functions/generate-daily-quiz`
- `supabase/functions/claim-rewarded-hint`

Add a Supabase Edge Function secret named:

`GEMINI_API_KEY`

Use a Gemini API key from Google AI Studio. The AI key stays on the server and is never included in the APK.

## 3. Make your account the admin

First create your account inside the app. Then run this once in Supabase SQL Editor, replacing the email:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
```

## 4. Add GitHub repository secrets

In GitHub: Repository -> Settings -> Secrets and variables -> Actions -> New repository secret.

Required for online login/database:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Optional while testing ads (the project automatically uses Google's test ad units when these are missing):

- `ADMOB_APP_ID`
- `ADMOB_INTERSTITIAL_ID`
- `ADMOB_REWARDED_ID`

Do not use your real ads while repeatedly testing your own app.

## 5. Build APK

Push the project to GitHub. The included workflow **Build Final Android APK** will run automatically.

GitHub -> Actions -> Build Final Android APK -> latest run -> Artifacts -> `Asmat-World-GK-Quiz-Final-APK`.

## Daily question generation

The first signed-in user who opens the app each app day calls the protected `generate-daily-quiz` Edge Function. If today's 60 questions already exist, it reuses them. Otherwise the function generates and validates 60 new GK questions, checks recent duplicates, and publishes the set.

The app day is based on Pakistan Standard Time (`Asia/Karachi`).

## Anti-cheat design

The correct answer is not returned with the question list. The server verifies every answer in order, allows one answer per question and one attempt per day, computes points on the server, and excludes automatically flagged attempts from leaderboards. Admins can restrict suspicious accounts from the Admin Panel.

## Production note for rewarded ads

The current rewarded-hint flow uses AdMob's client reward callback plus a server rate limit. Before a large public launch, add AdMob Server-Side Verification (SSV) for the strongest protection against modified clients forging rewarded-ad callbacks.
