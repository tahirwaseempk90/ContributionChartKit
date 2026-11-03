# Public API

### `ChartDataPoint`
- `id`: stable identity for SwiftUI diffing.
- `title`: annotation title.
- `value`: signed numeric value; positive is above zero and negative below.

### `ChartConfiguration`
Configures colors, line and marker dimensions, insets, text sizing, baseline label,
and value formatting.

### `ContributionChart`
Initialize with `[ChartDataPoint]` and an optional `ChartConfiguration`.
Give it a height using its parent layout.
