import Core
import SwiftUI

/// The colored bar of a template: one segment per phase, as wide as its duration.
///
/// Drawn instead of assembled from views: a plan with 99 rounds would otherwise need hundreds of
/// views per card. Gaps only while the segments are wide enough, otherwise the bar blurs.
public struct SequenceBar: View {
    let plan: PhasePlan
    var height: CGFloat

    public init(plan: PhasePlan, height: CGFloat = 8) {
        self.plan = plan
        self.height = height
    }

    public var body: some View {
        Canvas { ctx, size in
            guard plan.total > 0 else { return }
            let gap: CGFloat = plan.phases.count * 4 < Int(size.width) / 2 ? 2 : 0
            let usable = size.width - gap * CGFloat(max(plan.phases.count - 1, 0))
            var x: CGFloat = 0
            for p in plan.phases {
                let b = usable * CGFloat(p.duration) / CGFloat(plan.total)
                ctx.fill(
                    Path(CGRect(x: x, y: 0, width: b, height: size.height)),
                    with: .color(Palette.fill(p.kind)))
                x += b + gap
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

extension PhaseKind {
    /// The phase name from the catalog.
    public var title: LocalizedStringKey {
        switch self {
        case .preparation: "phase.preparation"
        case .active: "phase.work"
        case .rest: "phase.rest"
        case .circuitRest: "phase.circuitRest"
        case .cooldown: "phase.cooldown"
        }
    }

    /// Short form for the run screen: the rest between circuits is simply called "Rest" there.
    public var shortTitle: LocalizedStringKey {
        self == .circuitRest ? "phase.rest" : title
    }

    public var titleText: String {
        switch self {
        case .preparation: localized("phase.preparation")
        case .active: localized("phase.work")
        case .rest, .circuitRest: localized("phase.rest")
        case .cooldown: localized("phase.cooldown")
        }
    }
}
