#version 120
#extension GL_EXT_gpu_shader4 : enable


//Prepares sky textures (2 * 256 * 256), computes light values and custom lightmaps


#include "/lib/settings.glsl"

flat varying vec3 ambientUp;
flat varying vec3 ambientLeft;
flat varying vec3 ambientRight;
flat varying vec3 ambientB;
flat varying vec3 ambientF;
flat varying vec3 ambientDown;
flat varying vec3 lightSourceColor;
flat varying vec3 sunColor;
flat varying vec3 sunColorCloud;
flat varying vec3 moonColor;
flat varying vec3 moonColorCloud;
flat varying vec3 zenithColor;
flat varying vec3 avgSky;
flat varying vec2 tempOffsets;
flat varying float exposure;
flat varying float rodExposure;
flat varying float avgBrightness;
flat varying float exposureF;
flat varying float fogAmount;
flat varying float VFAmount;
uniform vec3 fogColor; 



uniform sampler2D colortex4;
uniform sampler2D noisetex;

uniform int frameCounter;
uniform float rainStrength;
uniform float eyeAltitude;
uniform vec3 sunVec;
uniform vec2 texelSize;
uniform float frameTimeCounter;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float sunElevation;
uniform vec3 cameraPosition;
uniform float far;
uniform ivec2 eyeBrightnessSmooth;
#include "/lib/util.glsl"
#include "/lib/ROBOBO_sky.glsl"
vec3 toShadowSpaceProjected(vec3 p3){
    p3 = mat3(gbufferModelViewInverse) * p3 + gbufferModelViewInverse[3].xyz;
    p3 = mat3(shadowModelView) * p3 + shadowModelView[3].xyz;
    p3 = diagonal3(shadowProjection) * p3 + shadowProjection[3].xyz;

    return p3;
}
float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y)+frameCounter/1.6180339887);
	return noise;
}
float blueNoise(){
  return fract(texelFetch2D(noisetex, ivec2(gl_FragCoord.xy)%512, 0).a + 1.0/1.6180339887 * frameCounter);
}
vec4 lightCol = vec4(fogColor, float(sunElevation > 1e-5)*2-1.);
const float[17] Slightmap = float[17](14.0,17.,19.0,22.0,24.0,28.0,31.0,40.0,60.0,79.0,93.0,110.0,132.0,160.0,197.0,249.0,249.0);

void main() {
/* DRAWBUFFERS:4 */
gl_FragData[0] = vec4(0.0);
//Lightmap for forward shading (contains average integrated sky color across all faces + N_TORCH + min ambient)
vec3 avgAmbient = (ambientUp + ambientLeft + ambientRight + ambientB + ambientF + ambientDown)/6.*(1.0+rainStrength*0.2);
if (gl_FragCoord.x < 17. && gl_FragCoord.y < 17.){
  float N_TORCHLut = clamp(16.0-gl_FragCoord.x,0.5,15.5);
  N_TORCHLut = N_TORCHLut+0.712;
  float N_TORCH_lightmap = max(1.0/N_TORCHLut/N_TORCHLut - 1/16.21/16.21,0.0);
  N_TORCH_lightmap = N_TORCH_lightmap*N_TORCH_AMOUNT*5.0;
  float sky_lightmap = 1.0*150.0;
  vec3 ambient = avgAmbient*sky_lightmap+N_TORCH_lightmap*vec3(N_TORCH_R,N_TORCH_G,N_TORCH_B)*N_TORCH_AMOUNT+N_MIN_LIGHT_AMOUNT*0.005/(exposureF+clamp(rodExposure*exposureF/10.,0.0,10000.0));
  gl_FragData[0] = vec4(ambient*N_Ambient_Mult,1.0);
}

//Lightmap for deferred shading (contains only N_TORCH + min ambient)
if (gl_FragCoord.x < 17. && gl_FragCoord.y > 19. && gl_FragCoord.y < 19.+17. ){
	float N_TORCHLut = clamp(16.0-gl_FragCoord.x,0.5,15.5);
  N_TORCHLut = N_TORCHLut+0.712;
  float N_TORCH_lightmap = max(1.0/N_TORCHLut/N_TORCHLut - 1/16.21/16.21,0.0);
  float ambient = N_TORCH_lightmap*N_TORCH_AMOUNT*5.;
  float sky_lightmap = 1.0;
  gl_FragData[0] = vec4(sky_lightmap,ambient,N_MIN_LIGHT_AMOUNT*0.005/(exposureF+clamp(rodExposure*exposureF/10.,0.0,10000.0)),1.0)*N_Ambient_Mult;
}

//Save light values
if (gl_FragCoord.x < 1. && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientUp,1.0);
if (gl_FragCoord.x > 1. && gl_FragCoord.x < 2.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientDown,1.0);
if (gl_FragCoord.x > 2. && gl_FragCoord.x < 3.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientLeft,1.0);
if (gl_FragCoord.x > 3. && gl_FragCoord.x < 4.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientRight,1.0);
if (gl_FragCoord.x > 4. && gl_FragCoord.x < 5.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientB,1.0);
if (gl_FragCoord.x > 5. && gl_FragCoord.x < 6.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(ambientF,1.0);
if (gl_FragCoord.x > 6. && gl_FragCoord.x < 7.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(lightSourceColor,1.0);
if (gl_FragCoord.x > 7. && gl_FragCoord.x < 8.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(avgAmbient,1.0);

//Sky gradient (no clouds)
const float pi = 3.141592653589793238462643383279502884197169;
if (gl_FragCoord.x > 18. && gl_FragCoord.y > 1. && gl_FragCoord.x < 18+257){
  gl_FragData[0] = vec4(vec3(fogColor)*100.,1.0);
}

//Temporally accumulate sky and light values
vec3 temp = texelFetch2D(colortex4,ivec2(gl_FragCoord.xy),0).rgb;
vec3 curr = gl_FragData[0].rgb*150.;
gl_FragData[0].rgb = clamp(mix(temp,curr,0.06),0.0,65000.);

//Exposure values
if (gl_FragCoord.x > 10. && gl_FragCoord.x < 11.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(exposure,avgBrightness,exposureF,1.0);
if (gl_FragCoord.x > 14. && gl_FragCoord.x < 15.  && gl_FragCoord.y > 19.+18. && gl_FragCoord.y < 19.+18.+1 )
gl_FragData[0] = vec4(rodExposure,0.0,0.0,1.0);

}
