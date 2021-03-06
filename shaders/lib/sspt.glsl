uniform float lightSign;


float invLinZ (float lindepth){
	return -((2.0*near/lindepth)-far-near)/(far-near);
}
vec3 toClipSpace3Prev(vec3 viewSpacePosition) {
    return projMAD(gbufferPreviousProjection, viewSpacePosition) / -viewSpacePosition.z * 0.5 + 0.5;
}
vec3 RT(vec3 dir,vec3 position,float noise){

	
	vec3 clipPosition = toClipSpace3(position);
	

	
	
	float stepSize = STEPSIZE;
	int maxSteps = MAXSTEPS;	
	int maxLength = MAXLENGTH;	
	
	
	

	float rayLength = ((position.z + dir.z * sqrt(3.0)*maxLength) > -sqrt(3.0)*near) ?  (-sqrt(3.0)*near -position.z) / dir.z : sqrt(3.0)*maxLength;

	vec3 end = toClipSpace3(position+dir*rayLength);
	vec3 direction = end-clipPosition;  //convert to clip space
	
	
	float len = max(abs(direction.x)/texelSize.x,abs(direction.y)/texelSize.y)/stepSize;
	
	
	//get at which length the ray intersects with the edge of the screen
	vec3 maxLengths = (step(0.,direction)-clipPosition) / direction*0.75;
	float mult = min(min(maxLengths.x*0.75,maxLengths.y*0.75),maxLengths.z*0.75);


	vec3 stepv = direction/len;

	
	int iterations = min(int(min(len, mult*len)-2), maxSteps);	

	//Do one iteration for closest texel (good contact shadows)
	vec3 spos = clipPosition*vec3(RENDER_SCALE,1.0) + stepv/stepSize*4.0;
	spos.xy+= TAA_Offset*texelSize*0.5;
	
	float sp = texelFetch2D(colortex4,ivec2(spos.xy/texelSize/4),0).w;
	float currZ = linZ(spos.z);

	if( sp < currZ) {
		float dist = abs(sp-currZ)/currZ;
		if (dist <= 0.035 ) return vec3(spos.xy, invLinZ(sp))/vec3(RENDER_SCALE,1.0);
	}
	
	stepv *= vec3(RENDER_SCALE,1.0);
	spos += stepv*noise*noise;	
	
 for(int i = 0; i < iterations; i++){
		float sp = texelFetch2D(colortex4,ivec2(spos.xy/texelSize/4),0).w;
		float currZ = linZ(spos.z);
		if( sp < currZ) {
			float dist = abs(sp-currZ)/currZ;
			if (dist <= 0.035 ) return vec3(spos.xy, invLinZ(sp))/vec3(RENDER_SCALE,1.0);
		}
			spos += stepv;
	}
	
    return vec3(1.1);
}
	const vec2 offsets[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.6495, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.6495, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.6495, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));


vec3 cosineHemisphereSample(vec2 Xi)
{
    float r = sqrt(Xi.x);
    float theta = 2.0 * 3.14159265359 * Xi.y;

    float x = r * cos(theta);
    float y = r * sin(theta);

    return vec3(x, y, sqrt(max(0.0f, 1 - Xi.x)));
}



vec3 TangentToWorld(vec3 N, vec3 H)
{
    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 T = normalize(cross(UpVector, N));
    vec3 B = cross(N, T);

    return vec3((T * H.x) + (B * H.y) + (N * H.z));
}

mat3 make_coord_space(vec3 n) {
    vec3 h = n;
    if (abs(h.x) <= abs(h.y) && abs(h.x) <= abs(h.z))
        h.x = 1.0;
    else if (abs(h.y) <= abs(h.x) && abs(h.y) <= abs(h.z))
        h.y = 1.0;
    else
        h.z = 1.0;

    vec3 y = normalize(cross(h, n));
    vec3 x = normalize(cross(n, y));

    return mat3(x, y, n);
}
vec2 WeylNth(int n) {
	return fract(vec2(n * 12664745, n*9560333) / exp2(24.0));
}



