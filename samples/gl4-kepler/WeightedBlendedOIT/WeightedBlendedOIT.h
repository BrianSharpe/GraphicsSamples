//----------------------------------------------------------------------------------
// File:        gl4-kepler\WeightedBlendedOIT/WeightedBlendedOIT.h
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
#ifndef WeightedBlendedOIT_H
#define WeightedBlendedOIT_H

#define ENABLE_GPU_TIMERS 1

#include "NvAppBase/gl/NvSampleAppGL.h"
#include "NvGLUtils/NvTimers.h"
#include "NV/NvMath.h"

class NvGLSLProgram;
class NvModelGL;
class NvStopWatch;
class NvFramerateCounter;

class WeightedBlendedOIT : public NvSampleAppGL
{
public:
    WeightedBlendedOIT();
    ~WeightedBlendedOIT();
    
    void initUI(void);
    void initRendering(void);
    void draw(void);
    void reshape(int32_t width, int32_t height);

    void configurationCallback(NvGLConfiguration& config);
    bool getRequestedWindowSize(int32_t& width, int32_t& height);

    enum {
        DEPTH_PEELING_MODE,         //  http://developer.download.nvidia.com/SDK/10/opengl/screenshots/samples/dual_depth_peeling.html
        WEIGHTED_BLENDED_MODE,      //  http://jcgt.org/published/0002/02/09/
        MOMENT_TRANSPARENCY_MODE,   //  https://briansharpe.files.wordpress.com/2018/07/moment-transparency-av.pdf
        MODE_COUNT
    };

    enum {
        BUNNY_MODEL,
        DRAGON_MODEL,
        MODELS_COUNT
    };

    enum {
        TIMER_MOMENTS,
        TIMER_GEOMETRY,
        TIMER_COMPOSITING,
        TIMER_COUNT
    };

    enum {
        MOMENT_RESOLUTION_FULL,         //  1/1
        MOMENT_RESOLUTION_HALF,         //  1/2
        MOMENT_RESOLUTION_QUARTER,      //  1/4
        MOMENT_RESOLUTION_EIGHTH,       //  1/8
        MOMENT_RESOLUTION_COUNT
    };

protected:
    void InitDepthPeelingRenderTargets();
    void DeleteDepthPeelingRenderTargets();
    void InitAccumulationRenderTargets();
    void DeleteAccumulationRenderTargets();
    void InitMomentTransparencyRenderTargets();
    void DeleteMomentTransparencyRenderTargets();
    NvModelGL* LoadModel(const char *model_filename);
    void DrawModel(NvGLSLProgram* shader);
    void BuildShaders();
    void DestroyShaders();
    void ReloadShaders();
    void RenderFrontToBackPeeling();
    void RenderWeightedBlendedOIT();
    void RenderMomentTransparency();
    void RenderFullscreenQuad(NvGLSLProgram* shader);

    NvModelGL *m_models[MODELS_COUNT];
    uint32_t m_modelID;
    GLuint m_vboId;
    GLuint m_eboId;
    GLuint m_queryId;

    NvGLSLProgram* m_shaderPeelingInit;
    NvGLSLProgram* m_shaderPeelingPeel;
    NvGLSLProgram* m_shaderPeelingBlend;
    NvGLSLProgram* m_shaderPeelingFinal;

    NvGLSLProgram* m_shaderWeightedBlend;
    NvGLSLProgram* m_shaderWeightedFinal;

    NvGLSLProgram* m_momentCaptureMomentsBlend;
    NvGLSLProgram* m_momentTransparencyBlend;

    int m_imageWidth;
    int m_imageHeight;
    float m_opacity;
    uint32_t m_mode;
    uint32_t m_numGeoPasses;
    uint32_t m_momentResolution;

#if ENABLE_GPU_TIMERS
    NvGPUTimer m_timers[TIMER_COUNT];
#endif

    const float *m_backgroundColor;
    float m_wb_weightParameter;
    float m_mt_overestimationWeight;

    GLuint m_frontFboId[2];
    GLuint m_frontDepthTexId[2];
    GLuint m_frontColorTexId[2];
    GLuint m_frontColorBlenderTexId;
    GLuint m_frontColorBlenderFboId;

    GLuint m_accumulationTexId[2];
    GLuint m_accumulationFboId;

    GLuint m_momentTexId;
    GLuint m_totalOpticalDepthTexId;
    GLuint m_momentFboId;       //  holds both moments + totalOpticalDepth
    uint32_t m_momentTextureResolution;

    nv::matrix4f m_MVP;
    nv::matrix4f m_normalMat;
    nv::matrix4f m_fullscreenMVP;

    NvUIText* m_statsText;
};

#endif
