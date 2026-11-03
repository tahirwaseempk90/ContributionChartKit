# Architecture

- **Core**: immutable, application-neutral data and configuration.
- **Rendering**: pure geometry and scale calculations; no API or app state.
- **Components**: small private SwiftUI primitives.
- **Public facade**: `ContributionChart`, the only view consumers need to construct.

The rendering engine is deterministic and independently unit-testable. The chart
does not own networking, persistence, view models, or selection state.

## Extension points

A future major version can add axis policies, selection callbacks, custom annotation
content, accessibility summaries, and alternate layouts without coupling those
features to the data model.
