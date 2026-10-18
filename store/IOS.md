# iOS store build

Bundle id: `io.github.jp196400.holearcade`

Short version: 1.0.0

Build: 1

Minimum iOS: 14.0 (so the tracking prompt can appear)

There is no Mac in this setup. `.github/workflows/ios.yml` runs on a GitHub macOS runner when someone starts it by hand. A push to main does not start it. macOS minutes are billed, so leave it unstarted until you want the archive.

The workflow exports the Godot iOS project with **Export Project Only**, injects the plist keys below, and runs `xcodebuild archive` with `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO`. The artifact is an unsigned `.xcarchive`. It cannot be installed on a phone and it cannot be uploaded to App Store Connect.

## Codemagic alternative

Use Codemagic if you would rather not spend GitHub macOS minutes. Do not connect it until you mean to.

1. Create the Codemagic account yourself. This repo does not.
2. Add the Apple credentials listed in the signing section below.
3. Use a macOS workflow that checks out this repo, installs Godot 4.3 stable and the 4.3 export templates, sets `const STORE_BUILD := false` to `true` in `mobile_ids.gd`, exports the `iOS` preset, runs `python3 tools/inject_ios_plist.py build/ios ios/skadnetwork_ids.txt`, then archives with your signing identity.
4. Leave `.github/workflows/ios.yml` unstarted if Codemagic is doing the build.

## What signing needs from the Apple account

After the Apple Developer Program enrollment is approved:

| Item | Where it goes |
| --- | --- |
| Team ID | `application/app_store_team_id` in the iOS preset, or the Codemagic Apple account |
| Apple Distribution certificate | Keychain on the Mac that signs, or a Codemagic certificate |
| App ID for `io.github.jp196400.holearcade` | Identifiers in the developer account. Enable In-App Purchase. |
| App Store provisioning profile for that App ID | `application/provisioning_profile_uuid_release`, or Codemagic's profile field |
| App Store Connect app record | You create it. Bundle id must match. |
| App Store Connect API key (issuer id, key id, AuthKey .p8) | Upload tools or Codemagic. Transporter on a Mac can upload without the API key if you sign in. |

Then turn `application/export_project_only` off for the signed build, set the release code sign identity to `Apple Distribution`, and archive with the profile. Upload that IPA with Transporter, or with the App Store Connect API.

The first unsigned archive has not been built here. The workflow is ready to dispatch. Expect the first `xcodebuild` log to be the place that shows whether Godot's generated project accepts `CODE_SIGNING_ALLOWED=NO` without a team. If it demands a team, the fix is a signing identity from the account above, or the Codemagic path.

## ATT, AdMob, and SKAdNetwork

App Store privacy contact email: jpdarby@mail.grokbot.com. Use the same address on the privacy policy page and in App Store Connect.

`tools/inject_ios_plist.py` writes these into every exported `Info.plist`:

- `NSUserTrackingUsageDescription`: "Hole Arcade uses this to show more relevant ads. You can still play if you say no."
- `GADApplicationIdentifier`: Google's iOS sample app id `ca-app-pub-3940256099942544~1458002511` until a real AdMob app id exists. Override with the env var `ADMOB_IOS_APP_ID` on a later run.
- `SKAdNetworkItems`: the ids in `ios/skadnetwork_ids.txt`.

Those SKAdNetwork ids are the list from Google's AdMob iOS quick start, page updated 16 October 2026:

https://developers.google.com/admob/ios/quick-start

When you add a mediation partner, download Google's current list again and replace `ios/skadnetwork_ids.txt`. Missing ids mean those networks cannot attribute installs.

`ad_service.gd` asks an `AppTrackingTransparency`, `ATT`, `AdMob`, or `PoingGodotAdMob` singleton for `request_tracking_authorization` (or `requestTrackingAuthorization`) before ads. Godot has no built-in ATT call. The plist string is what iOS shows. The plugin is what presents the dialog. Drop that plugin in with the AdMob plugin on the signed build.

Test ad units in `mobile_ids.gd`:

| Use | Id |
| --- | --- |
| iOS app | ca-app-pub-3940256099942544~1458002511 |
| Interstitial | ca-app-pub-3940256099942544/4411468910 |
| Rewarded | ca-app-pub-3940256099942544/1712485313 |

There is no banner. A store build with no plugin does not show the placeholder card and does not grant a rewarded item or Remove Ads.

iOS billing still needs a StoreKit plugin that calls the same product id `hole_arcade_remove_ads`. The Play Billing hook does not run on iOS.
