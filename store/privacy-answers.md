# Data safety and privacy nutrition answers

These match the privacy policy at https://jp196400.github.io/hole-arcade/privacy/ and the ad and purchase hooks in the repo. Test ad ids are in `mobile_ids.gd`. Paste the answers into the consoles. Do not invent extra collection.

The app does not have its own server. Progress stays on the device.

## Google Play Data safety

| Question | Answer |
| --- | --- |
| Does the app collect or share any of the required user data types? | Yes |
| Is all of the user data collected by the app encrypted in transit? | Yes. AdMob and Google Play Billing use HTTPS. Hole Arcade has no player-data server of its own. |
| Do you provide a way for users to request that their data be deleted? | Yes. Local progress is deleted by clearing app storage. Ad data is deleted through Google's ad settings. There is no Hole Arcade account to delete. |
| Data sold | No |

Data types:

| Type | Collected | Shared | Purpose | Optional |
| --- | --- | --- | --- | --- |
| Device or other IDs (advertising id) | Yes, by the AdMob SDK | Yes, with Google AdMob and mediation partners | Advertising | The game runs if the player buys Remove Ads. Rewarded ads stay optional. Tracking on iOS requires the ATT prompt. |
| Purchase history | Yes, through Google Play Billing for Remove Ads | Shared with Google as the payment processor | App functionality | The purchase itself is optional |
| Name, email, phone, address | No | No |  |  |
| Precise location | No | No |  |  |
| Coarse location | Only if AdMob derives it from the IP address. Declare it if the Data safety form treats the ad SDK's IP-based location as coarse location collected by the app. | With AdMob | Advertising |  |
| Photos, contacts, messages, files | No | No |  |  |
| App activity and game progress | No. Stays on the device. Do not declare it as collected. | No |  |  |
| Crash logs or diagnostics sent to us | No | No |  |  |

Account creation: the app does not allow account creation.

## Apple privacy nutrition label

| Category | Used to track you | Linked to the user | Not linked to the user | Purpose |
| --- | --- | --- | --- | --- |
| Identifiers, Device ID | Yes, if the player allows tracking. AdMob may use the advertising id. | Yes when tracking is allowed |  | Third-party advertising |
| Purchases, Purchase History | No | Yes, via the Apple ID receipt for Remove Ads |  | App functionality |
| Contact info, location, contacts, user content, search history, browsing history, health, financial info beyond the store receipt | No | No | No | Not collected by Hole Arcade |
| Game progress | No | No | No | Local save only. Do not list it. |

Tracking declaration: the app requests App Tracking Transparency. The prompt text is "Hole Arcade uses this to show more relevant ads. You can still play if you say no." If the player refuses, the game still runs.

Privacy policy URL for both stores: https://jp196400.github.io/hole-arcade/privacy/

## Privacy contact

| Form | Field | Value |
| --- | --- | --- |
| Google Play Data safety | Contact email | jpdarby@mail.grokbot.com |
| App Store privacy | Privacy contact email | jpdarby@mail.grokbot.com |

The same address is the contact on the privacy policy page.
