//----------------------------------------------------------------------------------
// File:        gl4-kepler\WeightedBlendedOIT\assets\shaders/moment_transparency_blend_fragment.glsl
// SDK Version: v3.00
// Email:       gameworks@nvidia.com
// Site:        http://developer.nvidia.com/
//
// Copyright (c) 2014-2015, NVIDIA CORPORATION. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of NVIDIA CORPORATION nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//----------------------------------------------------------------------------------

layout(location=0) out vec4 oMoments;
layout(location=1) out float oTotalOpticalDepth;
 
uniform sampler2D momentTex;
uniform sampler2D totalOpticalDepthTex;

uniform float uBlurRadius;
uniform ivec2 uBlurDirection;   // either 1,0 or 0,1 (representing hoz or vert)

void main(void)
{
    // first sample middle pixel
    oMoments = texelFetch(momentTex, ivec2(gl_FragCoord.xy), 0);
    oTotalOpticalDepth = texelFetch(totalOpticalDepthTex, ivec2(gl_FragCoord.xy), 0).x;
    float totalWeight = 1.0;
    
    // now sample the filter
    int numPixels = int(uBlurRadius);
    float invBlurRadius = 1.0 / uBlurRadius;
    for (int i = 1; i <= numPixels; i++)
    {
        // supersimple filter for now   y = (1 - x^2)^3
        float sampleWeight = float(i) * invBlurRadius;
        sampleWeight = 1.0 - ( sampleWeight * sampleWeight );
        sampleWeight = sampleWeight * sampleWeight * sampleWeight;

        oMoments += texelFetch(momentTex, ivec2(gl_FragCoord.xy) + (uBlurDirection * i), 0) * sampleWeight;
        oTotalOpticalDepth += texelFetch(totalOpticalDepthTex, ivec2(gl_FragCoord.xy) + (uBlurDirection * i), 0).x * sampleWeight;
        totalWeight += sampleWeight;
        
        oMoments += texelFetch(momentTex, ivec2(gl_FragCoord.xy) - (uBlurDirection * i), 0) * sampleWeight;
        oTotalOpticalDepth += texelFetch(totalOpticalDepthTex, ivec2(gl_FragCoord.xy) - (uBlurDirection * i), 0).x * sampleWeight;
        totalWeight += sampleWeight;
    }

    // output normalized result
    oMoments /= totalWeight;
    oTotalOpticalDepth /= totalWeight;
}
