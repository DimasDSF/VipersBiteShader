#version 120

varying vec4 color;
varying vec2 texcoord;

uniform sampler2D texture;

void main() {

	vec4 baseColor = texture2D(texture, texcoord.st) * color;


/* DRAWBUFFERS:01 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

  gl_FragData[0] = baseColor * 900000000000.0;
  gl_FragData[1] = vec4(8.0, 8.0, 0.0, 1.0) * 900000000000.0;

}
