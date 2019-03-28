#version 120


uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

void main() {

	/* DRAWBUFFERS:06 */
	
	// 0 = gcolor
	// 1 = gdepth
	// 2 = gnormal
	// 3 = composite
	// 4 = gaux1
	// 5 = gaux2
	// 6 = gaux3
	// 7 = gaux4

	gl_FragData[0] = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * color;
	gl_FragData[1] = vec4(lmcoord.t, lmcoord.s, 0.7, 1.0);
		
}