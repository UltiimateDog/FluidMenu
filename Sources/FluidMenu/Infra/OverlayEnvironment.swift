//
//  OverlayEnvironment.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 03/01/26.
//

import Foundation
import SwiftUI

/// An environment key used to inject an `OverlayManager`
/// into the SwiftUI environment.
private struct OverlayManagerKey: @preconcurrency EnvironmentKey {

    /// Default instance used when no `OverlayHost` is present.
    ///
    /// In practice, overlays will only work correctly when
    /// an `OverlayHost` provides a shared instance.
    @MainActor static let defaultValue = OverlayManager.shared
}

public extension EnvironmentValues {

    /// Accessor for the shared `OverlayManager`.
    ///
    /// Views can use this value to present or dismiss overlays
    /// without needing direct references or bindings.
    var overlayManager: OverlayManager {
        get { self[OverlayManagerKey.self] }
        set { self[OverlayManagerKey.self] = newValue }
    }
}
