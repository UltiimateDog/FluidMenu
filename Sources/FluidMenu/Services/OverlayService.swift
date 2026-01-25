//
//  OverlayService.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 05/01/26.
//

import Foundation
import CoreGraphics

/// A service responsible for calculating overlay placement relative to a source frame.
public struct OverlayService {
    
    // MARK: - Placement
    
    /// Calculates the center point for positioning an overlay within given bounds.
    ///
    /// The placement logic follows these rules:
    ///
    /// ### Vertical positioning
    /// 1. Prefer placing the overlay *below* the source frame if there is enough
    ///    vertical space within `bounds`.
    /// 2. Otherwise, place it *above* the source frame if it fits.
    /// 3. As a fallback, clamp the overlay to the top edge of `bounds`.
    ///
    /// ### Horizontal positioning
    /// - The overlay always expands to the **right** of the source frame.
    /// - If there is insufficient space to the right (including the configured
    ///   margin), the overlay is clamped to the trailing edge of `bounds`.
    /// - This ensures the overlay’s origin remains visually anchored to the
    ///   source frame, regardless of device size.
    ///
    /// ### Rationale
    /// Earlier versions attempted to snap overlays left or right based on the
    /// source frame’s position within the screen. On larger devices (e.g. iPad),
    /// this caused overlays originating near the center to appear detached from
    /// their source, seemingly materializing from the middle of the screen.
    ///
    /// Always expanding to the right preserves a consistent spatial relationship
    /// between the source and overlay across all device sizes and orientations.
    ///
    /// ### Validation
    /// - Overflow detection is delegated to `overflow(overlaySize:bounds:margin:)`.
    /// - If the overlay exceeds available bounds on either axis, the condition
    ///   is logged as a layout bug.
    ///
    /// The overlay is still positioned using clamping rules, but visual correctness
    /// is not guaranteed when overflow occurs.
    ///
    /// - Parameters:
    ///   - sourceFrame: The frame the overlay originates from (e.g. a button or label).
    ///   - overlaySize: The size of the overlay to be positioned.
    ///   - bounds: The available area the overlay must fit within (e.g. safe area).
    ///   - margin: The horizontal margin applied when clamping to the bounds.
    ///
    /// - Returns: The center point (`CGPoint`) where the overlay should be positioned.
    public static func placement(
        sourceFrame: CGRect,
        overlaySize: CGSize,
        bounds: CGRect,
        margin: CGFloat = OverlayConstants.menuMargin
    ) -> CGPoint {
        // MARK: - Vertical placement
        // Prefer expanding below the source frame, then above, then clamp to bounds.
        let y: CGFloat = {
            let halfHeight = overlaySize.height / 2
            
            if sourceFrame.minY + overlaySize.height <= bounds.maxY {
                return sourceFrame.minY + halfHeight
            }
            
            if overlaySize.height <= sourceFrame.maxY - bounds.minY {
                return sourceFrame.maxY - halfHeight
            }
            
            // Fallback: clamp to top of bounds
            return bounds.minY + halfHeight
        }()
        
        // MARK: - Horizontal placement
        // Prefer expanding to the right
        let x: CGFloat = {
            let halfWidth = overlaySize.width / 2
            
            if sourceFrame.minX + overlaySize.width + margin <= bounds.maxX {
                return sourceFrame.minX + halfWidth
            }
            
            // Snap to the right
            return bounds.maxX - halfWidth - margin
        }()
        
        // MARK: - Validation / Logging
        let overflow = overflow(
            overlaySize: overlaySize,
            bounds: bounds,
            margin: margin
        )
        
        if overflow.xOverflow {
            NSLog(
                """
                [OverlayService] Overlay width exceeds available bounds.
                Overlay width: \(overlaySize.width),
                Horizontal margins: \(margin * 2),
                Available width: \(bounds.width).
                This indicates a layout bug and should be investigated.
                """
            )
#if DEBUG
            print("[OverlayService] Overlay width exceeds available bounds (\(overlaySize.width) > \(bounds.width))")
#endif
        }
        
        if overflow.yOverflow {
            NSLog(
                """
                [OverlayService] Overlay height exceeds available bounds.
                Overlay height: \(overlaySize.height),
                Available height: \(bounds.height).
                This indicates a layout bug and should be investigated.
                """
            )
#if DEBUG
            print("[OverlayService] Overlay height exceeds available bounds (\(overlaySize.height) > \(bounds.height))")
#endif
        }
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Overflow
    
    /// Determines whether an overlay exceeds the available bounds.
    ///
    /// This function **does not clamp or correct layout**, it only reports overflow.
    ///
    /// - Parameters:
    ///   - overlaySize: The size of the overlay.
    ///   - bounds: The available layout bounds.
    ///   - margin: Horizontal margin applied to the overlay.
    ///
    /// - Returns: An `OverlayOverflow` describing which axes overflow.
    public static func overflow(
        overlaySize: CGSize,
        bounds: CGRect,
        margin: CGFloat = OverlayConstants.menuMargin
    ) -> OverlayOverflow {
        
        let xOverflow = overlaySize.width + (2 * margin) > bounds.width
        let yOverflow = overlaySize.height > bounds.height
        
        return OverlayOverflow(
            xOverflow: xOverflow,
            yOverflow: yOverflow
        )
    }
}
