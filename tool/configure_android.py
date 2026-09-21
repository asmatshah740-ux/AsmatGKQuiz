from pathlib import Path
import os
import re

root = Path(__file__).resolve().parents[1]
manifest = root / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found. Run flutter create first.')

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
if 'com.google.android.gms.ads.APPLICATION_ID' not in text:
    marker = '<application'
    start = text.find(marker)
    close = text.find('>', start)
    if start == -1 or close == -1:
        raise SystemExit('Application tag not found in AndroidManifest.xml')
    insertion = f'''\n        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="{app_id}" />'''
    # place immediately after opening application tag so it remains inside application
    text = text[:close+1] + insertion + text[close+1:]

manifest.write_text(text)
print('Android manifest configured for AdMob app id:', app_id)
