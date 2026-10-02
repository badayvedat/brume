import CoreGraphics

public enum SplitAxis: Sendable {
    /// Côte à côte.
    case horizontal
    /// L'un sous l'autre.
    case vertical
}

public enum SplitDirection: Sendable {
    case left, right, up, down
}

public indirect enum SplitTree<Pane: Hashable & Sendable>: Hashable, Sendable {
    case pane(Pane)
    case split(SplitAxis, SplitTree, SplitTree)

    /// Dans l'ordre de lecture : gauche avant droite, haut avant bas.
    public var panes: [Pane] {
        switch self {
        case let .pane(pane): [pane]
        case let .split(_, first, second): first.panes + second.panes
        }
    }

    public func splitting(_ target: Pane, axis: SplitAxis, adding new: Pane) -> SplitTree {
        switch self {
        case let .pane(pane) where pane == target:
            .split(axis, .pane(pane), .pane(new))
        case .pane:
            self
        case let .split(splitAxis, first, second):
            .split(
                splitAxis,
                first.splitting(target, axis: axis, adding: new),
                second.splitting(target, axis: axis, adding: new)
            )
        }
    }

    /// `nil` quand le dernier volet part. Le voisin reprend toute la place.
    public func removing(_ target: Pane) -> SplitTree? {
        switch self {
        case let .pane(pane):
            return pane == target ? nil : self
        case let .split(axis, first, second):
            switch (first.removing(target), second.removing(target)) {
            case let (first?, second?): return .split(axis, first, second)
            case let (remaining?, nil), let (nil, remaining?): return remaining
            case (nil, nil): return nil
            }
        }
    }

    public func frames(in rect: CGRect) -> [Pane: CGRect] {
        switch self {
        case let .pane(pane):
            return [pane: rect]
        case let .split(axis, first, second):
            let (firstRect, secondRect) = Self.halves(of: rect, axis: axis)
            return first.frames(in: firstRect).merging(second.frames(in: secondRect)) { current, _ in current }
        }
    }

    /// Les traits de séparation, un par division, sur la frontière entre les deux moitiés.
    public func dividers(in rect: CGRect) -> [CGRect] {
        guard case let .split(axis, first, second) = self else { return [] }
        let (firstRect, secondRect) = Self.halves(of: rect, axis: axis)
        let line = switch axis {
        case .horizontal: CGRect(x: secondRect.minX, y: rect.minY, width: 0, height: rect.height)
        case .vertical: CGRect(x: rect.minX, y: secondRect.minY, width: rect.width, height: 0)
        }
        return [line] + first.dividers(in: firstRect) + second.dividers(in: secondRect)
    }

    public func pane(after pane: Pane) -> Pane? {
        cycle(from: pane, by: 1)
    }

    public func pane(before pane: Pane) -> Pane? {
        cycle(from: pane, by: -1)
    }

    /// Le volet le plus proche dans cette direction ; à égalité, le premier dans l'ordre de lecture.
    public func neighbor(of pane: Pane, toward direction: SplitDirection) -> Pane? {
        let frames = frames(in: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let origin = frames[pane] else { return nil }
        let candidates = panes.filter { other in
            guard other != pane, let frame = frames[other] else { return false }
            return switch direction {
            case .left: frame.maxX <= origin.minX && Self.overlaps(frame.minY, frame.maxY, origin.minY, origin.maxY)
            case .right: frame.minX >= origin.maxX && Self.overlaps(frame.minY, frame.maxY, origin.minY, origin.maxY)
            case .up: frame.maxY <= origin.minY && Self.overlaps(frame.minX, frame.maxX, origin.minX, origin.maxX)
            case .down: frame.minY >= origin.maxY && Self.overlaps(frame.minX, frame.maxX, origin.minX, origin.maxX)
            }
        }
        // min(by:) garde le premier des ex aequo.
        return candidates.min { lhs, rhs in
            Self.distance(frames[lhs]!, origin, direction) < Self.distance(frames[rhs]!, origin, direction)
        }
    }

    private func cycle(from pane: Pane, by step: Int) -> Pane? {
        let all = panes
        guard let index = all.firstIndex(of: pane) else { return nil }
        return all[(index + step + all.count) % all.count]
    }

    private static func halves(of rect: CGRect, axis: SplitAxis) -> (CGRect, CGRect) {
        switch axis {
        case .horizontal:
            rect.divided(atDistance: rect.width / 2, from: .minXEdge)
        case .vertical:
            rect.divided(atDistance: rect.height / 2, from: .minYEdge)
        }
    }

    private static func overlaps(_ aMin: CGFloat, _ aMax: CGFloat, _ bMin: CGFloat, _ bMax: CGFloat) -> Bool {
        min(aMax, bMax) - max(aMin, bMin) > 0.0001
    }

    private static func distance(_ frame: CGRect, _ origin: CGRect, _ direction: SplitDirection) -> CGFloat {
        switch direction {
        case .left: origin.minX - frame.maxX
        case .right: frame.minX - origin.maxX
        case .up: origin.minY - frame.maxY
        case .down: frame.minY - origin.maxY
        }
    }
}
