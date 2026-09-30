"""Replace the App Store screenshots on the version being prepared.

    python upload.py            # the version in Prepare for Submission
    python upload.py 1.1        # a specific version

Deletes the existing iPhone 6.9" and iPad 13" screenshots for the primary locale, then uploads
build/store-screenshots/out/{phone,pad}-*.png in file-name order.
"""
import glob
import hashlib
import os
import sys
import urllib.request

from asc import APP_ID, call

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = f'{ROOT}/build/store-screenshots/out'
SETS = {'phone': 'APP_IPHONE_67', 'pad': 'APP_IPAD_PRO_3GEN_129'}


def version(wanted):
    versions = call('GET', f'/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS')['data']
    for candidate in versions:
        attributes = candidate['attributes']
        if wanted and attributes['versionString'] == wanted:
            return candidate
        if not wanted and attributes['appVersionState'] == 'PREPARE_FOR_SUBMISSION':
            return candidate
    raise SystemExit(f'No version {wanted or "in Prepare for Submission"} found')


def localization(version_id):
    locale = call('GET', f'/v1/apps/{APP_ID}')['data']['attributes']['primaryLocale']
    localizations = call('GET', f'/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations')
    for candidate in localizations['data']:
        if candidate['attributes']['locale'] == locale:
            return candidate['id']
    raise SystemExit(f'No {locale} localization on this version')


def screenshot_set(localization_id, display):
    sets = call('GET', f'/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets')
    for candidate in sets['data']:
        if candidate['attributes']['screenshotDisplayType'] == display:
            for shot in call('GET', f"/v1/appScreenshotSets/{candidate['id']}/appScreenshots")['data']:
                call('DELETE', f"/v1/appScreenshots/{shot['id']}")
            return candidate['id']
    created = call('POST', '/v1/appScreenshotSets', {'data': {
        'type': 'appScreenshotSets',
        'attributes': {'screenshotDisplayType': display},
        'relationships': {'appStoreVersionLocalization': {
            'data': {'type': 'appStoreVersionLocalizations', 'id': localization_id}}},
    }})
    return created['data']['id']


def upload(set_id, path):
    data = open(path, 'rb').read()
    reserved = call('POST', '/v1/appScreenshots', {'data': {
        'type': 'appScreenshots',
        'attributes': {'fileName': os.path.basename(path), 'fileSize': len(data)},
        'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}},
    }})['data']
    for operation in reserved['attributes']['uploadOperations']:
        chunk = data[operation['offset']:operation['offset'] + operation['length']]
        headers = {header['name']: header['value'] for header in operation['requestHeaders']}
        request = urllib.request.Request(operation['url'], data=chunk, method=operation['method'], headers=headers)
        urllib.request.urlopen(request).read()
    call('PATCH', f"/v1/appScreenshots/{reserved['id']}", {'data': {
        'type': 'appScreenshots',
        'id': reserved['id'],
        'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()},
    }})


if __name__ == '__main__':
    target = version(sys.argv[1] if len(sys.argv) > 1 else None)
    print('Version', target['attributes']['versionString'])
    localization_id = localization(target['id'])
    for kind, display in SETS.items():
        files = sorted(glob.glob(f'{OUT}/{kind}-*.png'))
        if not files:
            raise SystemExit(f'No {kind} screenshots in {OUT}; run compose.py first')
        set_id = screenshot_set(localization_id, display)
        for path in files:
            upload(set_id, path)
            print('Uploaded', os.path.basename(path))
