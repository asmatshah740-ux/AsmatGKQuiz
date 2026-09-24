from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
manifest = root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit("AndroidManifest.xml not found. Run flutter create first.")

TEST_APP_ID = "ca-app-pub-3940256099942544~3347511713"

text = manifest.read_text()
text = text.replace('android:label="asmat_gk_quiz"', 'android:label="Asmat World GK Quiz"')

permissions = [
    '<uses-permission android:name="android.permission.INTERNET" />',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />',
]
for permission in permissions:
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
    raise SystemExit("Application tag not found in AndroidManifest.xml")

admob_meta = (
    '\n        <meta-data\n'
    '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
    f'            android:value="{TEST_APP_ID}" />'
)
text = text[:app_open_end + 1] + admob_meta + text[app_open_end + 1:]

deep_link_scheme = "com.asmatworld.asmat_gk_quiz"
deep_link_host = "login-callback"
if f'android:scheme="{deep_link_scheme}"' not in text:
    activity_close = text.find("</activity>")
    if activity_close == -1:
        raise SystemExit("Main activity closing tag not found in AndroidManifest.xml")
    deep_link = (
        '\n            <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />\n'
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.VIEW" />\n'
        '                <category android:name="android.intent.category.DEFAULT" />\n'
        '                <category android:name="android.intent.category.BROWSABLE" />\n'
        f'                <data android:scheme="{deep_link_scheme}" android:host="{deep_link_host}" />\n'
        '            </intent-filter>\n'
    )
    text = text[:activity_close] + deep_link + text[activity_close:]

manifest.write_text(text)
print("Configured AndroidManifest.xml with official Google TEST AdMob App ID:", TEST_APP_ID)
