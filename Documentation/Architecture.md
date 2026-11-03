# Architecture

This document explains how the chart is built and why. Read it before changing the layout or
rendering code.

## Overview

The chart turns data into positions in a single, pure calculation. SwiftUI views then draw
what the calculation produced. Almost everything worth testing is in that calculation, so it
can be tested without rendering anything.

```text
 points, title, configuration
              │
              ▼
        ChartModel              Validates input, computes the scale, formats text.
              │                 Doesn't depend on size. Built once per body.
              ▼
        ChartPlotView           Declares every element as a child view, in drawing order.
              │
              ▼
     ChartContainerLayout       SwiftUI's `Layout` protocol. Measures text, places children.
              │
              ▼
      ChartLayoutEngine         Pure. Size in, frame for every element out.
        │             │
        ▼             ▼
 ChartVerticalPlan   ChartLayoutAssembler
 Who gets the height  Positions everything relative to the marks
                      │
                      ├── ChartGeometryCalculator     Stems, markers, baseline
                      └── AnnotationLayoutCalculator  Labels and their collisions
```

The `Canvas` that draws the marks calls `ChartGeometryCalculator` directly with its own size.
Because that function is pure, the canvas and the layout always agree, without sharing any state.

## Component responsibilities

| Component | Responsibility |
|---|---|
| `ContributionChart` | The public view. Chooses between the plot and the empty state. |
| `ChartDataPoint` | One labelled value. Domain neutral. |
| `ChartConfiguration`, `ChartStyle`, and related types | What callers can customise. |
| `ChartDataset` | Removes non-finite values and makes identifiers unique. |
| `ChartMetrics` | Validates every number that came from outside the package. |
| `ChartScale` | Maps a value to a fraction of the plot height, safely at any magnitude. |
| `ChartScaleCalculator` | Chooses the numeric range and tidy tick values. |
| `ChartModel` | Everything about a chart that doesn't depend on its size. |
| `ChartLayoutEngine` | Negotiates size and runs the layout steps in order. |
| `ChartVerticalPlan` | Divides the height, and decides what to drop when it runs out. |
| `ChartLayoutAssembler` | Positions every element once the plan is known. |
| `ChartGeometryCalculator` | Stems, markers, and baseline, from nothing but a size. |
| `AnnotationLayoutCalculator` | Places labels and resolves overlaps. |
| `ChartContainerLayout` | Connects the engine to SwiftUI's `Layout` protocol. |
| `ChartMarksRenderer` | Draws stems and markers into a `Canvas`. |
| `ChartPlotAccessibility`, `ChartAccessibilityDescriber`, `ChartAudioGraphDescriptor` | What assistive technology perceives. |

## Layout calculation

`ChartLayoutEngine.layout(in:measuring:)` runs these steps in dependency order, so nothing
depends on a result that isn't ready yet:

1. **Horizontal space.** The plot width depends only on the chart width and the tick labels. It
   sets how wide labels can be.
2. **Measure text** at those widths, through the `ChartElementMeasuring` protocol. SwiftUI
   subviews answer in the app, and fixed sizes answer in tests.
3. **Vertical space.** `ChartVerticalPlan` reserves room for the title and for labels above and
   below the plot, then gives what remains to the plot. If the plot would be shorter than
   `minimumPlotHeight`, it tries again with less: first without labels, then without the title,
   then without axis labels. Marks are always kept.
4. **Marks**, from the resulting plot area.
5. **Everything else**, positioned relative to the marks.

### Horizontal distribution

`.slots` gives each point an equal slot and centres it there, so any label up to the slot width
is guaranteed to fit. `.edgeToEdge` puts the first and last points at the plot's edges, which is
what the reference screenshot does so that its shaded region can line up with a point.

### Marks at different densities

Markers shrink to at most `maximumSpacingFraction` of the distance between points, down to
`minimumDiameter`. Stems and the minimum stem length shrink by the same ratio, so a dense chart
keeps the proportions of a sparse one. No stem gets narrower than one physical pixel, or it
would vanish.

### Pixel alignment

Line edges are aligned to device pixels using the environment's display scale, so they stay
crisp at 1x, 2x, and 3x. The marker's centre comes from its stem's aligned edges, because a
marker aligned independently could sit half a pixel off its stem. The canvas frame is aligned
too, because marks aligned within a canvas at a fractional position would blur anyway.

### Labels and collisions

Labels are considered from the largest value to the smallest. A label is kept only if it doesn't
overlap a label already kept or another point's marks. In a chart about the biggest values,
those are the labels most worth keeping. Ties go to the earlier point, so the result is
deterministic.

Names truncate, but values never do, because a truncated number is misleading. A label whose
value doesn't fit is hidden as a whole.

## Rendering

### `Canvas` for marks, views for everything else

| | Individual views | `Canvas` | Decision |
|---|---|---|---|
| 1,000 points | Thousands of views | One view | Canvas for stems and markers |
| Text and VoiceOver | Native | Canvas text is invisible to VoiceOver | Views for all text |
| Few, simple elements | Trivial | No advantage | Views for lines and regions |

Each fill covers one combined path per colour. This has a visual benefit beyond speed: separately
filled translucent stems in a dense chart would build up into dark bands where they overlap.

### `Layout` instead of `GeometryReader`

`GeometryReader` takes all the space it's offered and collapses in a `ScrollView`, and it can't
report an ideal size. A custom `Layout` receives the parent's real proposal, including an open
dimension, and answers it directly: finite proposals are honoured, infinity is returned so the
chart stays flexible, and an open dimension gets an ideal size.

