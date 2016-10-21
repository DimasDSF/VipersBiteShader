#version 120

varying vec2 lmcoord;
varying vec4 color;
varying float mat;
varying vec2 texcoord;
varying vec3 normal;

varying float glowmult;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform float wetness;

//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {

/* DRAWBUFFERS:04 */

	gl_FragData[0] = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * glowmult * color;
	gl_FragData[1] = vec4(lmcoord.t, mat, lmcoord.s, 1.0);
}
