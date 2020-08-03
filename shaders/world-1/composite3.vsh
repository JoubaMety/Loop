#version 120
#extension GL_EXT_gpu_shader4 : enable
#include "/lib/res_params.glsl"
varying vec2 texcoord;
flat varying vec3 zMults;
uniform float far;
uniform float near;
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	zMults = vec3(1.0/(far * near),far+near,far-near);
	gl_Position = ftransform();
				#ifdef TAA_UPSCALING
		gl_Position.xy = (gl_Position.xy*0.5+0.5)*RENDER_SCALE*2.0-1.0;
	#endif
	texcoord = gl_MultiTexCoord0.xy;

}
