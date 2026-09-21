# Build APK using only an Android phone

This project includes a GitHub Actions workflow that builds the APK in the cloud.

1. Create a new empty GitHub repository, for example `AsmatGKQuiz`.
2. In Termux, install tools:
   `pkg update && pkg install git unzip -y`
3. Give Termux storage access:
   `termux-setup-storage`
4. Extract the downloaded ZIP into a folder in Downloads.
5. Open the project folder in Termux and initialize Git:
   `git init`
   `git branch -M main`
   `git add .`
   `git commit -m "Initial Asmat GK Quiz app"`
6. Add your GitHub repository URL and push:
   `git remote add origin https://github.com/YOUR_USERNAME/AsmatGKQuiz.git`
   `git push -u origin main`
7. Open the repository on GitHub > Actions > Build Android APK.
8. Open the latest successful run and download the `Asmat-GK-Quiz-APK` artifact.
9. Extract the artifact ZIP and install `app-release.apk` on your Android phone.

Note: This is the demo build. Firebase, real AdMob ads, AI-generated daily questions, and server-side anti-cheat are not connected yet.
