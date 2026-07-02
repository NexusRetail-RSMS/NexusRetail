//
//  AlphaThreshold.metal
//  NexusRetail
//
//  Created by ANOOP on 02/07/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[stitchable]] half4 alphaThreshold(float2 position, SwiftUI::Layer layer) {
    float thresholdValue = 0.5;
    half4 color = layer.sample(position);
    return color.a >= thresholdValue ? half4(color.rgb / color.a, 1.0) : half4(0.0);
}
