import Foundation

/// Deterministic, seedable pseudo-random generator (SplitMix64).
/// Used so every puzzle is reproducible from a single seed value across
/// app launches and the standalone validator.
struct HashiRandom {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state producing a degenerate stream.
        self.state = seed &+ 0x9E3779B97F4A7C15
        if self.state == 0 { self.state = 0xD1B54A32D192ED03 }
    }

    mutating func nextU64() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform integer in 0..<bound (bound must be > 0).
    mutating func int(_ bound: Int) -> Int {
        precondition(bound > 0, "bound must be positive")
        return Int(nextU64() % UInt64(bound))
    }

    /// Inclusive integer in low...high.
    mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        return range.lowerBound + int(span)
    }

    /// Random Double in 0..<1.
    mutating func double() -> Double {
        return Double(nextU64() >> 11) * (1.0 / 9007199254740992.0)
    }

    /// True with the given probability (0...1).
    mutating func chance(_ p: Double) -> Bool {
        return double() < p
    }

    /// In-place Fisher-Yates shuffle.
    mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = int(i + 1)
            array.swapAt(i, j)
        }
    }

    /// Returns a shuffled copy.
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var copy = array
        shuffle(&copy)
        return copy
    }
}

/// Mix several integers into one 64-bit seed deterministically.
func mixSeed(_ values: [UInt64]) -> UInt64 {
    var h: UInt64 = 0xCBF29CE484222325
    for v in values {
        h = (h ^ v) &* 0x100000001B3
        h ^= h >> 29
    }
    if h == 0 { h = 0x1234567890ABCDEF }
    return h
}
