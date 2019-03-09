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

uniform float C0;   //  1.0 / nearPlane
uniform float C1;   //  1.0 / log( farPlane / nearPlane )

uniform float uOverestimationWeight;    //  default = 0.25

vec4 ShadeFragment();

//layout(location=0) in vec3 vTexCoord; //  already defined in shade_fragment.glsl
layout(location=1) in vec3 vViewPos;

layout(location=0) out vec4 oSumColor;
layout(location=1) out vec4 oSumWeight;

uniform sampler2DRect momentTex;
uniform sampler2DRect totalOpticalDepthTex;

//  minor hlsl -> glsl conversion code for use in EstimateIntegralFrom4Moments()
#define float2 vec2
#define float3 vec3
#define float4 vec4
float mad( float x , float y , float w ) { return x * y + w; }
float saturate( float a ) { return clamp( a, 0.0, 1.0 ); }
float4 lerp( float4 x, float4 y, float4 s ) { return mix( x, y, s ); };
float lerp( float x, float y, float s ) { return mix( x, y, s ); };

//  from http://jcgt.org/published/0006/01/03/
void EstimateIntegralFrom4Moments(
    out float OutShadowIntensity,
    float4 Biased4Moments,
    float IntervalEnd,
    float OverestimationWeight)
{
    float4 b=Biased4Moments;
    float3 z;
    z[0]=IntervalEnd;

    // Compute a Cholesky factorization of the Hankel matrix B storing only non-
    // trivial entries or related products
    float L21D11=mad(-b[0],b[1],b[2]);
    float D11=mad(-b[0],b[0], b[1]);
    float SquaredDepthVariance=mad(-b[1],b[1], b[3]);
    float D22D11=dot(float2(SquaredDepthVariance,-L21D11),float2(D11,L21D11));
    float InvD11=1.0f/D11;
    float L21=L21D11*InvD11;

    // Obtain a scaled inverse image of bz=(1,z[0],z[0]*z[0])^T
    float3 c=float3(1.0f,z[0],z[0]*z[0]);
    // Forward substitution to solve L*c1=bz
    c[1]-=b.x;
    c[2]-=b.y+L21*c[1];
    // Scaling to solve D*c2=c1
    c[1]*=InvD11;
    c[2]*=D11/D22D11;
    // Backward substitution to solve L^T*c3=c2
    c[1]-=L21*c[2];
    c[0]-=dot(c.yz,b.xy);
    // Solve the quadratic equation c[0]+c[1]*z+c[2]*z^2 to obtain solutions 
    // z[1] and z[2]
    float InvC2=1.0f/c[2];
    float p=c[1]*InvC2;
    float q=c[0]*InvC2;
    float D=(p*p*0.25f)-q;
    float r=sqrt(D);
    z[1]=-p*0.5f-r;
    z[2]=-p*0.5f+r;
    // Compute the shadow intensity by summing the appropriate weights
    float3 Weight;
    Weight[0]=(z[1]*z[2]-b[0]*(z[1]+z[2])+b[1])/((z[0]-z[1])*(z[0]-z[2]));
    Weight[1]=(z[0]*z[2]-b[0]*(z[0]+z[2])+b[1])/((z[2]-z[1])*(z[0]-z[1]));
    Weight[2]=1.0f-Weight[0]-Weight[1];
    float IntegralLowerBound=
        (z[2]<z[0])?(Weight[1]+Weight[2]):(
        (z[1]<z[0])?Weight[1]:0.0f);
    float IntegralUpperBound=saturate(IntegralLowerBound+Weight[0]);
    IntegralLowerBound=saturate(IntegralLowerBound);
    OutShadowIntensity = lerp(IntegralLowerBound,IntegralUpperBound,OverestimationWeight);
}

//  the following code can be found in
//  https://briansharpe.files.wordpress.com/2018/07/moment-transparency-supp-av.pdf

float Hamburger4MSM( vec4 moments, float z )
{
    // EstimateIntegralFrom4Moments and
    // Compute4MomentUnboundedShadowIntensity implementation, and
    // associated bias can be found in the demo code at
    // http://jcgt.org/published/0006/01/03/
    //
    // use Compute4MomentUnboundedShadowIntensity for basic MT
    // use EstimateIntegralFrom4Moments for MT with overestimation
    //
    moments = mix(moments, vec4(0.0, 0.375, 0.0, 0.375), 3.0e-7);
    float result;
    EstimateIntegralFrom4Moments(
        result,
        moments,
        z,
        uOverestimationWeight);
    return result;
}

float DepthToUnit( float z )
{
    return log( z * C0 ) * C1;
}

float w( float z , float alpha, vec4 moments, float totalOD )
{
    float unitPos = DepthToUnit( z );
    if ( totalOD != 0.0 )
        moments /= totalOD;		// normalize
    float ma = Hamburger4MSM( moments, unitPos );
    ma = exp( -ma * totalOD );
    return ma * alpha;
}

void main(void)
{
    vec4 color = ShadeFragment();

    vec4 moments = texture(momentTex, gl_FragCoord.xy);
    float totalOD = texture(totalOpticalDepthTex, gl_FragCoord.xy).r;

    float weight = w(
        -vViewPos.z,    //  z
        color.a,        //  alpha
        moments,        //  moments
        totalOD);       //  totalOD

    oSumColor = vec4(color.rgb * color.a, color.a) * weight;
    oSumWeight = vec4(color.a);
}
