"""Minimal App Store Connect API client.

Reads the key ID and issuer ID from ASC_KEY_ID and ASC_ISSUER_ID, and the key itself from
~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8 (where Xcode and altool look too).
"""
import json
import os
import time
import urllib.error
import urllib.request

import jwt

APP_ID = '6814702992'


def _token():
    key_id = os.environ['ASC_KEY_ID']
    path = os.path.expanduser(f'~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8')
    now = int(time.time())
    return jwt.encode(
        {'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 1200, 'aud': 'appstoreconnect-v1'},
        open(path).read(),
        algorithm='ES256',
        headers={'kid': key_id, 'typ': 'JWT'},
    )


def call(method, path, body=None):
    request = urllib.request.Request(
        'https://api.appstoreconnect.apple.com' + path,
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={'Authorization': 'Bearer ' + _token(), 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(request) as response:
            text = response.read()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as error:
        raise SystemExit(f'{method} {path} failed with {error.code}: {error.read().decode()}')
