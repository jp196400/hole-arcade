# Hole Arcade launch checklist

Stage 4 prep only. Nothing was paid for. No store account was created. Nothing was submitted or published. Ads use Google's sample ids. The GitHub Pages build stays the test build, with auto-start left on.

Checked 18 October 2026.

## Done

| Item | Evidence |
| --- | --- |
| Phone quality fallback | Phones and the web build start at 3D scale 1.0 with MSAA off, and climb only to 1.25 while the frame rate stays above 58. Under 55 fps the floor is scale 1.0, MSAA off, FXAA on. A desktop window starts at 1.25 with 2x MSAA. Locked showcase shots still use 1.5 and 4x MSAA. `preview=save` printed `QUALITY scale 1.25 msaa 1` on desktop and, with `HOLE_FORCE_PHONE=1`, `QUALITY scale 1.00 msaa 0`. Both printed `SAVE_OK`. |
| Save, progress, music, and SFX | The same preview wrote coins 4242, level 3, map 0 cleared, 2 stars, music off, and SFX off, then loaded that file back. Music and SFX toggles call `save_game()` immediately. |
| Version 1.0.0 (build 1) | Settings shows `Version 1.0.0 (build 1)`. `project.godot` `config/version` is 1.0.0. The Pages build still shows the short commit id under that line. Store exports hide the commit id. |
| App icon and splash | Original geometric art in `icons/`. Android legacy 48, 72, 96, 144, 192. Adaptive foreground and background 432. Play store 512. iOS 1024. Splash 720x1280 on the navy boot color. No characters and no third-party marks. |
| Store-build flag | `MobileIds.STORE_BUILD` is false in source, so Pages keeps tester mode and the test purchase. Android and iOS workflows rewrite it to true on the runner. A store build then refuses Remove Ads unless Play Billing returns a real purchase (`IAP_STORE_OK`, granted false). The web build still grants the test purchase (`IAP_WEB_OK`). Debug overlays stay behind `debug=1`, and that query is ignored when `STORE_BUILD` is true. |
| Privacy policy | `privacy/index.html` covers AdMob and mediation, the Remove Ads purchase, local saves, and no account. The Pages workflow copies it to `privacy/index.html` on the site. Contact line is the placeholder `privacy-contact@example.com`. |
| Android export preset | Preset `Android` writes `build/android/hole-arcade.aab`, package `io.github.jp196400.holearcade`, version code 1, version name 1.0.0, min SDK 24, target SDK 36, arm64-v8a, billing permission, adaptive icons. Keystore fields in git are empty. |
| Android workflow | `.github/workflows/android.yml` is `workflow_dispatch` only. It installs SDK 36, build-tools 36.0.0, and NDK 23.2.8568313, patches Godot 4.3's template to Android Gradle Plugin 8.9.1 and compileSdk 36, and signs with the upload keystore secrets. It fails with a message if a secret is missing. |
| iOS workflow | `.github/workflows/ios.yml` is `workflow_dispatch` only, on a macOS runner. It exports the Godot iOS project, injects the ATT string, the sample AdMob app id, and 50 SKAdNetwork ids, then archives with code signing disabled. Codemagic steps are in `store/IOS.md`. |
| Ad and billing hooks | Test ids only, in `mobile_ids.gd`. No banner. `ad_service.gd` calls an AdMob plugin when one is installed. `iap_service.gd` calls `GodotGooglePlayBilling` for `hole_arcade_remove_ads`. Store builds do not show the fake ad card and do not grant a reward or the purchase when the plugin is absent. |
| Store listing kit | `store/listing.md`, `store/ratings.md`, `store/privacy-answers.md`, `store/iap.md`, `store/ANDROID.md`, `store/IOS.md`. Short description is 58 characters (limit 80). Subtitle is 25 (limit 30). Promo text is 67 (limit 170). Keywords are 59 (limit 100). |
| Screenshots | Real gameplay frames from Farm Valley, Candy Town, Dino Jungle, Desert Oasis, and Space Colony. Play phone `store/screenshots/play-*-1080x1920.png`. iPhone 6.7 inch `ios67-*-1290x2796.png`. iPhone 6.5 inch `ios65-*-1284x2778.png`. Feature graphic `store/screenshots/feature-1024x500.png` is a Farm Valley crop plus the title in the game font. |
| Remove Ads spec | Non-consumable, $2.99, product id `hole_arcade_remove_ads`. Turns interstitials off. Rewarded ads stay optional. |

## In progress

| Item | What is left |
| --- | --- |
| Signed Android AAB | The workflow has not been dispatched. The first run is the proof that Android Gradle Plugin 8.9.1 accepts Godot 4.3's build files. It cannot succeed until the upload-key secrets exist. |
| Unsigned iOS archive | The macOS workflow has not been dispatched. GitHub bills macOS minutes, so it stays manual. The first `xcodebuild` log will show whether the generated project accepts an unsigned archive. |

## Needs John-paul

| Item | What to do |
| --- | --- |
| Google Play Console account | US$25, one time, as of 18 October 2026. https://support.google.com/googleplay/android-developer/answer/6112435 Google asks for a government id and a payment card in the legal name. The fee is not returned if verification fails. |
| Play closed testing | A personal account created after 13 November 2023 must have at least 12 testers opted in for 14 consecutive days before production access. Internal testing does not count. https://support.google.com/googleplay/android-developer/answer/14151465 Google's public page still states 12 testers and 14 days. |
| Apple Developer Program | US$99 per year, as of 18 October 2026. https://developer.apple.com/programs/ Enrollment includes identity checks. The $299 enterprise program is a different program and is not how this game goes on the App Store. |
| AdMob | Create the account, then replace the sample app ids and ad unit ids in `mobile_ids.gd`. Add the Android and iOS ad plugins. Refresh `ios/skadnetwork_ids.txt` when a mediation partner is added. Source list: https://developers.google.com/admob/ios/quick-start (page updated 16 October 2026). |
| Payments, payout, and tax | Play Console and App Store Connect each need a payout profile and a tax profile before they will pay out. |
| Upload key | Run `tools/make_upload_keystore.sh` once, on your own machine. Add `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` as Actions secrets. Keep a backup. See `store/ANDROID.md`. |
| Apple signing | Team ID, Apple Distribution certificate, App ID `io.github.jp196400.holearcade` with In-App Purchase, and an App Store provisioning profile. Then a signed archive. See `store/IOS.md`. |
| Privacy contact | Replace `privacy-contact@example.com` in `privacy/index.html` and `mobile_ids.gd` before submission. That address is a placeholder and is not a monitored mailbox. |
| Store products and forms | Create the non-consumable `hole_arcade_remove_ads` at $2.99 in both consoles. Paste `store/ratings.md` and `store/privacy-answers.md` into the questionnaires. The forms have not been submitted, so no age rating is granted yet. |
| Device frame-rate check | The fallback is in the build. This environment has no ~2020 phone. A software GL capture ran around 15 fps, which is the capture machine, not the target. Confirm about 60 fps on a real mid-range phone after the first internal build. |
| Target API reference | New Play apps and updates must target Android 16, API 36, as of 31 August 2026. https://support.google.com/googleplay/android-developer/answer/11926878 The preset and the template patch both set 36. API 36 needs Android Gradle Plugin 8.9.1 or newer. https://developer.android.com/build/releases/about-agp |
