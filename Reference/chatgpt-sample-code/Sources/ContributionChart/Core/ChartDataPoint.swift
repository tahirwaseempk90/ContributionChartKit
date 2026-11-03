import SwiftUI

/// One labeled contribution or detractor. Positive values extend above zero;
/// negative values extend below zero.
public struct ChartDataPoint: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let value: Double

    public init(id: String = UUID().uuidString, title: String, value: Double) {
        self.id = id
        self.title = title
        self.value = value
    }

    public var isPositive: Bool { value >= 0 }
}
