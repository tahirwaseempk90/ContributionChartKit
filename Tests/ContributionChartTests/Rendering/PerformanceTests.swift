import SwiftUI
import XCTest
@testable import ContributionChart

/// Measures how the chart scales with its data, for the table in `Documentation/Testing.md`.
///
/// Absolute times depend on the machine and on debug builds, so the assertions are generous
/// limits that catch a change in complexity rather than a small slowdown. Use the printed
/// table, not the assertions, to judge real performance.
@MainActor
final class PerformanceTests: XCTestCase {
    private let size = CGSize(width: 393, height: 300)
    private let counts = [3, 10, 50, 100, 500, 1000]

    private func milliseconds(_ operation: () -> Void) -> Double {
        let clock = ContinuousClock()
        let duration = clock.measure(operation)
        let components = duration.components
        return Double(components.seconds) * 1000 + Double(components.attoseconds) / 1e15
    }

    /// The fastest of several runs, which is the least affected by other activity on the machine.
    private func fastest(runs: Int = 5, _ operation: () -> Void) -> Double {
        (0..<runs).map { _ in milliseconds(operation) }.min() ?? 0
    }

    func testScalingReport() {
        var lines = ["points |  model ms | layout ms | render ms | labels shown"]
        for count in counts {
            let points = Fixtures.dense(count)
            let configuration = ChartConfiguration()
            let model = ChartModel(points: points, title: "Title", configuration: configuration)
            let engine = ChartLayoutEngine(model: model, displayScale: 3)
            let measurer = StubMeasurer()

            let modelTime = fastest { _ = ChartModel(points: points, title: "Title", configuration: configuration) }
            let layoutTime = fastest { _ = engine.layout(in: size, measuring: measurer) }
            let chart = ContributionChart(points: points, title: "Title", configuration: configuration)
            let renderTime = fastest(runs: 3) {
                _ = ChartRendering.image(of: chart, proposal: ProposedViewSize(size))
            }
            let labels = engine.layout(in: size, measuring: measurer).annotations.filter(\.isVisible).count
            lines.append(
                String(format: "%6d | %9.2f | %9.2f | %9.2f | %d", count, modelTime, layoutTime, renderTime, labels)
            )

            XCTAssertLessThan(modelTime + layoutTime, 250, "Model and layout at \(count) points")
            XCTAssertLessThan(renderTime, 3000, "Render at \(count) points")
        }
        print(lines.joined(separator: "\n"))
    }

    /// Text is measured for at most this many points, however large the dataset is.
    func testWorkPerLayoutIsBoundedByTheProminentPointLimit() {
        let counter = MeasurementCounter()
        let engine = makeEngine(Fixtures.dense(5000))
        _ = engine.layout(in: size, measuring: counter)
        XCTAssertLessThanOrEqual(counter.box.count, ChartModel.prominentPointLimit)
    }

    func testModelBuildPerformanceAtAThousandPoints() {
        let points = Fixtures.dense(1000)
        measure {
            _ = ChartModel(points: points, title: nil, configuration: ChartConfiguration())
        }
    }

    func testLayoutPerformanceAtAThousandPoints() {
        let engine = makeEngine(Fixtures.dense(1000))
        let measurer = StubMeasurer()
        measure {
            _ = engine.layout(in: size, measuring: measurer)
        }
    }

    func testRenderPerformanceAtAThousandPoints() {
        let chart = ContributionChart(points: Fixtures.dense(1000))
        measure {
            _ = ChartRendering.image(of: chart, proposal: ProposedViewSize(size))
        }
    }
}

private final class MeasurementCounter: ChartElementMeasuring {
    final class Box {
        var count = 0
    }

    let box = Box()

    func headerSize(proposedWidth: CGFloat) -> CGSize {
        .zero
    }

    func annotationSize(at index: Int, proposedWidth: CGFloat) -> CGSize {
        box.count += 1
        return CGSize(width: 40, height: 20)
    }

    func tickLabelSize(at index: Int) -> CGSize {
        .zero
    }
}
