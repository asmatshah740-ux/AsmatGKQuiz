from pathlib import Path
import os

root = Path(__file__).resolve().parents[1]
manifest = root / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found. Run flutter create first.')

# If no real AdMob App ID secret exists, use Google's official Android test App ID.
app_id = os.environ.get('ADMOB_APP_ID', '').strip() or 'ca-app-pub-3940256099942544~3347511713'
text = manifest.read_text()
text = text.replace('android:label="asmat_gk_quiz"', 'android:label="Asmat World GK Quiz"')

permissions = [
    '<uses-permission android:name="android.permission.INTERNET" />',
    '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />',
]
for permission in permissions:
    if permission not in text:
        pos = text.find('>') + 1
        text = text[:pos] + '\n    ' + permission + text[pos:]

# AdMob App ID metadata must exist inside <application> or Android can crash at startup.
if 'com.google.android.gms.ads.APPLICATION_ID' not in text:
    start = text.find('<application')
    close = text.find('>', start)
    if start == -1 or close == -1:
        raise SystemExit('Application tag not found in AndroidManifest.xml')
    insertion = f'''\n        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="{app_id}" />'''
    text = text[:close + 1] + insertion + text[close + 1:]

# Supabase email confirmation deep link.
deep_link_scheme = 'com.asmatworld.asmat_gk_quiz'
deep_link_host = 'login-callback'
if f'android:scheme="{deep_link_scheme}"' not in text:
    activity_close = text.find('</activity>')
    if activity_close == -1:
        raise SystemExit('Main activity closing tag not found in AndroidManifest.xml')
    deep_link = f'''\n            <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />\n            <intent-filter>\n                <action android:name="android.intent.action.VIEW" />\n                <category android:name="android.intent.category.DEFAULT" />\n                <category android:name="android.intent.category.BROWSABLE" />\n                <data\n                    android:scheme="{deep_link_scheme}"\n                    android:host="{deep_link_host}" />\n            </intent-filter>\n'''
    text = text[:activity_close] + deep_link + text[activity_close:]

manifest.write_text(text)
print('Android manifest configured for Supabase deep link and AdMob app id:', app_id)
