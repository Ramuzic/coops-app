# ChickenCoops.ai app: build guide

How to build and run the app on your own Mac. For signed App Store builds through
Codemagic, the bundle id and the update to the live app, see `README.md`.

## 1. One-time setup on your Mac

1. Install **Node.js** (the LTS version) from nodejs.org.
2. Install **Xcode** from the Mac App Store, open it once and let it finish installing its parts.
3. Install **Android Studio** from developer.android.com/studio and open it once (it downloads the Android SDK).

## 2. Get the project ready

1. Unzip this folder somewhere easy, like your Desktop.
2. Open **Terminal**, type `cd ` (with a space), drag the folder into the Terminal window, and press Return.
3. Run:

```
npm install
npx cap sync
```

4. **App icon and splash:** the project ships with placeholder art (a barn red "CC" tile on cream).
   To use the real logo, download it and run:

```
pip3 install pillow
python3 scripts/make-art.py --logo ~/Downloads/coop-ai-app-logo.png
```

## 3. iPhone (Xcode)

```
npx cap open ios
```

In Xcode:

1. Click **App** at the top of the left sidebar, then the **App** target, then **Signing & Capabilities**.
2. **Team:** pick your Apple Developer account. Check the Bundle Identifier is the live app's id (see README.md). Do the same for the **CoopWidget** target (`<bundle id>.CoopWidget`).
3. Pick an iPhone simulator (or your plugged-in iPhone) at the top and press the Play button.

OneSignal is already in the project as a package. Push stays off while `onesignal_app_id`
in `www/app.json` is empty.

## 4. Android (Android Studio)

```
npx cap open android
```

1. Wait for "Gradle sync" to finish (bottom bar). The first time takes a few minutes.
2. Pick an emulator or your plugged-in phone at the top and press the green Run button.

## 5. Turning on push later (OneSignal)

1. Create (or reuse) a OneSignal app for chickencoops.ai and put its App ID in `www/app.json` as `onesignal_app_id`.
2. **iPhone:** Apple Developer > Certificates, IDs & Profiles > Keys > create a key with **Apple Push Notifications service (APNs)**, download the .p8 file. In OneSignal: Settings > Push & In-App > **Apple iOS (APNs)** > the .p8 key, the Key ID, your Team ID and the bundle id.
3. **Android:** in the Firebase console add an Android app with the Android app id, then Project settings > Service accounts > Generate new private key. Upload that JSON in OneSignal > **Google Android (FCM)**, and put `google-services.json` in `android/app/`.
4. To ask for permission during onboarding, add `"push": true` to the last onboarding slide in `www/app.json`.
5. The site links a phone to a member with `Capacitor.nativePromise('CoopApp', 'registerPush', { externalId: '...' })`.

## 6. Test checklist

- First launch shows the 4 onboarding slides, only once.
- Each tab opens the right page and lights up. Tapping the tab you are on scrolls to the top.
- Chat opens the chat panel.
- The game opens inside the app.
- Airplane mode shows the offline screen. Turning it off brings the page back.
- Links to other websites open in Safari or Chrome, not inside the app.
- Press and hold the app icon: Plan a coop, Community, Reels.
- iPhone: add the "Daily coop tip" widget. Tapping it opens the planner.

To see the web page's console on iPhone: Safari on the Mac > Settings > Advanced > Show
features for web developers, then the Develop menu > your simulator > the page.

## 7. Changing tabs, colors or onboarding text

Everything is in `www/app.json`. Change it, then run `npx cap copy` and build again.
Icons for tabs and onboarding: home, plan, breeds, reels, community, chat, share, bell.

## 8. Store builds by hand

- iPhone: Xcode > Any iOS Device > Product > Archive > Distribute App > App Store Connect.
  Version 2.0.0 and build 200 are already set; the build number must be higher than any build uploaded before.
- Android: Build > Generate Signed App Bundle (keep the keystore file and password safe forever), then upload the .aab in Google Play Console.
