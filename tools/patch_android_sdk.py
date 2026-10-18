#!/usr/bin/env python3
"""Copy Godot's Android source template and aim it at API 36.

Godot 4.3 ships compileSdk 34 and Android Gradle Plugin 8.2.0. Google Play
requires target API 36, and API 36 needs Android Gradle Plugin 8.9.1 or newer
(Gradle 8.11.1). This patch only changes those version pins.
"""
import sys
import zipfile

REPLACEMENTS = {
    "androidGradlePlugin: '8.2.0'": "androidGradlePlugin: '8.9.1'",
    "compileSdk         : 34": "compileSdk         : 36",
    "targetSdk          : 34": "targetSdk          : 36",
    "buildTools         : '34.0.0'": "buildTools         : '36.0.0'",
    "gradle-8.2-bin.zip": "gradle-8.11.1-bin.zip",
}


def main():
    if len(sys.argv) != 3:
        print("usage: patch_android_sdk.py android_source.zip android_source_36.zip", file=sys.stderr)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    changed = {key: 0 for key in REPLACEMENTS}
    with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(dst, "w") as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            name = info.filename.replace("\\", "/")
            if name in ("config.gradle", "gradle/wrapper/gradle-wrapper.properties"):
                text = data.decode("utf-8")
                for old, new in REPLACEMENTS.items():
                    count = text.count(old)
                    if count:
                        text = text.replace(old, new)
                        changed[old] += count
                data = text.encode("utf-8")
            zout.writestr(info, data)
    missing = [old for old, count in changed.items() if count == 0]
    if missing:
        print("template patch missed: %s" % ", ".join(missing), file=sys.stderr)
        return 1
    print("patched %s" % dst)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
