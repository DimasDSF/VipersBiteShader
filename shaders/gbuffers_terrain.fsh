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

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

	gl_FragData[0] = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * glowmult * color;
	gl_FragData[1] = vec4(lmcoord.t, mat, lmcoord.s, 1.0);
}
