#version 120

#define SHAKING_HAND

varying vec2 texcoord;
varying vec4 color;
varying vec2 lmcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

void main() {

	texcoord      = gl_MultiTexCoord0.st;
	color 		  = gl_Color;
	lmcoord       = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	#ifdef SHAKING_HAND
		position -= vec4(0.02 * sin(frameTimeCounter * 2.0), 0.005 * cos(frameTimeCounter * 3.0), 0.0, 0.0) * gbufferModelView;
	#endif
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}