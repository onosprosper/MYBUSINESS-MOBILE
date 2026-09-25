# MYBUSINESS Android release checklist

The GitHub `Android test APK` workflow creates an APK for private testing. It is not a public release. The `Android signed release` workflow creates a signed APK for website distribution and a signed AAB for Play Console. Never publish `app-debug.apk`.

## Mobile feature access

The app has native login, signup, services setup, overview, reports, and read-only API lists. `Full business dashboard` opens the existing web dashboard inside the app. Other module buttons that previously showed an information page now open the corresponding live dashboard page. The first visit to the embedded dashboard requires the merchant to sign in again, because web sessions and native API login are separate. Network access is required.

## Prepare signing once

1. Choose and privately store an upload keystore and passwords. Do not put them into GitHub commits or chat. Back up the keystore securely; Play updates rely on the same upload identity.
2. Generate the upload key using `keytool` on a trusted computer (see Flutter's official Android deployment guide). The alias in the command must match the `ANDROID_KEY_ALIAS` secret.
3. In the `MYBUSINESS-MOBILE` repository's Settings → Secrets and variables → Actions, add:
   - `ANDROID_KEYSTORE_BASE64`: base64 encoding of the keystore's exact bytes (one line).
   - `ANDROID_KEY_ALIAS`: alias used when generating the key.
   - `ANDROID_KEY_PASSWORD`: private key password.
   - `ANDROID_STORE_PASSWORD`: keystore password.
4. Run Actions → `Android signed release` → Run workflow. Download the artifact containing `app-release.apk` and `app-release.aab`.
5. Install the signed APK on test devices. The application ID is `com.chipber.mybusiness`; older test builds using `com.example.mybusiness_mobile` are separate installations. Test login, signup, bookings, photo uploads, Android back navigation and logout.

## Website downloads

The website `/android` page accepts two Render environment variables, neither of which should be configured before the corresponding link exists:

- `ANDROID_APK_URL`: a permanent HTTPS URL to the signed release APK, for example a GitHub Release asset (GitHub Actions artifacts expire and generally require GitHub login).
- `ANDROID_PLAY_STORE_URL`: the app's real public Google Play listing URL, only after publication.

The app page automatically hides buttons without configured URLs. Do not point the APK button at the debug test artifact.

## Play Console

Create or verify your Play Console developer account. Upload `app-release.aab` to internal testing first. Complete your store listing, screenshots, app icon, privacy policy, data safety declaration, content rating and account-deletion requirements. Because users can sign up in the app, verify an in-app and public web path for deletion requests and a real fulfilment process before submitting for review. New personal accounts may need a closed test with at least 12 opted-in testers for 14 continuous days before production access, according to current Play Console requirements. Increase the version code for every subsequent Play upload.

The release workflow only prepares files. It does not enroll testers, submit the app to Play, or publish the APK to the website automatically.
