from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml").read_text()
gradle = Path("android/app/build.gradle.kts").read_text()

checks = {
    "test AdMob App ID": "ca-app-pub-3940256099942544~3347511713" in manifest,
    "single AdMob metadata": manifest.count("com.google.android.gms.ads.APPLICATION_ID") == 1,
    "WorkManager 2.11.2": 'implementation("androidx.work:work-runtime:2.11.2")' in gradle,
    "release minify disabled": "isMinifyEnabled = false" in gradle,
    "release resource shrinking disabled": "isShrinkResources = false" in gradle,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)

if failed:
    raise SystemExit("Android patch verification failed: " + ", ".join(failed))
