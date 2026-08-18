# ScreenshotKit — App Store screenshots

Produces the eight 6.9" (1320×2868) App Store pages described in
[docs/plans/app-store-screenshots.md](../../docs/plans/app-store-screenshots.md):
warm notebook page, green tracked kicker on a hairline rule, regular New York
headline, the real app as a flat photo in a warm-ink bezel, and the SproutMark
growing one stage per page.

## 1. Capture the raw screens

```bash
UD=$(xcrun simctl list devices available | grep -m1 "iPhone 17 Pro Max" | grep -oE "[0-9A-F-]{36}")
xcrun simctl boot "$UD"
xcrun simctl status_bar "$UD" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4
# frame 5 needs a fictional receipt in the photo library:
xcrun simctl addmedia "$UD" Design/ScreenshotKit/fixtures/receipt-corner-market.png

xcodebuild test -project Savely.xcodeproj -scheme Savely \
  -destination "platform=iOS Simulator,id=$UD" \
  -only-testing:SavelyUITests/StoreScreenshotTourUITests \
  -parallel-testing-enabled NO -resultBundlePath build/Tour.xcresult
xcrun xcresulttool export attachments --path build/Tour.xcresult --output-path build/tour
Design/ScreenshotKit/collect.sh build/tour build/captures
```

The tour launches the app with `-SavelyScreenshotSeed` (DEBUG only,
`Savely/Utilities/ScreenshotSeed.swift`), which **wipes** the Simulator store and
seeds the fictional dataset — never run it against a device with real data.

## 2. Compose the pages

```bash
swift Design/ScreenshotKit/compose.swift build/captures build/store
```

Renders with SwiftUI's `ImageRenderer` on macOS, so the type is the real
New York / SF Pro (nothing embedded, nothing licensed for the web). Copy lives
in `compose.swift` — one file, one source of truth.

## 3. Before upload

```bash
sips -g hasAlpha build/store/*.png            # must be "no"; flatten if not:
magick in.png -background '#f6f4ee' -alpha remove -alpha off out.png
```

Upload only the **6.9" slot** (Apple scales every smaller iPhone from it);
the project is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad set is
required. Run the 25% zoom legibility check before submitting.
