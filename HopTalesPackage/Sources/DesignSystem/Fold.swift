import SwiftUI

public struct Fold: Equatable, Sendable {
  public var frame: CGRect

  public init(_ frame: CGRect) {
    self.frame = frame
  }

  public var runsAcross: Bool { frame.width >= frame.height }

  public func room(in size: CGSize) -> CGRect {
    if runsAcross {
      return CGRect(
        x: 0, y: frame.maxY, width: size.width, height: max(0, size.height - frame.maxY)
      )
    }
    return CGRect(
      x: frame.maxX, y: 0, width: max(0, size.width - frame.maxX), height: size.height
    )
  }
}

extension Fold {
  public func stage(in size: CGSize) -> CGRect {
    if runsAcross {
      return CGRect(x: 0, y: 0, width: size.width, height: max(0, frame.minY))
    }
    return CGRect(x: 0, y: 0, width: max(0, frame.minX), height: size.height)
  }
}

extension EnvironmentValues {
  @Entry public var simulatedFold: Fold?
}

extension GeometryProxy {
  public func fold(or simulated: Fold?) -> Fold? {
    if #available(iOS 27.1, *),
       let region = reservedRegions(kind: .division).first(where: \.isActive) {
      return Fold(region.frame)
    }
    return simulated
  }
}
