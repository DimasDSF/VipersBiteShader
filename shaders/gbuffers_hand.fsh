#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;


void main() {
	vec4 baseColor = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * color;
	
	/* DRAWBUFFERS:06 */
	
	// 0 = gcolor
	// 1 = gdepth
	// 2 = gnormal
	// 3 = composite
	// 4 = gaux1
	// 5 = gaux2
	// 6 = gaux3
	// 7 = gaux4
	
	gl_FragData[0] = baseColor;
	gl_FragData[1] = vec4(lmcoord.t, lmcoord.s, 0.5, 1.0);
}