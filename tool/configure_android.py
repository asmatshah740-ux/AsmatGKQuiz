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
manifest.write_text(text)
print('Android manifest configured (ads disabled for boot-stability test).')
