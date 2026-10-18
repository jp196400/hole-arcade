# Android store build

Package name: `io.github.jp196400.holearcade`

Version name: 1.0.0

Version code: 1

Minimum SDK: 24

Target SDK: 36

Checked 18 October 2026 against Google's target API policy. New apps and updates must target Android 16 (API 36) as of 31 August 2026.

https://support.google.com/googleplay/android-developer/answer/11926878

https://developer.android.com/google/play/requirements/target-sdk

The export preset is `Android` in `export_presets.cfg`. It builds an AAB (`gradle_build/export_format=1`) for `arm64-v8a` only. Release keystore fields in the committed file are empty on purpose.

## What you add before the first AAB

Run `tools/make_upload_keystore.sh` once on your own computer. Use the same password for the store and the key. Godot 4.3 has a single release password field. Do not commit the `.keystore` file. Do not upload it as a workflow artifact.

GitHub Actions secrets on this repository:

| Secret | Value |
| --- | --- |
| ANDROID_KEYSTORE_BASE64 | The keystore file, base64, one line |
| ANDROID_KEYSTORE_PASSWORD | The store password |
| ANDROID_KEY_ALIAS | `holearcade`, unless you passed another alias |
| ANDROID_KEY_PASSWORD | The same password as the store |

Then run the **Android signed AAB** workflow by hand (Actions, workflow_dispatch). A push to main does not run it. The job stops with a clear message if a secret is missing.

Back up the keystore. Play App Signing can replace an upload key later, and that replacement waits on Google.

## API 36 and the Godot 4.3 template

Godot 4.3's Android template compiles with SDK 34 and Android Gradle Plugin 8.2.0. API 36 needs Android Gradle Plugin 8.9.1 or newer and Gradle 8.11.1.

https://developer.android.com/build/releases/about-agp

`tools/patch_android_sdk.py` copies the template and sets:

- Android Gradle Plugin 8.9.1
- compileSdk 36
- targetSdk 36
- build tools 36.0.0
- Gradle wrapper 8.11.1

The native Godot library stays the 4.3 AAR. The NDK pin stays 23.2.8568313, which is the NDK that AAR was built with. The first gradle run is the proof that AGP 8.9.1 accepts Godot 4.3's build files. If it rejects them, the log is the next fix. That run has not been started, because the keystore secrets are not in GitHub yet.

The workflow installs platforms;android-36, build-tools;36.0.0, and that NDK. Java is Temurin 17.

## Ads and billing hooks

Test ids only, in `mobile_ids.gd`:

| Use | Id |
| --- | --- |
| Android app | ca-app-pub-3940256099942544~3347511713 |
| Interstitial | ca-app-pub-3940256099942544/1033173712 |
| Rewarded | ca-app-pub-3940256099942544/5224354917 |

`ad_service.gd` calls a plugin singleton named `AdMob` or `PoingGodotAdMob` when it is installed (`initialize`, then `load_interstitial` / `show_interstitial`, or the rewarded pair). `iap_service.gd` calls `GodotGooglePlayBilling` (`startConnection`, `queryPurchases`, `purchase`, `acknowledgePurchase`) for product id `hole_arcade_remove_ads`.

Drop the plugin `.aar` and `.gdap` into `android/plugins/` on a later branch, then turn the matching `plugins/<name>` export option on. This repo does not vendor Google's SDK binaries. There is no banner.

The workflow sets `MobileIds.STORE_BUILD` to true only on the runner. If the plugin is missing, a store build does not show the fake ad card and does not grant Remove Ads. The Pages web build leaves `STORE_BUILD` false.

The preset requests `INTERNET`, `ACCESS_NETWORK_STATE`, and `com.android.vending.BILLING`.

## Editor paths the workflow writes

Godot reads the SDK from editor settings, not only from `ANDROID_HOME`. The workflow writes `~/.config/godot/editor_settings-4.3.tres` with `export/android/android_sdk_path` and `export/android/java_sdk_path`.

The Pages workflow is unchanged aside from copying the privacy page, and it checks that `STORE_BUILD` is still false.
