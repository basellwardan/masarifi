# مصاريفي · My Expenses

A Syrian personal expense tracker for Android, built with React and Capacitor. It is offline-first and stores everything on the device.

- Amounts are stored in the **new Syrian pound**. Settings can display them in old SYP (×100) or in USD at a rate you type in yourself.
- Arabic RTL is the default, and English is available in Settings.
- Voice entry uses the on-device speech recognizer, and `src/lib/voiceParser.ts` turns phrases like "صرفت خمسين ألف على البقالة" into an amount, a type and a category.
- **مشاركة مصاريفي** in Settings shares a text summary with the remaining balance and every transaction, plus a CSV file.

## Develop
```bash
npm install
npm run dev        # http://localhost:5180 (phone frame on desktop)
npm test           # voice parser tests
npm run build      # type-check + production bundle
```
In dev, `window.__store` and `window.__ui` expose the stores for quick seeding.

## Android
Gradle 8.11 cannot run on JDK 25, and the Capacitor 7 modules compile with Java 21, so run Gradle on JDK 21. Gradle's toolchain resolver downloaded it to `~/.gradle/jdks`, and `android/local.properties` points to the SDK.
```powershell
npm run build; npx cap sync android
$env:JAVA_HOME = "$env:USERPROFILE\.gradle\jdks\eclipse_adoptium-21-amd64-windows.2"
cd android; .\gradlew.bat assembleDebug
# -> android/app/build/outputs/apk/debug/app-debug.apk
```
Icons and splash images come from the logo. Run `node tools/android-res.mjs` again after changing it. `tools/make-icons.mjs` writes `public/logo.svg` and 1024px source PNGs to `assets/`.

## Layout
- `src/screens/` holds Splash, Welcome, Home, Transactions, Stats, Voice and Settings.
- `src/components/` holds Money (muted decimals), TabBar (glass bar with a sliding black pill), AddSheet (keypad and mic), the modal sheets and the Logo.
- `src/lib/` holds currency, i18n, store (zustand persisted to Capacitor Preferences), voiceParser, speech, share and categories.
- `src/styles/tokens.css` holds the colours, glass and radii taken from the reference screens.

## iPhone (native SwiftUI, Liquid Glass)
The iPhone app in `ios-native/` is a separate native SwiftUI app with no web view. Its screens are drawn to match the Android build: the same layout, colours (`src/styles/tokens.css` → `UI/Theme.swift`), fonts and icons, plus Apple's real Liquid Glass.
- Fonts are the APK's Inter and IBM Plex Sans Arabic. `python tools/ios-fonts.py` rebuilds them into `ios-native/Masarifi/Fonts/` from `node_modules/@fontsource` and needs `pip install fonttools`.
- Icons are the same Lucide outlines, drawn as native vector paths. `node tools/ios-icons.mjs` regenerates `UI/LucideData.swift`; add new icons to its list.
- Liquid Glass (iOS 26 `glassEffect`) covers the floating tab bar, the glass circle buttons, the chips, the month card, the statistics bubbles, the mic bubble and the logo tile. The grey and black pills keep the APK's colours and press like glass. On iOS 18–25 these fall back to the APK's own translucent look.
- Same features and wording as the Android app. `ios-native/Masarifi/Model/VoiceParser.swift` is a port of `src/lib/voiceParser.ts`, so keep the two in step. `MasarifiTests` repeats the TypeScript parser cases.
- On first launch it imports what the earlier web-based iPhone build saved (`CapacitorStorage.masarifi-v1`).
- There's no Mac here. GitHub Actions (`.github/workflows/ios.yml`) generates the Xcode project with XcodeGen (`ios-native/project.yml`) and runs the tests on a simulator with Xcode 26. It then screenshots every screen in the simulator (the `screenshots` artifact) and uploads an unsigned `masarifi.ipa`. Install it with Sideloadly.
- Debug builds accept `-uiDemo`, `-uiTab 0…4`, `-uiSheet add|month|notifications`, `-uiLang en` and `-uiWelcome` as launch arguments, which CI uses for the screenshots.
- To regenerate the icon and launch assets: `node tools/native-ios-assets.mjs`.
