#version 120

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;


void main() {

  texcoord = gl_MultiTexCoord0.st;
  color    = gl_Color;
  lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
