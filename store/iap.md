# Remove Ads

| Field | Value |
| --- | --- |
| Product name | Remove Ads |
| Product id | hole_arcade_remove_ads |
| Type | Non-consumable |
| Price | $2.99 USD |
| Entitlement | Turns interstitial ads off. Rewarded ads stay optional. |
| Where it is stored | On the device, in the local save (`no_ads`). |
| Android | Google Play Billing, product id `hole_arcade_remove_ads`. The GodotGooglePlayBilling singleton is the hook in `iap_service.gd`. |
| iOS | Apple In-App Purchase, same product id, non-consumable. A StoreKit plugin is still required before a signed iOS build can charge. Until that plugin is present, a store build does not grant Remove Ads. |
| Web test build | The GitHub Pages build grants the flag with no charge, and the shop says so. `MobileIds.STORE_BUILD` is false there. |
| Store builds | `STORE_BUILD` is set true by the Android and iOS workflows. With no billing plugin, the button does not grant the item. |

Create the product in Play Console and App Store Connect with this exact id before a production submit. Do not create it from this repo.
