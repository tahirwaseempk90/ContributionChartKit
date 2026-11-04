# Testing

## Running the tests

```sh
# Unit, rendering, snapshot, and performance tests on macOS.
swift test

# The same with a coverage report, failing below a minimum line coverage.
Scripts/coverage.sh 99

# The package's tests on iOS Simulator. Change the destination for other platforms.
xcodebuild test -scheme ContributionChart \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO

# The example app's UI tests.
xcodebuild test -project Example/ContributionChartExample.xcodeproj \
  -scheme ContributionChartExample \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

On macOS, UI tests take control of the mouse and bring the app to the front, so run them when you aren't
using the machine.

## What is tested

429 tests in the package, and 59 UI tests in the example app (47 of them also run on macOS).

| Suite | Tests | What it covers |
|---|---|---|
| `ChartLayoutEngineTests` | 98 | Sizing, title, labels, fallbacks at small sizes, axis, reference lines, regions, ticks |
| `ChartGeometryCalculatorTests` | 51 | Distribution, marks, stems, density, pixel alignment |
| `ChartScaleCalculatorTests`, `ChartScaleTests` | 52 | Every scale mode, tidy ticks, extreme and invalid values |
| `ContributionChartRenderingTests` | 41 | The real view, examined pixel by pixel |
| `SnapshotTests` | 39 | Visual regressions in device-sized frames, appearances, and data shapes, plus the README's hero image |
| `ChartModelTests` | 26 | Tick labels, reference lines, and mapping indices past invalid points |
| `ChartValueFormatterTests` | 23 | Percentages, precision, locales, and extreme values |
| `AnnotationLayoutCalculatorTests` | 20 | Label placement and overlaps |
| `ChartDatasetTests`, `ChartDataPointTests` | 31 | Validation, identity, and duplicates |
| `ChartAccessibilityDescriberTests`, `ChartAudioGraphDescriptorTests` | 24 | Spoken wording and Audio Graph data |
| `ChartConfigurationTests`, `ChartPaletteTests` | 17 | Defaults, invalid settings, and the contrast of default colours |
| `PerformanceTests` | 5 | Scaling and the limit on work per layout |
| `LayoutFuzzTests` | 2 | Hostile input across 4,500 seeded cases |
| Example app UI tests | 59 | Launch, display, accessibility, responsive layout, and screenshots |

### Unit tests

Layout, scaling, and formatting are pure functions, so most tests call them directly. Text measurement is
injected through `ChartElementMeasuring`, so layout is tested with exact, known sizes and no rendering.

### Fuzz tests

`LayoutFuzzTests` runs the whole layout pipeline against thousands of seeded combinations of hostile input:
`NaN`, infinities, `±greatestFiniteMagnitude`, subnormal values, negative and non-finite settings, and
degenerate sizes. It asserts the promise the package makes: every coordinate is finite and inside the chart.
A failure message includes the seed, so it can be reproduced.

### Rendering tests

`ContributionChartRenderingTests` renders the real view offscreen with SwiftUI's `ImageRenderer`, which runs
the real layout pass and `Canvas`, and then examines the pixels. Examples:

- All green pixels are above the baseline, and all red pixels are below it.
- A right-to-left chart is an exact mirror image of the left-to-right one.
- Lines have solid pixels at 1x, 2x, and 3x, which shows they're aligned to the pixel grid.
- Changing a chart's data gives the same pixels as drawing the new chart fresh.

### Snapshot tests

Snapshot libraries were evaluated and rejected: `ImageRenderer` makes a harness about 100 lines long
([`SnapshotAssertion.swift`](../Tests/ContributionChartTests/Support/SnapshotAssertion.swift)), which doesn't
justify a dependency.

References are in `Tests/ContributionChartTests/__Snapshots__/<platform>-<OS major version>/`, because text
renders differently between operating systems. Where no references exist for the current platform and OS,
these tests skip rather than report false failures. So on a new OS, CI won't catch visual changes until new
references are recorded.

To record, then review the changes in your diff tool:

```sh
SNAPSHOT_RECORD=1 swift test --filter SnapshotTests

