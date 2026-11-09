# ChickenCoops.ai app

The native iPhone and Android app for chickencoops.ai. It is a Capacitor app: the site runs
in a web view inside a real native shell with a native bottom tab bar (Home, Plan, Reels,
Community, Chat), native onboarding, haptics, an offline screen, pull to refresh, home
screen quick actions and a "Daily coop tip" home screen widget on iPhone.

This build (version 2.0.0) replaces the old webtonative build of the live App Store app.
It must ship under the SAME bundle id as the live app so it installs as an update.

Version 2.0.0, build 200. Building on a Mac: see `BUILD-GUIDE.md`.

## Where every setting lives

| What | File |
| --- | --- |
| Start page, site host, tabs, colors, onboarding text, offline text, OneSignal id | `www/app.json` |
| App id, app name, allowed hosts, user agent (`ChickenCoopsApp/1.0`), splash color | `capacitor.config.json` |
| iPhone name, quick actions, camera and mic wording | `ios/App/App/Info.plist` |
| iPhone version and build number, bundle id | `ios/App/App.xcodeproj/project.pbxproj` |
| iPhone capabilities (push, Associated Domains, Sign in with Apple) | `ios/App/App/App.entitlements` |
| iPhone widget | `ios/App/CoopWidget/CoopWidget.swift` |
| What the site can ask the app to do (JS name `CoopApp`) | `ios/App/App/CoopAppPlugin.swift`, `android/app/src/main/java/ai/chickencoops/app/CoopAppPlugin.java` |
| Android version, app id | `android/app/build.gradle` |
| Android name, quick actions | `android/app/src/main/res/values/strings.xml`, `android/app/src/main/res/xml/shortcuts.xml` |
| Signed iPhone builds | `codemagic.yaml` |
| Icons and splash | `scripts/make-art.py` (see Icons below) |

After changing `www/app.json` or `capacitor.config.json`, run `npx cap sync` and build again.

## Bundle id

The iPhone app uses the live App Store app's bundle id `coop.chickencoops.ai` (App Store name "Coopai", Apple ID 6797082651). The widget is `coop.chickencoops.ai.CoopWidget`. It is set in:

- `ios/App/App.xcodeproj/project.pbxproj` (app and widget, Debug and Release)
- `codemagic.yaml` (`bundle_identifier`, plus `APP_STORE_APPLE_ID: "6797082651"`)
- `capacitor.config.json` (`appId`)
- `scripts/add-widget-target.rb`

Android still uses `ai.chickencoops.app` (there is no Play Store app yet). Change `applicationId` in `android/app/build.gradle`, `res/xml/shortcuts.xml` and `res/values/strings.xml` if a Play Store app is made with a different id.

## Purchases in the app

The site hides upgrades, plan pages and checkout inside the app (chickencoops-tools 1.6.4 checks the `ChickenCoopsApp` user agent), so the app sells nothing and needs no Apple purchases for now.

## What you need to supply

- **Apple Team ID**: Apple Developer > Membership. For a Mac build pick the team in Xcode (Signing & Capabilities). Codemagic finds it from the API key.
- **App Store Connect API key**: App Store Connect > Users and Access > Integrations > App Store Connect API. Role App Manager. You need the .p8 file, the Key ID and the Issuer ID. Add it in Codemagic > Settings > Integrations > Developer Portal and name it `chickencoops_asc`.
- **App ID capabilities** (Apple Developer > Identifiers > the live app's id): Push Notifications, Associated Domains, Sign in with Apple. If you do not want one of them, remove its key from `ios/App/App/App.entitlements`, or signing fails.
- **Widget App ID**: register `<bundle id>.CoopWidget` (no capabilities). Codemagic makes its profile.
- **APP_STORE_APPLE_ID** (optional): the app's numeric Apple ID, as a Codemagic environment variable. With it the build number becomes one above the latest build Apple has.
- **Push** (optional, off now): put a OneSignal app id in `www/app.json` `onesignal_app_id`. Empty means push is off and the app never starts OneSignal. For Android push also add `android/app/google-services.json` from Firebase.
- **Android release**: a Play Console account and an upload keystore (keep it forever).

Nothing secret goes in this folder.

## Ship the update to the existing App Store app

1. Put the live app's bundle id in (see above). The app shows up as an update only with the same id.
2. Version: `MARKETING_VERSION` is 2.0.0. It must be higher than the version live in the store now.
3. Build number: 200 in the project. It must be higher than the last build ever uploaded for the app (webtonative builds count). Codemagic uses the higher of 200 + its own build counter and (with `APP_STORE_APPLE_ID`) Apple's latest build + 1. If Apple says the build number was used, raise `BUILD_FLOOR` in `codemagic.yaml`.
4. Put this folder in a Git repo and connect it in Codemagic (codemagic.yaml is read from the repo).
5. Codemagic > Start new build > `ios-testflight`. Install from TestFlight and test.
6. When happy: Start new build > `ios-app-store`. It uploads and submits the update for review. Release it yourself in App Store Connect after approval. Or, in App Store Connect, open version 2.0.0, pick the TestFlight build and press Submit for Review.

The icon and splash: Codemagic downloads the logo from `LOGO_URL` (the S3 logo) during the
build and makes the real icon and splash. If that fails the placeholder "CC" art ships.

## In-app purchases

The live app sold subscriptions with these product ids:

- `ai.chickencoops.premium.monthly`
- `ai.chickencoops.pro.monthly`

This app supports Apple purchases (StoreKit 2) through the bridge, but the old webtonative
purchase code on the site no longer works. The site must call, inside the app:

```
Capacitor.nativePromise('CoopApp', 'iapProducts', { ids: ['ai.chickencoops.premium.monthly', 'ai.chickencoops.pro.monthly'] })
Capacitor.nativePromise('CoopApp', 'iapBuy', { id: 'ai.chickencoops.premium.monthly', token: '<member uuid>' })
```

then verify the returned `jws` on the server, grant the plan and call `iapFinish` with the
`transactionId`. Also `iapPending`, `iapRestore` (a Restore button is required) and
`iapManage`. Until that is done, hide any web checkout for digital plans inside the iPhone
app, or Apple will reject the update.

## Site side

- The app adds `ChickenCoopsApp/1.0` to the user agent. The site uses that to hide its own bottom nav, footer, install prompts and the floating chat button.
- The JS bridge is `CoopApp`: `haptic`, `info`, `tabBar`, `setRefresh`, `setBadge`, `requestReview`, `registerPush`, `appleSignIn` and the `iap*` methods above.
- The Chat tab opens the site's chat (Marketur Chat `MobileApp.open()` or the chat button).
- chickencoops.ai, its subdomains and the game on lovable.app stay inside the app. Every other link opens in the browser.
- Links from Messages or Mail open in the app only once `https://chickencoops.ai/.well-known/apple-app-site-association` (Team ID + bundle id) and `assetlinks.json` (Android) exist. Without them links open in the browser, nothing breaks.

## Icons

The placeholder art is a barn red "CC" tile on cream. To use the real logo:

- Codemagic does it on every iPhone build (`LOGO_URL`).
- GitHub: Actions > Fetch icon > Run workflow (the logo address is already filled in). It commits the new icons.
- By hand: `python3 scripts/make-art.py --logo path/to/logo.png` (needs `pip install pillow`).
