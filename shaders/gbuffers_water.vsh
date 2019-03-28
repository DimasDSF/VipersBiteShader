#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec2 lmcoord;

varying float mat;

varying vec3 worldpos;

attribute vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;

#define WAVING_WATER

#define ENTITY_WATERFLOWING	8.0
#define ENTITY_WATERSTILL	9.0
#define ENTITY_STAINEDGLASS 95.0
#define ENTITY_STAINEDGLASSPANE 96.0
#define ENTITY_ICE			79.0
#define ENTITY_PORTAL		90.0
#define ENTITY_SLIMEBLOCK	165.0

const float PI = 3.1415927;

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

void main() {

	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	color    = gl_Color;
	mat = 0.01f;
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	worldpos = position.xyz + cameraPosition;
	#ifdef WAVING_WATER
	if ( mc_Entity.x == ENTITY_WATERFLOWING || mc_Entity.x == ENTITY_WATERSTILL) {
			position.xyz += calcWaterMove(worldpos.xyz) * 0.25;
	}
	#endif
	
	if (mc_Entity.x == ENTITY_WATERSTILL || mc_Entity.x == ENTITY_WATERFLOWING){
		mat = 0.1;
	}
	else if (mc_Entity.x == ENTITY_ICE) {
		mat = 0.2;
	}
	else if( mc_Entity.x == ENTITY_STAINEDGLASS || mc_Entity.x == ENTITY_STAINEDGLASSPANE || mc_Entity.x == ENTITY_SLIMEBLOCK){
		mat = 0.3;
	}
	else if(mc_Entity.x == ENTITY_PORTAL){
		mat = 0.4;
	}
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
