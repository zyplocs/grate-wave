//
//  Renderer.swift
//  GrateWave
//
//  Created by Eli J on 12/16/25.
//

import Foundation
import MetalKit
import simd

struct GratingUniforms {
    var resolution: SIMD2<Float> = .zero
    var frequency: Float = 0.01
    var orientation: Float = 0.0
    var phase: Float = 0.0
    var mean: Float = 0.5
    var contrast: Float = 1.0
    var _pad: SIMD2<Float> = .zero
}

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private var uniformBuffer: MTLBuffer
    
    var frequency: Float = 0.01
    var orientationRadians: Float = 0
    var contrast: Float = 1
    var mean: Float = 0.5
    var driftEnabled: Bool = false
    var phaseVelocity: Float = 0

    private var phase: Float = 0
    private var lastTime: CFTimeInterval?
    
    init?(mtkView: MTKView) {
        guard let device: any MTLDevice = mtkView.device else { return nil }
        self.device = device
        
        guard let cq: any MTLCommandQueue = device.makeCommandQueue() else { return nil }
        self.commandQueue = cq
        
        let uniformsSize: Int = MemoryLayout<GratingUniforms>.stride
        guard let ub: any MTLBuffer = device.makeBuffer(length: uniformsSize, options: [.storageModeShared]) else { return nil }
        self.uniformBuffer = ub
        
        guard let library: any MTLLibrary = device.makeDefaultLibrary() else { return nil }
        let vFunc: (any MTLFunction)? = library.makeFunction(name: "vertex_main")
        let fFunc: (any MTLFunction)? = library.makeFunction(name: "fragment_grating")
        
        let desc: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vFunc
        desc.fragmentFunction = fFunc
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        do {
            self.pipeline = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            return nil
        }
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {  }
    
    func draw(in view: MTKView) {
        guard
            let drawable: any CAMetalDrawable = view.currentDrawable,
            let rpd: MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        
        // Time step
        let now: CFTimeInterval = CACurrentMediaTime()
        let dt: Float
        if let last: CFTimeInterval = lastTime {
            dt = Float(now - last)
        } else {
            dt = 0
        }
        lastTime = now
        
        if driftEnabled {
            phase += phaseVelocity * dt
            // Keep phase bounded
            if phase > 10_000 { phase = phase.truncatingRemainder(dividingBy: 2 * .pi) }
        }
        
        // Fill uniforms
        var u: GratingUniforms = GratingUniforms()
        u.resolution = SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        u.frequency = frequency
        u.orientation = orientationRadians
        u.phase = phase
        u.mean = mean
        u.contrast = contrast
        
        memcpy(uniformBuffer.contents(), &u, MemoryLayout<GratingUniforms>.stride)
        
        guard let cmd: any MTLCommandBuffer = commandQueue.makeCommandBuffer(),
              let enc: any MTLRenderCommandEncoder = cmd.makeRenderCommandEncoder(descriptor: rpd)
        else { return }
        
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
        
        cmd.present(drawable)
        cmd.commit()
    }
}
