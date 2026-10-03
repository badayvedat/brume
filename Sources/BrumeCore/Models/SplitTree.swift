import CoreGraphics

public enum SplitAxis: Codable, Sendable {
    /// Côte à côte.
    case horizontal
    /// L'un sous l'autre.
    case vertical
}

public enum SplitDirection: Sendable {
    case left, right, up, down

    /// Le bord le plus proche : les diagonales coupent le volet en quatre triangles,
    /// sans zone morte.
    public static func nearestEdge(to point: CGPoint, in rect: CGRect) -> SplitDirection {
        let x = (point.x - rect.minX) / rect.width
        let y = (point.y - rect.minY) / rect.height
        let distances: [(SplitDirection, CGFloat)] = [(.left, x), (.right, 1 - x), (.up, y), (.down, 1 - y)]
        return distances.min { $0.1 < $1.1 }!.0
    }

    /// La moitié du volet que prendra ce qu'on y dépose.
    public func half(of rect: CGRect) -> CGRect {
        switch self {
        case .left: rect.divided(atDistance: rect.width / 2, from: .minXEdge).slice
        case .right: rect.divided(atDistance: rect.width / 2, from: .maxXEdge).slice
        case .up: rect.divided(atDistance: rect.height / 2, from: .minYEdge).slice
        case .down: rect.divided(atDistance: rect.height / 2, from: .maxYEdge).slice
        }
    }
}

/// Une séparation qu'on peut glisser. `path` la retrouve dans l'arbre : 0 = premier, 1 = second.
public struct SplitDivider: Hashable, Sendable {
    public static let ratioRange: ClosedRange<CGFloat> = 0.15 ... 0.85

    public let path: [Int]
    public let axis: SplitAxis
    public let line: CGRect
    /// Toute la zone de la division, pour traduire une position en ratio.
    public let container: CGRect

    public func ratio(at location: CGPoint) -> CGFloat {
        let raw = switch axis {
        case .horizontal: (location.x - container.minX) / container.width
        case .vertical: (location.y - container.minY) / container.height
        }
        return min(max(raw, Self.ratioRange.lowerBound), Self.ratioRange.upperBound)
    }
}

