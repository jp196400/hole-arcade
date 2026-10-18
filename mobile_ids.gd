extends RefCounted

# Android and iOS export workflows rewrite this to true on the runner.
# The GitHub Pages web build leaves it false, so tester mode and the
# test Remove Ads grant stay available there.
const STORE_BUILD := false

const APP_VERSION := "1.0.0"
const APP_BUILD := 1

const PRODUCT_REMOVE_ADS := "hole_arcade_remove_ads"
const REMOVE_ADS_PRICE := 2.99

const PRIVACY_URL := "https://jp196400.github.io/hole-arcade/privacy/"
const PRIVACY_EMAIL := "jpdarby@mail.grokbot.com"

# Official Google sample units. Swap these only after a real AdMob account exists.
const ADMOB_ANDROID_APP := "ca-app-pub-3940256099942544~3347511713"
const ADMOB_IOS_APP := "ca-app-pub-3940256099942544~1458002511"
const ADMOB_ANDROID_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"
const ADMOB_ANDROID_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const ADMOB_IOS_INTERSTITIAL := "ca-app-pub-3940256099942544/4411468910"
const ADMOB_IOS_REWARDED := "ca-app-pub-3940256099942544/1712485313"

static func interstitial_id() -> String:
	if OS.has_feature("ios"):
		return ADMOB_IOS_INTERSTITIAL
	return ADMOB_ANDROID_INTERSTITIAL

static func rewarded_id() -> String:
	if OS.has_feature("ios"):
		return ADMOB_IOS_REWARDED
	return ADMOB_ANDROID_REWARDED

static func app_id() -> String:
	if OS.has_feature("ios"):
		return ADMOB_IOS_APP
	return ADMOB_ANDROID_APP
