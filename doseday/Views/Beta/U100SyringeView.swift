import SwiftUI

struct U100SyringeView: View {
    let drawUnits: Double
    let accentColor: Color
    let isOverflow: Bool

    private var clampedUnits: Double {
        min(max(drawUnits, 0), 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let plungerWidth = geometry.size.width * 0.16
                let needleWidth = geometry.size.width * 0.12
                let barrelWidth = geometry.size.width - plungerWidth - needleWidth - 12

                HStack(spacing: 6) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: plungerWidth, height: 22)
                        .overlay {
                            Capsule()
                                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                        }
                        .padding(.leading, 6)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 2)

                        GeometryReader { barrelGeometry in
                            let inset: CGFloat = 16
                            let scaleWidth = max(barrelGeometry.size.width - inset * 2, 1)
                            let markerX = scaleWidth * CGFloat(clampedUnits / 100)

                            ForEach(0...10, id: \.self) { index in
                                let ratio = CGFloat(index) / 10
                                let x = inset + (scaleWidth * ratio)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.45))
                                    .frame(width: 1, height: index.isMultiple(of: 5) ? 28 : 18)
                                    .offset(x: x, y: 10)
                            }

                            Rectangle()
                                .fill(isOverflow ? .orange : accentColor)
                                .frame(width: 4, height: barrelGeometry.size.height + 10)
                                .offset(x: inset + markerX - 2, y: -5)
                        }
                        .padding(.vertical, 6)
                    }
                    .frame(width: barrelWidth, height: 58)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: needleWidth * 0.35, height: 8)

                        NeedleShape()
                            .fill(Color.secondary.opacity(0.45))
                            .frame(width: needleWidth, height: 14)
                    }
                    .frame(width: needleWidth, height: 58)
                }
            }
            .frame(height: 70)

            HStack {
                ForEach([0, 25, 50, 75, 100], id: \.self) { tick in
                    Text("\(tick)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("U100 syringe")
        .accessibilityValue("\(clampedUnits.formatted(.number.precision(.fractionLength(0...1)))) units")
    }
}

private struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
