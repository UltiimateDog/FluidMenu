//
//  OverlayEnums.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 06/01/26.
//

import Foundation

/// Describes whether an overlay exceeds its available bounds.
public struct OverlayOverflow: Equatable {

    /// `true` if the overlay exceeds the horizontal bounds (including margins).
    let xOverflow: Bool

    /// `true` if the overlay exceeds the vertical bounds.
    let yOverflow: Bool

    /// Convenience flag indicating any overflow.
    var hasOverflow: Bool {
        xOverflow || yOverflow
    }
}
