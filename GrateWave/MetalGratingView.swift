//
//  MetalGratingView.swift
//  GrateWave
//
//  Created by Eli J on 12/17/25.
//

import SwiftUI
import MetalKit
internal import Combine

final class GratingParams: ObservableObject {
    @Published var frequency: Double = 0.01
    @Published var orientationDeg: Double = 0
    @Published var contrast: Double = 1.0
    @Published var mean: Double = 0.5
    @Published var driftEnabled: Bool = false
    @Published var phaseVelocity: Double = 0.0
}

struct MetalGratingView: UIViewRepresentable {
    @ObservedObject var params: GratingParams
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MTKView {
        let view: MTKView = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        
        guard let renderer = Renderer(mtkView: view) else {
            return view
        }
        context.coordinator.renderer = renderer
        view.delegate = renderer
        
        return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let r = context.coordinator.renderer else { return }
        r.frequency = Float(params.frequency)
        r.orientationRadians = Float(params.orientationDeg * (.pi / 180))
        r.contrast = Float(params.contrast)
        r.mean = Float(params.mean)
        r.driftEnabled = params.driftEnabled
        r.phaseVelocity = Float(params.phaseVelocity)
    }
    
    final class Coordinator {
        var renderer: Renderer?
    }
}
