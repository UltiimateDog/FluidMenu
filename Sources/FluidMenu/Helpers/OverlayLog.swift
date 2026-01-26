//
//  OverlayLog.swift
//  FluidMenu
//
//  Created by Ultiimate Dog on 26/01/26.
//

import Foundation
import os

/// Centralized logging namespace for the Overlay system.
///
/// `OverlayLog` defines scoped `Logger` instances used across the package,
/// making it easy to categorize and filter logs by responsibility
/// (host, manager, service).
enum OverlayLog {

    /// Shared logging subsystem identifier for the package.
    ///
    /// This should remain stable to allow consistent log filtering
    /// in Console and other logging tools.
    static let subsystem = "com.cardboardsoftware.FluidMenu"

    /// Logger for overlay hosting and lifecycle-related events.
    static let host = Logger(
        subsystem: subsystem,
        category: "OverlayHost"
    )

    /// Logger for overlay management and coordination logic.
    static let manager = Logger(
        subsystem: subsystem,
        category: "OverlayManager"
    )
    
    /// Logger for overlay services and background operations.
    static let service = Logger(
        subsystem: subsystem,
        category: "OverlayService"
    )
}


