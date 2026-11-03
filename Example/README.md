# ContributionChartExample

A SwiftUI app demonstrating the `ContributionChart` package. It uses the package through a local Swift
Package reference, exactly as your app would, and contains no chart code of its own.

## Run it

1. Open `ContributionChartExample.xcodeproj` in Xcode.
2. Choose the `ContributionChartExample` scheme.
3. Choose an iOS or visionOS simulator, or **My Mac**, and run.

No account or signing setup is needed for a simulator or Mac. To run on a physical device, choose your
team under **Signing & Capabilities**.

## Screens

| Screen | What it shows |
|---|---|
| Reference Chart | The supplied screenshot reproduced, and the chart from the written brief on yellow |
| Mixed Data | Positive and negative values, with a picker for each scale mode, and a value axis |
| Positive Only | All points above the baseline, proportional and symmetric |
| Negative Only | All points below the baseline, proportional and fixed |
| Custom Styling | Seven configurations: colours, markers, bars, formatting, reference lines, and more |
| Responsive Layout | Sliders to resize a chart, fixed frames, `HStack`, `Grid`, `List`, a sheet, and horizontal scrolling |
| Edge Cases | Empty, one point, all zero, extreme values, long names, invalid values, duplicates, and dense data up to 1,000 points |
| Accessibility | Dynamic Type, right-to-left layout, and custom VoiceOver wording |

Use the toolbar's appearance menu to switch between light and dark.

## Run the UI tests

Press **⌘U** in Xcode, or:

```sh
xcodebuild test \
  -project Example/ContributionChartExample.xcodeproj \
  -scheme ContributionChartExample \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Launch arguments

Add these under **Product > Scheme > Edit Scheme > Arguments** to open a specific state:

| Argument | Values | Effect |
|---|---|---|
| `-scenario` | `reference`, `mixed`, `positiveOnly`, `negativeOnly`, `customStyling`, `responsiveLayout`, `edgeCases`, `accessibility` | Opens that screen |
| `-appearance` | `system`, `light`, `dark` | Sets the appearance |
| `-exposeVoiceOverTree` | `YES` | Publishes what VoiceOver would read, for the UI tests (iOS only) |

## Changing the project

`ContributionChartExample.xcodeproj` is generated from `project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen). The generated project is committed, so XcodeGen is only
needed if you change `project.yml`:

```sh
cd Example && xcodegen generate
```
