#version 120

#define WAVING_LEAVES
#define WAVING_VINES
#define WAVING_GRASS
#define WAVING_WEB
#define WAVING_NETHERWART
#define WAVING_WHEAT
#define WAVING_FLOWERS
#define WAVING_FIRE
#define WAVING_WATER
#define WAVING_LAVA
#define WAVING_LILYPAD
#define INTENSE_GLOW

#define ENTITY_LEAVES        18.0
#define ENTITY_LEAVES_2      161.0
#define ENTITY_VINES        106.0
#define ENTITY_TALLGRASS     31.0
#define ENTITY_DEAD_BUSH 	 32.0
#define ENTITY_SAPLING		 6.0
#define ENTITY_DANDELION     37.0
#define ENTITY_ROSE          38.0
#define ENTITY_FLOWERS		175.0
#define ENTITY_NETHERWART 115.0
#define ENTITY_CARROT 		141.0
#define ENTITY_POTATO 		142.0
#define ENTITY_BEET 		207.0
#define ENTITY_WHEAT         59.0
#define ENTITY_LILYPAD      111.0
#define ENTITY_WEB          30.0
#define ENTITY_FIRE          51.0
#define ENTITY_WATERFLOWING   8.0
#define ENTITY_WATERSTILL     9.0
#define ENTITY_LAVAFLOWING   10.0
#define ENTITY_LAVASTILL     11.0
#define ENTITY_GLOWSTONE     89.0
#define ENTITY_GLOWSTONE_LAMP 124.0
#define ENTITY_TORCH          50.0

const float PI = 3.1415927;

varying vec4 color;
varying vec2 lmcoord;
varying float mat;
varying vec2 texcoord;
varying vec3 normal;
varying float glowmult;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 upPosition;
uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;

float pi2wt = PI*2*(frameTimeCounter*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude * (1.0f + rainStrength * 2.0f);
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude * (1.0f + rainStrength * 2.0f);
	  ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude * (1.0f + rainStrength * 2.0f);
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

vec3 calcWaterMove(in vec3 pos)
{
	float fy = fract(pos.y + 0.001);
	if (fy > 0.002)
	{
		float wave = 0.05 * sin(2*PI/2*frameTimeCounter + 2*PI*2/16*pos.x + 2*PI*5/16*pos.z)
				   + 0.05 * sin(2*PI/1*frameTimeCounter - 2*PI*3/16*pos.x + 2*PI*4/16*pos.z);
		return vec3(0, clamp(wave * (1.0 + rainStrength * 3.0), -fy, 1.0-fy), 0);
	}
	else
	{
		return vec3(0);
	}
}

vec3 calcLavaMove(in vec3 pos)
{
	float fy = fract(pos.y + 0.001);
	if (fy > 0.002)
	{
		float wave = 0.05 * sin(2*PI/4*frameTimeCounter + 2*PI*2/16*pos.x + 2*PI*5/16*pos.z)
				   + 0.05 * sin(2*PI/3*frameTimeCounter - 2*PI*3/16*pos.x + 2*PI*4/16*pos.z);
		return vec3(0, clamp(wave, -fy, 1.0-fy), 0);
	}
	else
	{
		return vec3(0);
	}
}

//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {
	vec4 vtexcoordam;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vec2 vtexcoord    = sign(texcoordminusmid)*0.5+0.5;
	mat = 1.0f;
  glowmult = 1.0f;
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;

	#ifdef WAVING_LEAVES
	if ( mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_LEAVES_2 )
			position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
	#endif
	#ifdef WAVING_VINES
	if ( mc_Entity.x == ENTITY_VINES )
			position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
	#endif
	if (istopv > 0.9) {
	#ifdef WAVING_GRASS
	if ( mc_Entity.x == ENTITY_TALLGRASS)
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif

	#ifdef WAVING_FLOWERS
	if (mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_FLOWERS || mc_Entity.x == ENTITY_DEAD_BUSH)
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WAVING_WHEAT
	if ( mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == ENTITY_CARROT || mc_Entity.x == ENTITY_POTATO ||  mc_Entity.x == ENTITY_BEET)
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
  #ifdef WAVING_NETHERWART
	if ( mc_Entity.x == ENTITY_NETHERWART)
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WAVING_FIRE
	if ( mc_Entity.x == ENTITY_FIRE)
      position.xyz += calcMove(worldpos.xyz, 0.0105, 0.0096, 0.0087, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
  #endif
	}
	#ifdef WAVING_LAVA
	if ( mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL) {
			position.xyz += calcLavaMove(worldpos.xyz) * 0.25;
			}
	#endif
	#ifdef WAVING_WATER
	if ( mc_Entity.x == ENTITY_WATERFLOWING || mc_Entity.x == ENTITY_WATERSTILL) {
			position.xyz += calcWaterMove(worldpos.xyz) * 0.25;
			}
	#endif
  #ifdef WAVING_WEB
	if ( mc_Entity.x == ENTITY_WEB ) {
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.2,0.0,0.2), vec3(0.2,0.0,0.2));
			}
	#endif
	#ifdef WAVING_LILYPAD
	if ( mc_Entity.x == ENTITY_LILYPAD ) {
			position.xyz += calcMove(worldpos.xyz, 0.0021, 0.0035, 0.0022, 0.0016, 0.0120, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
			}
	#endif
  #ifdef INTENSE_GLOW
  if ( mc_Entity.x == ENTITY_GLOWSTONE || mc_Entity.x == ENTITY_GLOWSTONE_LAMP || mc_Entity.x == ENTITY_FIRE || mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL){
    glowmult = 2.0f;
  }
  #endif
	float translucent = 1.0;
		if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_VINES || mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == 30.0
	|| mc_Entity.x == 175.0	|| mc_Entity.x == 115.0 || mc_Entity.x == 32.0) {
	mat = 0.2;
	translucent = 0.5;
	}
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	color = gl_Color;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	normal = normalize(gl_NormalMatrix * gl_Normal);

	float ndotl = dot(normalize(sunPosition),normal);
	float ndotup = dot(normalize(upPosition),normal);
	float SdotU = dot(normalize(sunPosition),normalize(upPosition));
	float sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	float t1 = mix(mix(-ndotl,ndotl,sunVisibility),1.0,rainStrength*0.8);

	float lmult = 0.5*(sqrt(ndotup*0.45+0.55)+(t1*0.47+0.53));
	lmult = mix(1.0,pow(lmult,0.33),translucent);
	lmcoord.t *= lmult;

}
