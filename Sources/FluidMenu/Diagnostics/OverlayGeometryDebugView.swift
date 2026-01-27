//
//  OverlayGeometryDebugView.swift
//  FluidMenu
//
//  Created by Ultiimate Dog on 26/01/26.
//

import SwiftUI

/// Renders a debug-only visualization of overlay bounds and safe area insets.
///
/// This view is intended strictly for development and debugging purposes.
/// It visualizes the geometry information published to `OverlayManager`
/// and should not be relied upon for production behavior.
///
/// - Note: This view does not influence layout or overlay placement.
///         It is purely visual and non-interactive.
struct OverlayGeometryDebugView: View {
    // MARK: - ATTRIBUTES
    let manager: OverlayManager
    
    // MARK: - BODY
    var body: some View {
        GeometryReader { _ in
            let bounds = manager.overlayBounds
            let insets = manager.safeAreaInsets
            
            let xValues = (bounds.minX.formatted(), bounds.midX.formatted(), bounds.maxX.formatted())
            let yValues = (bounds.minY.formatted(), bounds.midY.formatted(), bounds.maxY.formatted())
            
            ZStack {
                // MARK: - Boxes
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.red.opacity(0.2))
                        .frame(height: insets.top)
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(.red.opacity(0.2))
                            .frame(width: insets.leading)
                        
                        Rectangle()
                            .fill(.green.opacity(0.2))
                            .frame(width: bounds.width, height: bounds.height)
                        
                        Rectangle()
                            .fill(.red.opacity(0.2))
                            .frame(width: insets.trailing)
                    }
                    
                    Rectangle()
                        .fill(.red.opacity(0.2))
                        .frame(height: insets.bottom)
                }
                
#if DEBUG
                // MARK: - Labels
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "Bounds: \(bounds.size)")
                    Text(verbatim: "   origin: \(bounds.origin.debugDescription)")
                    Text(verbatim: "  (minX, midX, maxX): \(xValues)")
                    Text(verbatim: "  (minY, midY, maxY): \(yValues)")
                    Text(verbatim: "SafeArea: \(insets)")
                }
                .padding()
                .font(.caption2)
                .background(.black.opacity(0.7))
                .foregroundStyle(.white)
                .cornerRadius(6)
                .offset(y: -100)
#endif
            }
            .ignoresSafeArea()
        }//: Geometry
        .allowsHitTesting(false)
        .zIndex(998)
    }
}

#Preview {
    OverlayGeometryDebugView(manager: OverlayManager.shared)
}
