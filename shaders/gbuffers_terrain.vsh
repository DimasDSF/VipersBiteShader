#version 120

#define WAVING_LEAVES
#define WAVING_VINES
#define WAVING_GRASS
#define WAVING_WEB
#define WAVING_NETHERWART
#define WAVING_CROPS
#define WAVING_FLOWERS
#define WAVING_FIRE
#define WAVING_LAVA
#define WAVING_LILYPAD
#define INTENSE_GLOW

#define ENTITY_LEAVES		18.0
#define ENTITY_LEAVES_2		161.0
#define ENTITY_VINES		106.0
#define ENTITY_TALLGRASS	31.0
#define ENTITY_DEAD_BUSH	32.0
#define ENTITY_SAPLING		6.0
#define ENTITY_DANDELION	37.0
#define ENTITY_ROSE			38.0
#define ENTITY_NETHERWART	115.0
#define ENTITY_CARROT		141.0
#define ENTITY_POTATO		142.0
#define ENTITY_BEET			207.0
#define ENTITY_PUMPKIN_ROOT	104.0
#define ENTITY_MELON_ROOT	105.0
#define ENTITY_SUGARCANE	83.0
#define ENTITY_WHEAT		59.0
#define ENTITY_LILYPAD		111.0
#define ENTITY_WEB			30.0
#define ENTITY_FIRE			51.0
#define ENTITY_WATERFLOWING	8.0
#define ENTITY_WATERSTILL	9.0
#define ENTITY_LAVAFLOWING	10.0
#define ENTITY_LAVASTILL	11.0
#define ENTITY_GLOWSTONE	89.0
#define ENTITY_GLOWLAMP		124.0
#define ENTITY_TORCH		50.0
#define ENTITY_ENDROD		198.0
#define ENTITY_PORTAL		90.0
#define ENTITY_BEACON		138.0
#define ENTITY_MAGMABLOCK	213.0
#define ENTITY_STAINEDGLASS 95.0
#define ENTITY_STAINEDGLASSPANE 96.0
#define ENTITY_SEALANTERN   169.0
#define ENTITY_GLASS		20.0
#define ENTITY_SNOW			78.0
#define ENTITY_ICE			79.0
#define ENTITY_SLIMEBLOCK	165.0
#define ENTITY_SEAGRASS		33.0

const float PI = 3.1415927;

