from pathlib import Path
import os
import re

root = Path(__file__).resolve().parents[1]
manifest = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
gradle = root / "android" / "app" / "build.gradle.kts"
proguard = root / "android" / "app" / "proguard-rules.pro"

TEST_APP_ID = "ca-app-pub-3940256099942544~3347511713"
WORK_VERSION = "2.11.2"

mode = os.environ.get("ADMOB_MODE", "test").strip().lower()
real_app_id = os.environ.get("ADMOB_APP_ID", "").strip()

if mode == "production":
    if not real_app_id.startswith("ca-app-pub-") or "~" not in real_app_id:
        raise SystemExit("ADMOB_MODE=production but ADMOB_APP_ID is missing or invalid.")
    chosen_app_id = real_app_id
else:
    chosen_app_id = TEST_APP_ID

if not manifest.exists() or not gradle.exists():
    raise SystemExit("Android files not found. Run flutter create first.")

text = manifest.read_text()
text = text.replace('android:label="asmat_gk_quiz"', 'android:label="Asmat World GK Quiz"')

for permission in (
    '<uses-permission android:name="android.permission.INTERNET" />',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />',
):
    if permission not in text:
        manifest_open = text.find(">")
        text = text[:manifest_open + 1] + "\n    " + permission + text[manifest_open + 1:]

text = re.sub(
    r'\s*<meta-data\s+android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value="[^"]*"\s*/>',
    "",
    text,
    flags=re.MULTILINE,
)

app_start = text.find("<application")
app_open_end = text.find(">", app_start)
if app_start == -1 or app_open_end == -1:
    raise SystemExit("Application tag not found")

admob_meta = (
    '\n        <meta-data\n'
    '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
    f'            android:value="{chosen_app_id}" />'
)
text = text[:app_open_end + 1] + admob_meta + text[app_open_end + 1:]

scheme = "com.asmatworld.asmat_gk_quiz"
host = "login-callback"
if f'android:scheme="{scheme}"' not in text:
    activity_close = text.find("</activity>")
    if activity_close == -1:
        raise SystemExit("Main activity closing tag not found")
    deep_link = (
        '\n            <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />\n'
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.VIEW" />\n'
        '                <category android:name="android.intent.category.DEFAULT" />\n'
        '                <category android:name="android.intent.category.BROWSABLE" />\n'
        f'                <data android:scheme="{scheme}" android:host="{host}" />\n'
        '            </intent-filter>\n'
    )
    text = text[:activity_close] + deep_link + text[activity_close:]

manifest.write_text(text)

g = gradle.read_text()
dependency = f'implementation("androidx.work:work-runtime:{WORK_VERSION}")'
if dependency not in g:
    g += f'\n\ndependencies {{\n    {dependency}\n}}\n'

g = re.sub(r'isMinifyEnabled\s*=\s*true', 'isMinifyEnabled = false', g)
g = re.sub(r'isShrinkResources\s*=\s*true', 'isShrinkResources = false', g)

release_pos = g.find("release {")
if release_pos != -1:
    block_start = release_pos + len("release {")
    release_slice = g[block_start:block_start + 700]
    additions = ""
    if "isMinifyEnabled" not in release_slice:
        additions += "\n            isMinifyEnabled = false"
    if "isShrinkResources" not in release_slice:
        additions += "\n            isShrinkResources = false"
    if additions:
        g = g[:block_start] + additions + g[block_start:]

gradle.write_text(g)

proguard.write_text(
    """# WorkManager / Room reflection compatibility
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.work.InputMerger { *; }
"""
)

print("AdMob build mode:", mode)
print("Android AdMob App ID configured.")
print("WorkManager:", WORK_VERSION)
