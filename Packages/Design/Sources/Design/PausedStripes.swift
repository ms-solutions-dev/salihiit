import SwiftUI

/// The phase color in diagonal stripes: this is what a paused workout looks like. A small "Paused"
/// label alone was too easy to miss from a distance.
public struct PausedStripes: View {
    let color: Color
    var width: CGFloat = 18

    public init(color: Color, width: CGFloat = 18) {
        self.color = color
        self.width = width
    }

    public var body: some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
            var stripes = Path()
            let step = width * 2
            var x = -size.height
            while x < size.width {
                stripes.move(to: CGPoint(x: x, y: size.height))
                stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                stripes.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                stripes.addLine(to: CGPoint(x: x + width, y: size.height))
                stripes.closeSubpath()
                x += step
            }
            c.fill(stripes, with: .color(.black.opacity(0.14)))
        }
        .accessibilityHidden(true)
    }
}

/// The large ‖ above the digits of a paused workout.
public struct PauseGlyph: View {
    let height: CGFloat

    public init(height: CGFloat) {
        self.height = height
    }

    public var body: some View {
        HStack(spacing: height * 0.28) {
            RoundedRectangle(cornerRadius: height * 0.08).frame(width: height * 0.26)
            RoundedRectangle(cornerRadius: height * 0.08).frame(width: height * 0.26)
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(Text(app: "run.paused"))
    }
}