varying vec4 color;
varying vec2 lmcoord;
varying vec4 lmcoord4;
varying float mat;
varying vec2 texcoord;
varying vec4 texcoord4;
varying vec3 normal;
varying float glowmult;
varying float glowing;
varying float canbewet;
varying vec3 worldpos;

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
	texcoord4 = gl_MultiTexCoord0;
	vec2 midcoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vec2 vtexcoord    = sign(texcoordminusmid)*0.5+0.5;
	mat = 0.01;
	glowmult = 1.0f;
	canbewet = 1.0f;
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	worldpos = position.xyz + cameraPosition;

	#ifdef WAVING_LEAVES	
	if ( mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_LEAVES_2 ){
			position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
			}
	#endif
	#ifdef WAVING_VINES
	if ( mc_Entity.x == ENTITY_VINES )
			if (mc_Entity.z == 1.0) {
				//South
				position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,0.0), vec3(0.5,0.1,0.1));
			}
			else if (mc_Entity.z == 2.0) {
				//West
				position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.0,0.2,1.0), vec3(0.1,0.1,0.5));
			}
			else if (mc_Entity.z == 4.0) {
				//North
				position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,0.0), vec3(0.5,0.1,0.1));
			}
			else if (mc_Entity.z == 8.0) {
				//East
				position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.0,0.2,1.0), vec3(0.1,0.1,0.5));
			}
	#endif
	#ifdef WAVING_CROPS
	if ( mc_Entity.x == ENTITY_MELON_ROOT || mc_Entity.x == ENTITY_PUMPKIN_ROOT ){
		if ( istopv < 0.1 ){
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.0,0.0,0.0), vec3(0.0,0.0,0.0));
		}
		else {
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.4,0.0,0.4), vec3(0.4,0.0,0.4));
		}
	}
	#endif
	if (istopv > 0.9) {
		#ifdef WAVING_GRASS
		float facingEast = abs(normalize(gl_Normal.xz).x);
		float facingUp = abs(gl_Normal.y);
		if ( mc_Entity.x == ENTITY_TALLGRASS)
				position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		if (mc_Entity.x == ENTITY_SEAGRASS)
				position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		if ( mc_Entity.x == 2.0 && gl_Normal.y <0.5 && facingEast > 0.01 && facingEast < 0.99 && facingUp < 0.9)
				position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		#endif
		#ifdef WAVING_FLOWERS
		if (mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_DEAD_BUSH || mc_Entity.x == ENTITY_SAPLING)
				position.xyz += calcMove(worldpos.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		#endif
		#ifdef WAVING_CROPS
		if ( mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == ENTITY_CARROT || mc_Entity.x == ENTITY_POTATO ||  mc_Entity.x == ENTITY_BEET )
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
	if ( mc_Entity.x == ENTITY_GLOWSTONE ){
		glowmult = 2.0f;
	}
	else if( mc_Entity.x == ENTITY_GLOWLAMP ){
		glowmult = 2.0f;
	}
	else if( mc_Entity.x == ENTITY_FIRE ){
		glowmult = 2.0f;
	}
	else if( mc_Entity.x == ENTITY_ENDROD){
		glowmult = 1.4f;
	}
	else if( mc_Entity.x == ENTITY_LAVAFLOWING ){
		glowmult = 4.5f;
	}
	else if( mc_Entity.x == ENTITY_LAVASTILL ){
		glowmult = 4.5f;
	}
	else if( mc_Entity.x == ENTITY_PORTAL ){
		glowmult = 0.9f;
	}
	else if( mc_Entity.x == ENTITY_BEACON ){
		glowmult = 1.2f;
	}
	else if( mc_Entity.x == ENTITY_MAGMABLOCK ){
		glowmult = 1.4f;
	}
	#endif
	if (mc_Entity.x == ENTITY_GLOWSTONE ||
		mc_Entity.x == ENTITY_LAVASTILL ||
		mc_Entity.x == ENTITY_GLOWLAMP ||
		mc_Entity.x == ENTITY_FIRE ||
		mc_Entity.x == ENTITY_ENDROD ||
		mc_Entity.x == ENTITY_LAVAFLOWING ||
		mc_Entity.x == ENTITY_PORTAL ||
		mc_Entity.x == ENTITY_BEACON ||
		mc_Entity.x == ENTITY_MAGMABLOCK ||
		mc_Entity.x == ENTITY_SEALANTERN)
	{
		glowing = 1.0;
	}
	float translucent = 1.0;
		if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_LEAVES_2 || mc_Entity.x == ENTITY_VINES || mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == ENTITY_BEET || mc_Entity.x == ENTITY_CARROT || mc_Entity.x == ENTITY_POTATO || mc_Entity.x == ENTITY_WEB || mc_Entity.x == ENTITY_NETHERWART || mc_Entity.x == ENTITY_DEAD_BUSH) {
			translucent = 0.5;
		}
	//Always Dry Blocks
	if (mc_Entity.x == ENTITY_WATERSTILL || mc_Entity.x == ENTITY_WATERFLOWING || mc_Entity.x == ENTITY_LAVAFLOWING || mc_Entity.x == ENTITY_LAVASTILL || mc_Entity.x == ENTITY_SNOW || mc_Entity.x == ENTITY_GLASS || mc_Entity.x == ENTITY_STAINEDGLASS || mc_Entity.x == ENTITY_SLIMEBLOCK)
	{
		canbewet = 0.0;
	}
	//Always Dry Blocks End
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	color = gl_Color;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord4 = (gl_TextureMatrix[1] * gl_MultiTexCoord1);
	normal = normalize(gl_NormalMatrix * gl_Normal);

	float ndotl = dot(normalize(sunPosition),normal);
	float ndotup = dot(normalize(upPosition),normal);
	float SdotU = dot(normalize(sunPosition),normalize(upPosition));
	float sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	float t1 = mix(mix(-ndotl,ndotl,sunVisibility),1.0,rainStrength*0.8);

	float lmult = 0.5*(sqrt(ndotup*0.45+0.55)+(t1*0.47+0.53));
	lmult = mix(1.0,pow(lmult,0.33),translucent);
	lmcoord.t *= lmult;
	lmcoord4.t *= lmult;

}