vec2 R2_samples(int n){
	vec2 alpha = vec2(0.75487765, 0.56984026);
	return fract(alpha * n);
}

float R2_dither(){
	vec2 alpha = vec2(0.75487765, 0.56984026);
	return fract(alpha.x * gl_FragCoord.x + alpha.y * gl_FragCoord.y);
}
//#define RTAO

vec3 rtGI(vec3 normal,  vec3 normal2, vec4 noise,vec3 fragpos, vec3 ambient, bool translucent, vec3 torch){
	int nrays = RAYS;
	vec3 intRadiance = vec3(0.0);
	float occlusion = 0.0;
	for (int i = 0; i < nrays; i++){

	
	
	
		int seed = (frameCounter%10000)*nrays+i;
		vec2 ij = fract(R2_samples(seed) + noise.rg);
		vec3 rayDir = normalize(cosineHemisphereSample(ij));
			 rayDir = TangentToWorld(normal,rayDir);
		vec2 texcoord = gl_FragCoord.xy*texelSize;	
		vec3 rayHit = RT(mat3(gbufferModelView)*rayDir, fragpos, fract(seed/1.6180339887 + noise.b));
		
	//	vec3 rayHit = RT(mix(mat3(gbufferModelView)*rayDir,reflectedVector,0.5), fragpos, fract(seed/1.6180339887 + noise.b));
	
	
		if (rayHit.z < 1.0-1e-8){

				
			vec3 previousPosition = mat3(gbufferModelViewInverse) * toScreenSpace(rayHit) + gbufferModelViewInverse[3].xyz + cameraPosition-previousCameraPosition;
			previousPosition = mat3(gbufferPreviousModelView) * previousPosition + gbufferPreviousModelView[3].xyz;
			previousPosition.xy = projMAD(gbufferPreviousProjection, previousPosition).xy / -previousPosition.z * 0.5 + 0.5;
			

			if (previousPosition.x > 0.0 && previousPosition.y > 0.0 && previousPosition.x < 1.0 && previousPosition.x < 1.0){


				intRadiance += texture2D(colortex5,previousPosition.xy).rgb;

			}else
			
				intRadiance += ambient;
				occlusion += 1.0;
			
			if (translucent)
				intRadiance += ambient*0.25;
		}
		else {
			intRadiance += ambient;
		}
	}
	
	
	
	
	
	return clamp(intRadiance/nrays + (1.0-occlusion/nrays)*torch,0,10);
}





vec3 endGI(vec3 normal,vec4 noise,vec3 fragpos, vec3 ambient, bool translucent, vec3 torch){
	int nrays = RAYS;
	vec3 intRadiance = vec3(0.0);
	float occlusion = 0.0;
	for (int i = 0; i < nrays; i++){
		int seed = (frameCounter%10000)*nrays+i;
		vec2 ij = fract(R2_samples(seed) + noise.rg);
		vec3 rayDir = normalize(cosineHemisphereSample(ij));
		rayDir = TangentToWorld(normal,rayDir);
		vec3 rayHit = RT(mat3(gbufferModelView)*rayDir, fragpos, fract(seed/1.6180339887 + noise.b));
		if (rayHit.z < 1.){
			vec3 previousPosition = mat3(gbufferModelViewInverse) * toScreenSpace(rayHit) + gbufferModelViewInverse[3].xyz + cameraPosition-previousCameraPosition;
			previousPosition = mat3(gbufferPreviousModelView) * previousPosition + gbufferPreviousModelView[3].xyz;
			previousPosition.xy = projMAD(gbufferPreviousProjection, previousPosition).xy / -previousPosition.z * 0.5 + 0.5;
			if (previousPosition.x > 0.0 && previousPosition.y > 0.0 && previousPosition.x < 1.0 && previousPosition.x < 1.0)
				intRadiance += texture2D(colortex5,previousPosition.xy).rgb*3;
			occlusion += 1.0;
			if (translucent)
				intRadiance += ambient*0.25;
		}
		else {
			intRadiance += ambient;
		}
	}
	return intRadiance/nrays + (1.0-occlusion/nrays)*torch*3;
}



