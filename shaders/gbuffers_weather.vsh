#version 120

const float PI = 3.1415927;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform float rainStrength;

void main() {
	//gl_Position = ftransform();
	//gl_Position.z = 0.0f;
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	vec3 worldpos = position.xyz + cameraPosition;
	
	bool istopv = worldpos.y > cameraPosition.y+5.0;
	
	if (!istopv) position.xz += vec2(1.0,1.0)+sin(frameTimeCounter)*sin(frameTimeCounter)*sin(frameTimeCounter)*vec2(1.1,0.6);
	position.xz -= (vec2(1.0,1.0)+sin(frameTimeCounter)*sin(frameTimeCounter)*sin(frameTimeCounter)*vec2(1.1,0.6))*0.5;
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	color = gl_Color * 0.65;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
}