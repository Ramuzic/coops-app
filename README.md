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

## Bundle id (change this first)

`ai.chickencoops.app` is a placeholder. Find the live app's real bundle id in App Store
Connect > the app > App Information > Bundle ID, and put it in every one of these:

- `ios/App/App.xcodeproj/project.pbxproj` (4 lines: `PRODUCT_BUNDLE_IDENTIFIER`, app Debug and Release, widget Debug and Release as `<id>.CoopWidget`)
- `codemagic.yaml` (`bundle_identifier`)
- `capacitor.config.json` (`appId`)
- `scripts/add-widget-target.rb` (only used if the widget target is ever added again)
- Android, only if the Play Store app id should match: `android/app/build.gradle` (`applicationId`), `android/app/src/main/res/xml/shortcuts.xml` (3 x `targetPackage`), `android/app/src/main/res/values/strings.xml` (`package_name`, `custom_url_scheme`). Leave `namespace` and the Java folder `ai/chickencoops/app` alone.

One command does all of it (run it in this folder, swap in the real id):

```
grep -rlI "ai\.chickencoops\.app" --exclude-dir=node_modules --exclude-dir=java --exclude=README.md . | xargs sed -E -i '' 's/ai\.chickencoops\.app\.CoopWidget/REAL.BUNDLE.ID.CoopWidget/g; /namespace/!s/ai\.chickencoops\.app([^.a-zA-Z]|$)/REAL.BUNDLE.ID\1/g'
```

That is the Mac version (`sed -i ''`). On Linux use `sed -E -i`. It leaves the Android `namespace` and `targetClass` alone, as it should.

Quick action types (`coop.plan` and so on) and the Java package are not bundle ids and do not need changing.

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
