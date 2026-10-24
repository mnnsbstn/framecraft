#!/usr/bin/env python3
"""Exercise native signing across changed executables and reject impostors."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import tempfile

def run(args, success=True):
    p = subprocess.run(args, text=True, capture_output=True)
    if success and p.returncode:
        raise RuntimeError(p.stderr)
    return p

def requirement(path):
    p=run(['/usr/bin/codesign','--display','-r-',str(path)])
    return re.search(r'(?:# )?designated => (.+)',p.stdout+p.stderr).group(1)

def main():
    pin=Path.home()/'Library/Application Support/FrameCraft/Signing/identity.sha1'
    identity=pin.read_text().strip()
    assert re.fullmatch(r'[A-Fa-f0-9]{40}',identity)
    with tempfile.TemporaryDirectory(prefix='framecraft-continuity-') as directory:
        root=Path(directory)
        for name,code in [('a',0),('b',7),('impostor',42)]:
            (root/(name+'.c')).write_text('int main(void) { return '+str(code)+'; }\n')
            run(['/usr/bin/xcrun','clang',str(root/(name+'.c')),'-o',str(root/name)])
            run(['/usr/bin/codesign','--force','--sign',identity if name!='impostor' else '-', '--timestamp=none','--identifier','local.sebastian.FrameCraft.signing-probe',str(root/name)])
        a,b=requirement(root/'a'),requirement(root/'b')
        assert a==b and 'cdhash' not in a and 'identifier' in a and ('anchor' in a or 'certificate' in a)
        assert hashlib.sha256((root/'a').read_bytes()).digest()!=hashlib.sha256((root/'b').read_bytes()).digest()
        run(['/usr/bin/codesign','--verify','--strict','-R','='+a,str(root/'b')])
        run(['/usr/bin/codesign','--verify','--strict','-R','='+b,str(root/'a')])
        assert run(['/usr/bin/codesign','--verify','--strict','-R','='+a,str(root/'impostor')],False).returncode!=0
        data=bytearray((root/'b').read_bytes()); data[4096]^=1; (root/'b').write_bytes(data)
        assert run(['/usr/bin/codesign','--verify','--strict',str(root/'b')],False).returncode!=0
        print(json.dumps({'certificate_sha1':identity,'different_executables':True,'mutually_compatible_requirements':True,'same_identifier_adhoc_impostor_rejected':True,'tampering_rejected':True,'designated_requirement':a},indent=2))

if __name__=='__main__': main()
