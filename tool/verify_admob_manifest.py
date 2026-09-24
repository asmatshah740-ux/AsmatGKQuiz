from pathlib import Path
import re

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text()
expected = "ca-app-pub-3940256099942544~3347511713"

m = re.search(
    r'android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value="([^"]+)"',
    text,
    re.MULTILINE,
)
if not m:
    raise SystemExit("FAIL: AdMob APPLICATION_ID metadata is missing.")

actual = m.group(1)
if actual != expected:
    raise SystemExit(f"FAIL: Wrong AdMob TEST App ID: {actual}")

if text.count("com.google.android.gms.ads.APPLICATION_ID") != 1:
    raise SystemExit("FAIL: Duplicate AdMob APPLICATION_ID metadata found.")

print("PASS: AdMob TEST App ID is present exactly once:", actual)
