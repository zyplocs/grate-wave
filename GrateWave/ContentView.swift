//
//  ContentView.swift
//  GrateWave
//
//  Created by Eli J on 12/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var p = GratingParams()

    var body: some View {
        VStack(spacing: 12) {
            MetalGratingView(params: p)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Frequency (cycles/pixel): \(p.frequency, specifier: "%.4f")")
                    Slider(value: $p.frequency, in: 0.0...0.05)
                }
                HStack {
                    Text("Orientation (deg): \(p.orientationDeg, specifier: "%.0f")")
                    Slider(value: $p.orientationDeg, in: 0...180)
                }
                HStack {
                    Text("Contrast: \(p.contrast, specifier: "%.2f")")
                    Slider(value: $p.contrast, in: 0...1)
                }
                HStack {
                    Text("Mean: \(p.mean, specifier: "%.2f")")
                        .fontDesign(.serif)
                    Slider(value: $p.mean, in: 0...1)
                }
                
                Toggle("Drift", isOn: $p.driftEnabled)
                    .fontDesign(.serif)
                
                HStack {
                    Text("Phase velocity (rad/s): \(p.phaseVelocity, specifier: "%.2f")")
                        .fontDesign(.serif)
                    Slider(value: $p.phaseVelocity, in: 0...20)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    ContentView()
}
