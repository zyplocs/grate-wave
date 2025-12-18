//
//  GratingShader.metal
//  GrateWave
//
//  Created by Eli J on 12/16/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]]; // clip space -> [x, y, z, w]
    float2 uv;  // texture coordinates
};

struct GratingUniforms {
    float2 resolution;   // screen (view) size -> pixels
    float  frequency;    // spatial freq. -> cycles per pixel
    float  orientation;  // grating angle -> radians
    float  phase;        // shifts the wave left/right -> radians
    float  mean;         // average luminance -> 0..1
    float  contrast;     // Michelson contrast -> 0..1
    float2 _pad;         // GPU padding bytes; leave here
};

vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    // Fullscreen triangle
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0, 3.0)
    };  // norm. device coords : (-1,-1) is bottom-left & (1,1) is top-right
    float2 uv[3] = {
        float2(0.0, 0.0),
        float2(2.0, 0.0),
        float2(0.0, 2.0)
    };  // texture coords : (0,0) is bottom-left & (1,1) is top-right
    
    VertexOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv = uv[vid];
    return out;
}

fragment float4 fragment_grating(VertexOut in [[stage_in]],
                                 constant GratingUniforms& u [[buffer(0)]]) {
    float2 uv = in.uv;

    // Convert to centered pixel coordinates
    float2 p = (uv - 0.5) * u.resolution;

    // Rotate axis: x_rot = x cosθ + y sinθ
    float c = cos(u.orientation);
    float s = sin(u.orientation);
    float x_rot = p.x * c + p.y * s;

    float amplitude = u.contrast * u.mean;
    float value = u.mean + amplitude * sin(2.0f * M_PI_F * u.frequency * x_rot + u.phase);

    value = clamp(value, 0.0f, 1.0f);
    return float4(value, value, value, 1.0);
}
