#version 120
#extension GL_EXT_gpu_shader4 : enable

varying vec4 lmtexcoord;
varying vec4 color;
varying vec4 normalMat;
#include "/lib/settings.glsl"


uniform sampler2D texture;
uniform sampler2D gaux1;

uniform vec4 lightCol;
uniform vec3 sunVec;
uniform vec3 upVec;

uniform vec2 texelSize;
uniform float skyIntensityNight;
uniform float skyIntensity;
uniform float sunElevation;
uniform float rainStrength;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#include "/lib/util2.glsl"
//faster and actually more precise than pow 2.2
vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}

#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)
vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = p * 2. - 1.;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}



float facos(float sx){
    float x = clamp(abs( sx ),0.,1.);
    float a = sqrt( 1. - x ) * ( -0.16882 * x + 1.56734 );
    return sx > 0. ? a : 3.14159265359 - a;
}


//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
/* DRAWBUFFERS:2 */
void main() {


	gl_FragData[0] = texture2D(texture, lmtexcoord.xy)*color;
	gl_FragData[0].a = 1.0;

		vec3 albedo = toLinear(gl_FragData[0].rgb);

		float torch_lightmap = lmtexcoord.z;
		float exposure = texelFetch2D(gaux1,ivec2(10,37),0).r;
		vec3 diffuseLight = torch_lightmap*vec3(20.,30.,50.)*2./10. ;

		vec3 color = diffuseLight*albedo/exposure*5.0;


		gl_FragData[0].rgb = color*0.01;




}