public indirect enum SplitTree<Pane: Hashable & Sendable>: Hashable, Sendable {
    case pane(Pane)
    /// `ratio` : la part du premier volet.
    case split(SplitAxis, ratio: CGFloat, SplitTree, SplitTree)

    /// Dans l'ordre de lecture : gauche avant droite, haut avant bas.
    public var panes: [Pane] {
        switch self {
        case let .pane(pane): [pane]
        case let .split(_, _, first, second): first.panes + second.panes
        }
    }

    /// Pose `subtree` (un volet, ou les splits d'un autre onglet) du côté `direction` de `target`.
    public func inserting(_ subtree: SplitTree, beside target: Pane, toward direction: SplitDirection) -> SplitTree {
        switch self {
        case let .pane(pane) where pane == target:
            let axis: SplitAxis = direction == .left || direction == .right ? .horizontal : .vertical
            return direction == .left || direction == .up
                ? .split(axis, ratio: 0.5, subtree, self)
                : .split(axis, ratio: 0.5, self, subtree)
        case .pane:
            return self
        case let .split(axis, ratio, first, second):
            return .split(
                axis,
                ratio: ratio,
                first.inserting(subtree, beside: target, toward: direction),
                second.inserting(subtree, beside: target, toward: direction)
            )
        }
    }

    /// `nil` quand le dernier volet part. Le voisin reprend toute la place.
    public func removing(_ target: Pane) -> SplitTree? {
        switch self {
        case let .pane(pane):
            return pane == target ? nil : self
        case let .split(axis, ratio, first, second):
            switch (first.removing(target), second.removing(target)) {
            case let (first?, second?): return .split(axis, ratio: ratio, first, second)
            case let (remaining?, nil), let (nil, remaining?): return remaining
            case (nil, nil): return nil
            }
        }
    }

    public func frames(in rect: CGRect) -> [Pane: CGRect] {
        switch self {
        case let .pane(pane):
            return [pane: rect]
        case let .split(axis, ratio, first, second):
            let (firstRect, secondRect) = Self.divide(rect, axis: axis, ratio: ratio)
            return first.frames(in: firstRect).merging(second.frames(in: secondRect)) { current, _ in current }
        }
    }

    /// Une par division, posée sur la frontière entre ses deux volets.
    public func dividers(in rect: CGRect, path: [Int] = []) -> [SplitDivider] {
        guard case let .split(axis, ratio, first, second) = self else { return [] }
        let (firstRect, secondRect) = Self.divide(rect, axis: axis, ratio: ratio)
        let line = switch axis {
        case .horizontal: CGRect(x: secondRect.minX, y: rect.minY, width: 0, height: rect.height)
        case .vertical: CGRect(x: rect.minX, y: secondRect.minY, width: rect.width, height: 0)
        }
        return [SplitDivider(path: path, axis: axis, line: line, container: rect)]
            + first.dividers(in: firstRect, path: path + [0])
            + second.dividers(in: secondRect, path: path + [1])
    }

    /// La même disposition, aux proportions près.
    public func hasSameShape(as other: SplitTree) -> Bool {
        switch (self, other) {
        case let (.pane(a), .pane(b)):
            a == b
        case let (.split(axis, _, first, second), .split(otherAxis, _, otherFirst, otherSecond)):
            axis == otherAxis && first.hasSameShape(as: otherFirst) && second.hasSameShape(as: otherSecond)
        default:
            false
        }
    }

    /// `a` prend la place de `b`, et l'inverse.
    public func swapping(_ a: Pane, _ b: Pane) -> SplitTree {
        switch self {
        case let .pane(pane): .pane(pane == a ? b : pane == b ? a : pane)
        case let .split(axis, ratio, first, second): .split(axis, ratio: ratio, first.swapping(a, b), second.swapping(a, b))
        }
    }

    public func settingRatio(_ newRatio: CGFloat, at path: [Int]) -> SplitTree {
        guard case let .split(axis, ratio, first, second) = self else { return self }
        guard let step = path.first else {
            return .split(axis, ratio: newRatio, first, second)
        }
        let rest = Array(path.dropFirst())
        return step == 0
            ? .split(axis, ratio: ratio, first.settingRatio(newRatio, at: rest), second)
            : .split(axis, ratio: ratio, first, second.settingRatio(newRatio, at: rest))
    }

    /// Tous les volets à la même taille, comme `equalize_splits` de Ghostty : chaque côté
    /// pèse le nombre de volets qu'il aligne dans le sens de la division.
    public func equalized() -> SplitTree {
        guard case let .split(axis, _, first, second) = self else { return self }
        let firstWeight = first.weight(along: axis)
        let ratio = CGFloat(firstWeight) / CGFloat(firstWeight + second.weight(along: axis))
        return .split(axis, ratio: ratio, first.equalized(), second.equalized())
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

    private func weight(along axis: SplitAxis) -> Int {
        guard case let .split(splitAxis, _, first, second) = self, splitAxis == axis else { return 1 }
        return first.weight(along: axis) + second.weight(along: axis)
    }

    private func cycle(from pane: Pane, by step: Int) -> Pane? {
        let all = panes
        guard let index = all.firstIndex(of: pane) else { return nil }
        return all[(index + step + all.count) % all.count]
    }

    private static func divide(_ rect: CGRect, axis: SplitAxis, ratio: CGFloat) -> (CGRect, CGRect) {
        switch axis {
        case .horizontal:
            rect.divided(atDistance: rect.width * ratio, from: .minXEdge)
        case .vertical:
            rect.divided(atDistance: rect.height * ratio, from: .minYEdge)
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

extension SplitTree: Codable where Pane: Codable {}