TEST_RUNNER_SNAPSHOT_RECORD=1 xcodebuild test -scheme ContributionChart \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ContributionChartTests/SnapshotTests CODE_SIGNING_ALLOWED=NO
```

Frames are named for the devices they represent, such as `iphone-compact-light` and `ipad-dark`. The frame
is what the chart responds to, so these run the same way on any simulator.

The README's hero image comes from `testReadmeHeroLight` and `testReadmeHeroDark`. If the chart's appearance
changes, copy their iOS references to `Documentation/Assets/hero-light.png` and `hero-dark.png`.

### UI tests

The tests in `Example/ContributionChartExampleUITests` find elements by accessibility identifier and compare
positions relative to each other, never against exact coordinates, so they work across devices.

`ScreenshotTests` captures every screen in both appearances. To collect them from a result bundle:

```sh
Scripts/export-screenshots.py path/to/result.xcresult output-folder
```

### Testing what VoiceOver reads

XCUITest can't show what VoiceOver reads, because its tree also includes elements hidden from VoiceOver. A
plain `Text("x").accessibilityHidden(true)` still appears in it. SwiftUI also doesn't build accessibility nodes
in a plain test process, so a unit test can't walk them either.

So the example app has a small test-only probe, `VoiceOverTreeProbe`, enabled by the `-exposeVoiceOverTree`
launch argument. It walks the `UIAccessibility` tree, which is what VoiceOver traverses, and publishes the
result for the UI tests to read. This runs on iOS only.

These tests verify the tree, not the experience. Nobody has yet tested the chart by using it with VoiceOver,
or heard its Audio Graph.

## Coverage

Measured by `Scripts/coverage.sh` on macOS, with `swift test --enable-code-coverage`:

| Metric | Coverage |
|---|---|
| Lines | 100.00% (1944 of 1944) |
| Functions | 100.00% (324 of 324) |
| Regions | 99.86% (698 of 699) |

Coverage is a measure of which lines ran, not of whether they're right. It reached 100% of lines before a
code review found several real bugs, each of which now has its own test.

The uncovered region is `guard let position else { return .zero }` in `ChartContainerLayout`'s measurer. It
guards against the engine asking for a subview that doesn't exist. The engine and the view agree on which
subviews exist, and `LayoutSubviews` can't be constructed in a test, so it can't be reached. It stays because
the alternative is a crash if that agreement were ever broken.

## Performance

Measured with `PerformanceTests.testScalingReport`, in a release build on an Apple Silicon Mac. Each figure is
the fastest of several runs, in milliseconds, for a 393 × 300 chart. Render is a complete offscreen render,
including rasterizing the image and all text.

| Points | Build model | Layout | Render | Labels shown |
|---|---|---|---|---|
| 3 | 0.01 | < 0.01 | 0.92 | 3 |
| 10 | 0.01 | < 0.01 | 1.71 | 6 |
| 50 | 0.07 | 0.01 | 6.81 | 11 |
| 100 | 0.14 | 0.02 | 13.45 | 11 |
| 500 | 0.20 | 0.03 | 13.56 | 9 |
| 1,000 | 0.25 | 0.04 | 12.88 | 10 |

Time stops growing with the data past about 100 points, because text is created and measured for at most 100
points. No caching has been added, as nothing here justifies one. To get figures for your own device, run the
test on it.

### Behaviour with dense data

| Points on a phone-sized chart | Behaviour |
|---|---|
| Up to about 10 | Full-size marks, and usually every label |
| 50 to 100 | Marks shrink, and only labels that fit are shown, largest first |
| 500 to 1,000 | Minimum-size marks that merge into a silhouette, with labels only at the extremes |

The 100 largest values get their own VoiceOver elements, and all values are in the Audio Graph. For dense data
that needs individual labels, put the chart in a horizontal `ScrollView`, where it chooses a wider frame by
itself.

## Linux

The package can't be built or tested on Linux, because SwiftUI only exists on Apple platforms. The layout code
could be split into a target that doesn't need SwiftUI, but it depends on `CGRect` and similar types, and
Apple-platform CI already covers it, so no benefit would justify the added structure.

## Continuous integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) defines these jobs, all on macOS runners:

| Job | What it does |
|---|---|
| `package` | Resolves dependencies, builds with warnings as errors, runs tests, and fails below 99% line coverage |
| `platforms` | Compiles for iOS, iOS Simulator, Mac Catalyst, tvOS, watchOS, and visionOS |
| `ios-unit-tests` | Runs the package's tests on iOS Simulator |
| `example` | Checks the Xcode project matches `project.yml`, builds for macOS and visionOS, and runs the UI tests |
| `lint` | Runs SwiftLint in strict mode |

The workflow runs on pushes to `main` and on pull requests, using the newest stable Xcode on GitHub's latest
macOS runner. That was Xcode 26.6 with Swift 6.3.3 on macOS 26 when this was last checked, with the iOS jobs on
iOS 26.5.

References for snapshot tests only exist for OS 27, so **these tests skip on CI** until GitHub's runners reach
OS 27. Until then, CI doesn't catch visual changes, and snapshots have to be run locally. All other tests run
there.

A second workflow, [`compatibility.yml`](../.github/workflows/compatibility.yml), runs on the same events. It tests
the oldest toolchain and systems that GitHub's runners offer, because SwiftUI's behaviour can differ between OS versions
in ways the compiler can't see:

| Job | What it does |
|---|---|
| `macos` | Builds with warnings as errors and runs the tests, with Swift 6.0 on macOS 14 and Swift 6.1 on macOS 15 |
| `package-tests` | Runs the package's tests on iOS 17.0 and 18.6, Mac Catalyst, tvOS 17.0, watchOS 10.0, and visionOS 1.0 |
| `declared-minimums` | Downloads the simulators for iOS 16.4, tvOS 16.4, and watchOS 9.4, and runs the package's tests on them |
| `example` | Builds the example app, and runs its UI tests on iOS 17.0 and 18.6 |

It will need updating when GitHub retires a runner image. A failure there doesn't affect the CI badge, which only
follows `ci.yml`.
