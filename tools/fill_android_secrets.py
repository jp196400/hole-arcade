#!/usr/bin/env python3
"""Point the Android export preset at the CI upload keystore and patched template.

Reads ANDROID_KEYSTORE_PATH, ANDROID_KEY_ALIAS, ANDROID_KEYSTORE_PASSWORD,
ANDROID_KEY_PASSWORD, and ANDROID_SOURCE_TEMPLATE from the environment.
Passwords are written into export_presets.cfg on the runner only.
"""
import os
import sys


def cfg_quote(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "export_presets.cfg"
    fields = {
        "keystore/release": os.environ["ANDROID_KEYSTORE_PATH"],
        "keystore/release_user": os.environ["ANDROID_KEY_ALIAS"],
        "keystore/release_password": os.environ["ANDROID_KEYSTORE_PASSWORD"],
        "gradle_build/android_source_template": os.environ["ANDROID_SOURCE_TEMPLATE"],
    }
    # Godot signs with the release password. The key password is the same
    # secret when the keystore was created with one password for both.
    key_password = os.environ.get("ANDROID_KEY_PASSWORD", "")
    if key_password and key_password != os.environ["ANDROID_KEYSTORE_PASSWORD"]:
        print("Godot 4.3 uses keystore/release_password for the key.", file=sys.stderr)
        print("Create the upload key with the same store and key password,", file=sys.stderr)
        print("or see store/ANDROID.md.", file=sys.stderr)
        return 1
    text = open(path, encoding="utf-8").read()
    for key, value in fields.items():
        needle = key + "="
        found = False
        lines = []
        for line in text.splitlines():
            if line.startswith(needle):
                lines.append(needle + cfg_quote(value))
                found = True
            else:
                lines.append(line)
        if not found:
            print("missing preset key %s" % key, file=sys.stderr)
            return 1
        text = "\n".join(lines) + "\n"
    open(path, "w", encoding="utf-8").write(text)
    print("android preset updated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
