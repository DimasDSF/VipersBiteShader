#version 120

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor;

void main() {


/* DRAWBUFFERS:01 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

  vec4 endColor = vec4(color.rgb + (entityColor.rgb / 2), color.a);
  gl_FragData[0] = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * endColor;
  gl_FragData[1] = vec4(lmcoord.t, lmcoord.s, 0.2, 1.0);
}
