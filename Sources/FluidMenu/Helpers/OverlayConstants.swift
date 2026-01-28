//
//  OverlayConstants.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 04/01/26.
//

import Foundation
import SwiftUI

/// Centralized constants used by the overlay system.
///
/// `OverlayConstants` defines shared values that control coordinate spaces,
/// layout constraints, transitions, and visual styling for all overlay-based
/// components (e.g. context menus, popovers, floating panels).
///
/// Centralizing these values ensures:
/// - Consistent overlay behavior and appearance
/// - Predictable geometry calculations
/// - Safer refactoring and design iteration
///
/// These constants are consumed by:
/// - `OverlayHost` (coordinate spaces & bounds)
/// - `OverlayService` (layout & overflow calculations)
/// - Overlay views (styling, transitions, sizing)
public enum OverlayConstants {

    // MARK: - Coordinate Spaces

    /// Named coordinate space used by the overlay system.
    ///
    /// This coordinate space is established by `OverlayHost` and is
    /// required for accurate geometry capture and placement of overlays.
    /// All geometry calculations performed by the overlay system assume
    /// frames are measured within this space.
    nonisolated(unsafe) public static let coordinateSpace: CoordinateSpace = .named("OverlayCoordinateSpace")

    /// Named space used for matched geometry effects within overlay menus.
    ///
    /// This identifier must remain stable across both the source view
    /// and the overlay content to ensure correct animation behavior.
    public static let menuSpaceName: String = "contextMenuSpace"

    // MARK: - Layout & Sizing

    /// Horizontal margin applied when snapping overlays to layout bounds.
    ///
    /// This value is used by `OverlayService` when calculating placement
    /// and overflow detection, and should remain in sync with visual
    /// spacing expectations.
    public static let menuMargin: CGFloat = 10

    /// Fixed width applied to context menu overlays.
    ///
    /// The overlay placement logic assumes a fixed width when calculating
    /// horizontal positioning. Changing this value affects both layout
    /// and overflow behavior.
    public static let menuWidth: CGFloat = 250

    /// Minimum height for context menu content.
    ///
    /// This ensures menus maintain a minimum tap target size and
    /// prevents overly compact layouts when content is small.
    public static let menuMinHeight: CGFloat = 100

    /// Corner radius applied to menu containers and masks.
    ///
    /// This value must remain consistent across the background container
    /// and content mask to preserve visual alignment during animations.
    public static let menuCornerRadius: CGFloat = 40

    // MARK: - Visual Styling

    /// Default background color used for dismissable overlay layers.
    ///
    /// This color is typically transparent but exists as a centralized
    /// styling hook for future customization.
    public static let backgroundColor: Color = .clear

    /// Tint color applied to liquid glass backgrounds.
    ///
    /// This value controls the intensity of the glass effect and
    /// should align with the app’s overall accent and material design.
    public static let menuGlassTint: Color = .blue.opacity(0.1)

    // MARK: - Transitions

    /// Transition applied when presenting and dismissing context menus.
    ///
    /// The asymmetric configuration ensures the menu appears instantly
    /// (to preserve spatial continuity) while fading out smoothly on
    /// dismissal.
    @MainActor public static let contextMenuTransition: AnyTransition =
        .asymmetric(insertion: .identity, removal: .opacity)
}
