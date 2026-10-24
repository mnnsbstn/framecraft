#!/usr/bin/env python3
"""Create/reuse a local FrameCraft code-signing key. Never changes trust settings."""
from pathlib import Path
import hashlib
import os
import re
import secrets
import subprocess
import sys
import tempfile

LABEL = 'FrameCraft Local Development'
DIRECTORY = Path.home() / 'Library/Application Support/FrameCraft/Signing'
PIN = DIRECTORY / 'identity.sha1'

def run(args):
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        # Never print arguments: security import receives a temporary PKCS#12 password.
        raise RuntimeError(Path(args[0]).name + ': ' + (result.stderr or result.stdout).strip())
    return result.stdout.strip()

def main():
    os.umask(0o077)
    DIRECTORY.mkdir(parents=True, exist_ok=True, mode=0o700)
    lock = DIRECTORY / '.setup-lock'
    lock.mkdir()
    try:
        keychain = run(['/usr/bin/security', 'default-keychain', '-d', 'user']).strip('"')
        if not Path(keychain).is_file():
            raise RuntimeError('Kein persönlicher Standardschlüsselbund vorhanden.')
        if PIN.exists():
            fingerprint = PIN.read_text().strip().upper()
            if not re.fullmatch(r'[A-F0-9]{40}', fingerprint):
                raise RuntimeError('Ungültige gespeicherte Signierungskennung; keine neue Identität erzeugt.')
        else:
            found = subprocess.run(['/usr/bin/security', 'find-certificate', '-a', '-c', LABEL, '-Z', keychain], text=True, capture_output=True)
            if found.returncode not in (0, 44):
                raise RuntimeError('Zertifikatsuche fehlgeschlagen; keine Identität erzeugt.')
            fingerprints = re.findall(r'SHA-1 hash: ([A-Fa-f0-9]{40})', found.stdout)
            if len(fingerprints) > 1:
                raise RuntimeError('Mehrere passende Zertifikate vorhanden; Auswahl erforderlich.')
            if fingerprints:
                fingerprint = fingerprints[0].upper()
            else:
                with tempfile.TemporaryDirectory(prefix='framecraft-signing-') as tmp:
                    temp = Path(tmp)
                    password = secrets.token_urlsafe(48)
                    (temp/'password').write_text(password+'\n')
                    (temp/'export-password').write_text(password+'\n')
                    (temp/'openssl.cnf').write_text('''[req]
prompt = no
distinguished_name = name
x509_extensions = signing
[name]
CN = FrameCraft Local Development
[signing]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
''')
                    run(['/usr/bin/openssl', 'req', '-new', '-x509', '-newkey', 'rsa:3072', '-sha256', '-days', '3650', '-config', str(temp/'openssl.cnf'), '-keyout', str(temp/'key.pem'), '-out', str(temp/'certificate.pem'), '-passout', 'file:'+str(temp/'password')])
                    run(['/usr/bin/openssl', 'x509', '-in', str(temp/'certificate.pem'), '-outform', 'DER', '-out', str(temp/'certificate.der')])
                    fingerprint = hashlib.sha1((temp/'certificate.der').read_bytes()).hexdigest().upper()
                    run(['/usr/bin/openssl', 'pkcs12', '-export', '-inkey', str(temp/'key.pem'), '-in', str(temp/'certificate.pem'), '-name', LABEL, '-out', str(temp/'identity.p12'), '-passin', 'file:'+str(temp/'password'), '-passout', 'file:'+str(temp/'export-password')])
                    run(['/usr/bin/security', 'import', str(temp/'identity.p12'), '-k', keychain, '-P', password, '-T', '/usr/bin/codesign'])
                    (DIRECTORY/'certificate.der').write_bytes((temp/'certificate.der').read_bytes())
        # Verify a real signature before persisting the selection. No trust-policy changes.
        with tempfile.TemporaryDirectory(prefix='framecraft-signing-check-') as tmp:
            temp = Path(tmp)
            (temp/'probe.c').write_text('int main(void) { return 0; }\n')
            run(['/usr/bin/xcrun', 'clang', str(temp/'probe.c'), '-o', str(temp/'probe')])
            run(['/usr/bin/codesign', '--force', '--sign', fingerprint, '--keychain', keychain, '--timestamp=none', '--identifier', 'local.sebastian.FrameCraft.signing-probe', str(temp/'probe')])
            run(['/usr/bin/codesign', '--verify', '--strict', str(temp/'probe')])
        staged = PIN.with_suffix('.tmp')
        staged.write_text(fingerprint+'\n')
        os.replace(staged, PIN)
        print('Feste lokale Signierungsidentität geprüft und gespeichert: '+fingerprint)
        print('Privater Schlüssel: persönlicher Schlüsselbund. Keine Vertrauenseinstellungen geändert.')
    finally:
        lock.rmdir()

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
