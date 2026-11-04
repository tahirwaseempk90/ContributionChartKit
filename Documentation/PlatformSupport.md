# Platform Support

## Minimum versions

| Platform | Minimum | Why |
|---|---|---|
| iOS, iPadOS | 16 | The `Layout` protocol |
| Mac Catalyst | 16 | The `Layout` protocol |
| macOS | 13 | The `Layout` protocol |
| tvOS | 16 | The `Layout` protocol |
| watchOS | 9 | The `Layout` protocol |
| visionOS | 1 | First release |

## What has been validated

Tested locally with Xcode 27.2 (27B52) and Swift 6.4.2 on macOS 27.2, where all simulators ran version 27.2:

| Platform | Compiled | Package tests | UI tests | Tested on |
|---|---|---|---|---|
| iOS | Yes | 429 passed | 59 passed on each device | iPhone 17e, iPhone 17, and iPhone 18 Pro Max simulators |
| iPadOS | Yes | Same build as iOS | 59 passed on each device | iPad mini (A20 Pro) and iPad Pro 13-inch (M5) simulators |
| macOS | Yes | 429 passed | 47 passed | Apple Silicon Mac |
| Mac Catalyst | Yes | 390 passed, 39 skipped | None | Apple Silicon Mac |
| visionOS | Yes | 390 passed, 39 skipped | None. The example app launched and rendered correctly. | Apple Vision Pro simulator |
| tvOS | Yes | 390 passed, 39 skipped | None | Apple TV 4K (4th generation) simulator |
| watchOS | Yes | 390 passed, 39 skipped | None | Apple Watch Series 12 (46mm) simulator |

Also tested on GitHub Actions with Xcode 26.6 (17F113) and Swift 6.3.3 on macOS 26:

| Platform | Compiled | Package tests | UI tests | Tested on |
|---|---|---|---|---|
| iOS | Yes | 390 passed, 39 skipped | 59 passed | iOS 26.5 iPhone 17 Pro simulator |
| macOS | Yes | 390 passed, 39 skipped | None | GitHub's arm64 runner |
| iOS device, Mac Catalyst, tvOS, watchOS, visionOS | Yes | None | None | Compiled only |

Older systems are tested on GitHub Actions by the
[compatibility workflow](../.github/workflows/compatibility.yml):

| Toolchain | Platform | Package tests | UI tests |
|---|---|---|---|
| Xcode 16.2, Swift 6.0.3 | macOS 14 | 390 passed, 39 skipped | None |
| Xcode 16.2 | Mac Catalyst on macOS 14 | 390 passed, 39 skipped | None |
| Xcode 16.2 | iOS 16.4 | 390 passed, 39 skipped | None, as they need iOS 17 |
| Xcode 16.2 | iOS 17.0.1 | 390 passed, 39 skipped | 59 passed |
| Xcode 16.2 | tvOS 16.4 and 17.0 | 390 passed, 39 skipped on each | None |
| Xcode 16.2 | watchOS 9.4 and 10.0 | 390 passed, 39 skipped on each | None |
| Xcode 16.2 | visionOS 1.0 | 390 passed, 39 skipped | None |
| Xcode 16.4, Swift 6.1.2 | macOS 15 | 390 passed, 39 skipped | None |
| Xcode 16.4 | iOS 18.6 | 390 passed, 39 skipped | 59 passed |

"Skipped" tests are the snapshot tests, which only have references for macOS 27 and iOS 27. All the other package
tests ran on those platforms, including the rendering tests.

**Not validated:**

- **macOS 13.** This is the one declared minimum that hasn't been run, because GitHub's runners no longer offer it.
  The oldest macOS tested is 14. The compiler confirms the package uses only APIs available on macOS 13, but SwiftUI's
  behaviour can differ between versions.
- **Earlier point releases.** The oldest versions run are iOS 16.4, tvOS 16.4, and watchOS 9.4, not 16.0 and 9.0.
- **Visual comparison on older systems.** Snapshot tests only compare images on OS 27. Elsewhere, the rendering tests
  check what was drawn, but nobody has looked at the results on older systems.
