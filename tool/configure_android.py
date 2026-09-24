from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = root / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found. Run flutter create first.')

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


# Configure a custom deep link so Supabase email confirmations can return to the app.
deep_link_scheme = 'com.asmatworld.asmat_gk_quiz'
deep_link_host = 'login-callback'
if deep_link_scheme not in text:
    activity_close = text.find('</activity>')
    if activity_close == -1:
        raise SystemExit('Main activity closing tag not found in AndroidManifest.xml')
    deep_link = f'''
            <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="{deep_link_scheme}"
                    android:host="{deep_link_host}" />
            </intent-filter>
'''
    text = text[:activity_close] + deep_link + text[activity_close:]

manifest.write_text(text)
print('Android manifest configured with Supabase auth deep link (ads remain disabled for boot-stability).')
