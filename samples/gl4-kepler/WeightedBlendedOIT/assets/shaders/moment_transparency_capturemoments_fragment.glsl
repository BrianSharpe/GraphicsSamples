//----------------------------------------------------------------------------------
// File:        gl4-kepler\WeightedBlendedOIT\assets\shaders/moment_transparency_capturemoments_fragment.glsl
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

uniform float C0;   //  1.0 / nearPlane
uniform float C1;   //  1.0 / log( farPlane / nearPlane )

vec4 ShadeFragment();

//layout(location=0) in vec3 vTexCoord; //  already defined in shade_fragment.glsl
layout(location=1) in vec3 vViewPos;

layout(location=0) out vec4 oMoments;
layout(location=1) out float oTotalOpticalDepth;

//  the following code can be found in
//  https://briansharpe.files.wordpress.com/2018/07/moment-transparency-supp-av.pdf

float DepthToUnit( float z )
{
    return log( z * C0 ) * C1;
}

vec4 MakeMoments4( float z )
{
    float zsq = z * z;
    return vec4( z, zsq, zsq * z, zsq * zsq );
}

void WriteMoments(
    float z,
    float alpha,
    out vec4 o_moments,         // write to FP32_RGBA as additive
    out float o_opticalDepth )  // write to FP32_R as additive
{
    const float kMaxAlpha = 1.0 - 0.5/256.0; // clamp alpha
    float opticalDepth = -log( 1.0 - ( alpha * kMaxAlpha ) );
    float unitPos = DepthToUnit( z );
    o_moments = MakeMoments4( unitPos ) * opticalDepth;
    o_opticalDepth = opticalDepth;
}

void main(void)
{
    vec4 color = ShadeFragment();

    WriteMoments(
        -vViewPos.z,            //  z
        color.a,                //  alpha
        oMoments,               //  o_moments
        oTotalOpticalDepth );   //  o_opticalDepth
}