- **Physical devices.** Everything ran on simulators and Macs.

## Devices

The chart responds to the frame it's given, not to the device, so it has no device-specific code. These
frames are covered by snapshot tests on macOS and iOS, and the real devices listed above ran the UI tests.

| Scenario | Frame | How it was checked |
|---|---|---|
| Small iPhone | iPhone 17e | UI tests and screenshots |
| Standard iPhone | iPhone 17 | UI tests and screenshots |
| Large iPhone | iPhone 18 Pro Max | UI tests and screenshots |
| Small and large iPad | iPad mini, iPad Pro 13-inch | UI tests and screenshots |
| Portrait and landscape | Rotating the devices above | `testChartAdaptsToRotation` |
| Narrow container | 120 × 220, and 44 × 44 | Snapshots |
| Wide container | 852 × 220, 900 × 420 | Snapshots |
| Short height | 350 × 90, and 350 × 44 | Snapshots |
| Tall height | 393 × 620 | Snapshots |
| Resizable | Live sliders in the example app | `testResizingTheFrameResizesTheChart` |

## Platform notes

### macOS

- **There's no Dynamic Type.** Text styles have fixed sizes on macOS, so the chart's text doesn't grow.
- **`.primary` is translucent.** On macOS it's about 85% black rather than pure black. If you need an exact match
  to a design, as `EditorialChartStyle.swift` does, use an explicit colour.
- **Elements are static text.** macOS only exposes an element's value when it's static text, so the chart's
  VoiceOver elements have that trait. As a result, the contrast check in XCTest's `performAccessibilityAudit`
  flags them, by measuring the marks underneath as if they were letters. These elements draw nothing, so you can
  ignore those results.

### Mac Catalyst

Behaves as iOS. Its unit tests pass, but the example app doesn't target Catalyst, because it targets native macOS
instead, so Catalyst has no UI tests.

### visionOS

The example app runs on visionOS, but its UI tests target iOS and macOS only. Charts sit on translucent glass there,
so check that any opaque colours you choose look right against it.

### tvOS

The chart isn't focusable, as it has no interactive elements. If you place it in a focusable container, the
container handles focus. Text is measured at tvOS sizes, so you may want a larger `idealPlotHeight`.

### watchOS

The chart works, but small screens leave little room. In a 184 × 150 frame, the largest values keep their labels and
the others are left out. Consider hiding the title and using short names. The example app doesn't target watchOS.

### Right-to-left languages

Supported on every platform. The chart mirrors, and points run from right to left. Built-in formatters use the
locale's own number format. This was checked with a Hebrew locale, and with right-to-left layout forced on an
English locale.

## Known limitations

- **No interaction.** There's no selection, tooltips, or scrubbing.
- **No animation between datasets.** Marks are drawn on a `Canvas` that redraws instantly, so the chart disables
  animation when its marks change. This also means a change of data under `withAnimation` won't animate.
- **Linear scale only.** With very uneven data, small values sit near the baseline. There's no logarithmic mode.
- **Default VoiceOver wording is English.** All of it can be replaced. See
  [Customization](Customization.md#accessibility).
- **Decorations aren't described to VoiceOver.** Reference lines and shaded regions aren't announced. If yours
  carry meaning, describe them with a custom `summary`.
- **Labels can overlap gridlines.** When a value axis is shown, a gridline can pass behind a label. They stay
  readable, as gridlines are faint by default, but the chart doesn't move labels to avoid them.
- **Very wide frames.** A chart's chosen width stops at 16,384 pixels, the usual GPU texture limit. A parent can still
  offer more, and whether that draws depends on the device's GPU. On iOS 16, tvOS 16, and watchOS 10 and earlier,
  SwiftUI's `ImageRenderer` crashes when asked for an image wider than the limit, whatever the view, so keep exported
  images within it. Simulators on virtual GPUs allow as little as 4,096 pixels.
