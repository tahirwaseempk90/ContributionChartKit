/// How a ``ContributionChart`` maps values to vertical positions.
///
/// Every mode uses one linear scale and always includes zero, so equal magnitudes are
/// equally long on both sides of the baseline and the comparison stays honest.
public enum ChartScaleMode: Sendable, Hashable {
    /// Fits the scale to the data, so the baseline moves to wherever zero falls.
    ///
    /// This is the default because it uses the available height fully. All-positive data
    /// fills the chart above a baseline at the bottom, where a centred baseline would leave
    /// half the chart empty.
    case proportional

    /// Extends the scale equally in both directions, keeping the baseline centred.
    ///
    /// Use this when the middle of the chart should always mean zero, such as in a row of
    /// small charts. It leaves one side partly empty when the data is lopsided.
    case symmetric

    /// Uses exactly the range you provide.
    ///
    /// Use this to give several charts the same scale. A range that excludes zero is
    /// extended to reach it, and values outside the range are drawn at its nearest edge
    /// while their labels keep showing the real value.
    ///
    /// - Parameters:
    ///   - lower: The value at the bottom of the plot.
    ///   - upper: The value at the top of the plot.
    case fixed(lower: Double, upper: Double)
}
