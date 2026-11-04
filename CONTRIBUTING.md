# Contributing to ContributionChart

Thanks for your interest. Bug reports, fixes, documentation, and ideas are all welcome.

## Before you start

- **For a bug,** [open an issue](https://github.com/tahirwaseempk90/ContributionChartKit/issues/new/choose) with a small piece of code that shows the problem.
- **For a new feature,** open an issue first, so we can agree on the approach before you spend time on it.
- **For a security problem,** follow the [security policy](SECURITY.md) instead of opening an issue.

## Set up

You need Xcode 16 or later. There are no dependencies to install.

[Fork the repository](https://github.com/tahirwaseempk90/ContributionChartKit/fork), then:

```sh
git clone https://github.com/YOUR_USERNAME/ContributionChartKit.git
cd ContributionChartKit
git checkout -b my-change
swift build
swift test
```

To work on the package alongside the example app, open `Example/ContributionChartExample.xcodeproj`. Changes to the package appear there immediately.

SwiftLint is optional locally, but CI runs it: `brew install swiftlint`. XcodeGen is only needed if you change `Example/project.yml`: `brew install xcodegen`.

## Make your change

### Coding expectations

- **Keep the public API small.** Every public declaration needs a documentation comment (`///`). New options should be additive, with a default value, so that existing code keeps working.
- **Keep layout pure.** Calculation belongs in `Sources/ContributionChart/Layout`, where it can be tested without rendering. Views should only declare elements.
- **Validate outside input.** Numbers from callers go through `ChartMetrics`. No input may produce non-finite geometry.
- **Avoid force unwraps, force casts, and `@unchecked Sendable`** in production code.
- **Use no third-party dependencies,** unless we've agreed otherwise in an issue.
- **Don't add abstractions in advance.** A protocol needs at least two real implementations.
- **Write comments that explain why,** not what the code does.

### Tests

Every change in behaviour needs a test, and a bug fix needs one that fails without the fix.

```sh
swift test                  # Package tests on macOS
Scripts/coverage.sh 99      # The same, with coverage, which CI requires to be at least 99%
swiftlint lint --strict     # Lint
```

If you change the example app, also run its UI tests:

```sh
xcodebuild test -project Example/ContributionChartExample.xcodeproj \
  -scheme ContributionChartExample \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

On macOS, UI tests take control of the mouse and bring the app to the front.

### Snapshots

If your change alters how a chart looks, the snapshot tests will fail. If the new look is intended, record new references on both macOS and iOS, then check the images in your diff:

```sh
SNAPSHOT_RECORD=1 swift test --filter SnapshotTests

TEST_RUNNER_SNAPSHOT_RECORD=1 xcodebuild test -scheme ContributionChart \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ContributionChartTests/SnapshotTests CODE_SIGNING_ALLOWED=NO
```

References only exist for specific OS versions, and tests skip on other versions. If you can't record on those versions, say so in your pull request.

### Documentation

Update the guides in `Documentation/` and `CHANGELOG.md` when behaviour changes. Documentation must describe what the code does today, not what's planned.

## Open a pull request

1. Push your branch and open a pull request against `main`.
2. Explain what changed and why. Include before and after screenshots for a visual change.
3. Make sure CI passes.

## Questions

Open an issue. There are no silly questions.
