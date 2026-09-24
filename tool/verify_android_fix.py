from pathlib import Path
import os
import re

manifest = Path("android/app/src/main/AndroidManifest.xml").read_text()
gradle = Path("android/app/build.gradle.kts").read_text()

mode = os.environ.get("ADMOB_MODE", "test").strip().lower()
expected = (
    os.environ.get("ADMOB_APP_ID", "").strip()
    if mode == "production"
    else "ca-app-pub-3940256099942544~3347511713"
)

m = re.search(
    r'android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value="([^"]+)"',
    manifest,
    re.MULTILINE,
)
actual = m.group(1) if m else ""

checks = {
    "AdMob App ID": actual == expected and bool(actual),
    "single AdMob metadata": manifest.count("com.google.android.gms.ads.APPLICATION_ID") == 1,
    "WorkManager 2.11.2": 'implementation("androidx.work:work-runtime:2.11.2")' in gradle,
    "release minify disabled": "isMinifyEnabled = false" in gradle,
    "release resource shrinking disabled": "isShrinkResources = false" in gradle,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)

print("AdMob mode:", mode)

if failed:
    raise SystemExit("Android config verification failed: " + ", ".join(failed))