A `Layout` also has a limitation that shapes the code. It must place every subview and can't
change one's opacity, so it can't simply hide a label it has measured. `CollapsibleLayout` solves
this: it makes a zero proposal mean zero size, and clipping to that size hides the content.

### Sharing geometry between `Layout` and `Canvas`

`Canvas` receives only a size, and a `Layout` can't pass anything to its children beyond a
proposed size. Rather than sharing state between the layout and render passes, which would
require a reference type and unsafe concurrency annotations, the code makes size sufficient: the
layout places the canvas at exactly the plot area plus the marks' margin, and
`ChartGeometryCalculator` derives everything else from that size.

### Right-to-left layout

SwiftUI mirrors where a `Layout` places its children, but not what a `Canvas` draws inside itself.
`.flipsForRightToLeftLayoutDirection(true)` on the canvas makes the two agree. The engine always
works in left-to-right coordinates. Pixel tests verify that a right-to-left chart is an exact
mirror image.

## Scaling

All modes use one linear scale that includes zero, so equal magnitudes are equally long on
both sides of the baseline.

| Strategy | Trade-off | Decision |
|---|---|---|
| Proportional | Uses the height fully. The baseline moves with the data. | **Default.** Matches the reference screenshot, whose axis runs from -20 to 30. |
| Symmetric | The baseline is always centred, but lopsided data leaves one side part empty. | Available as `.symmetric`. |
| Fixed | The same scale across charts, but values can exceed it. | Available as `.fixed(lower:upper:)`. |
| Independent ranges for each side | Fills both sides, but `-2.70` could look as long as `+11.05`. | **Rejected.** It misrepresents the data, which is the one thing a chart must not do. |

### Tick labels

An axis must never print a wrong number, which sets three rules for choosing ticks:

- Spacing is 1, 2, or 5 times a power of ten. Multiples of 2.5 are excluded because they need a
  digit more than the values around them, so a whole-number axis would get ticks at 2.5 and 7.5.
- By default, labels show as many digits as the spacing needs.
- With a custom formatter, spacing widens until no two labels read the same, including the next few
  multiples of the spacing. That catches rounding even when its twin isn't on the axis: with no
  decimals, 1.5 and 2 both read "2". If nothing within the size of the data works, only zero is
  labelled, because going further would flatten the data to fit a tidy axis.

### Extreme values


- **Very large values:** the scale divides by the largest magnitude before subtracting, so
  `-1e308...1e308` can't overflow.
- **Very small values:** the minimum stem length keeps a tiny value on its own side of the baseline
  instead of looking like zero. If the baseline would otherwise sit at the plot's edge, leaving
  no room on that side, the scale reserves the room. Set `minimumLength` to 0 to draw strictly to
  scale.
- **All zero:** a unit scale, with the baseline centred.
- **Non-finite values:** removed before any of this runs.

## Accessibility

VoiceOver doesn't read the visible text. It reads a separate layer of transparent elements:
one summary, and one element per point.

- **A point stays reachable when its label doesn't fit.** Its element is laid out over the marks
  whether or not the label is shown.
- **Direction is spoken in words,** such as "Positive, 11.05%", rather than through an arrow or
  colour.
- **Nothing is read twice,** and the axis and decorations aren't read at all.
- **Reading order is explicit.** SwiftUI would otherwise order elements by position, which would
  mix up points at different heights.
- **Large charts stay usable.** Only the 100 largest values get their own elements. Every value
  remains available in the Audio Graph.

## Data flow

Data flows one way. The chart owns no state, performs no asynchronous work, and has no view model,
because it has no state to manage: every update rebuilds the model from its inputs. This is cheap,
as `Documentation/Testing.md` measures. Everything is value types, and all of it is `Sendable`
without `@unchecked` annotations.

Consequently, the chart does not animate between datasets. `Canvas` redraws instantly, and
animating the views around it would pull labels out of step with the marks. So the chart disables
animation when its marks change, and leaves other animations alone.

## Architectural decisions

| Decision | Why |
|---|---|
| A neutral data model, without a generic adapter | `map` is one line and needs no API to learn. |
| No protocols for rendering or configuration | Each has one implementation. `ChartElementMeasuring` exists because it has two, the app's and the tests'. |
| No layout cache | Measured: a full render of 1,000 points takes about as long as 100. See `Testing.md`. |
| Text is measured for at most 100 points | Far fewer labels than that can fit, so this bounds the work whatever the dataset's size. |
| In-house snapshot testing | About 100 lines on `ImageRenderer`, compared with adding a dependency. |
| Default marker colours near 0.179 relative luminance | That is where contrast against white and black is equal, giving at least 4.5:1 on both. The package can't know the background it's on. |

## Extension strategy

New behaviour should arrive as additive configuration: a new property with a default value on an
existing struct, or a new case on an enum that callers don't need to switch over. Neither breaks
existing callers. `ChartStyle` deliberately has only a no-argument initializer for this reason, and
nested styles add new parameters at the end with defaults.

A new kind of decoration involves these steps:

1. Add the public configuration type and a property on `ChartConfiguration`.
2. Resolve it in `ChartModel`, mapping source indices to plotted positions.
3. Add a case to `ChartElementRole` and a frame to `ChartLayoutResult`.
4. Compute the frame in `ChartLayoutAssembler`, using `contained(_:in:)`.
5. Add the view to `ChartPlotView` in the right layer of the drawing order.
