#!/usr/bin/env python3
"""Add the AdMob app id, the ATT prompt, and SKAdNetwork IDs to exported Info.plist files.

The app id defaults to Google's iOS sample id. Pass a real id only after AdMob exists.
"""
import os
import sys
import plistlib

DEFAULT_APP = "ca-app-pub-3940256099942544~1458002511"
ATT = "Hole Arcade uses this to show more relevant ads. You can still play if you say no."


def load_ids(path):
    ids = []
    for line in open(path, encoding="utf-8"):
        item = line.strip()
        if item and not item.startswith("#"):
            ids.append(item)
    return ids


def patch(plist_path, app_id, skad_ids):
    with open(plist_path, "rb") as handle:
        data = plistlib.load(handle)
    data["GADApplicationIdentifier"] = app_id
    data["NSUserTrackingUsageDescription"] = ATT
    items = []
    for skad in skad_ids:
        items.append({"SKAdNetworkIdentifier": skad})
    data["SKAdNetworkItems"] = items
    with open(plist_path, "wb") as handle:
        plistlib.dump(data, handle)
    print("patched %s (%d SKAdNetwork ids)" % (plist_path, len(items)))


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "build/ios"
    ids_path = sys.argv[2] if len(sys.argv) > 2 else "ios/skadnetwork_ids.txt"
    app_id = os.environ.get("ADMOB_IOS_APP_ID", DEFAULT_APP)
    skad_ids = load_ids(ids_path)
    if len(skad_ids) < 40:
        print("SKAdNetwork list looks short: %d" % len(skad_ids), file=sys.stderr)
        return 1
    found = 0
    for dirpath, _dirs, files in os.walk(root):
        if "Info.plist" in files and not dirpath.endswith(".xcarchive"):
            patch(os.path.join(dirpath, "Info.plist"), app_id, skad_ids)
            found += 1
    if found == 0:
        print("no Info.plist under %s" % root, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
