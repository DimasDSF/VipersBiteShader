#version 120

varying vec4 texcoord;
varying vec2 texcoord2;

varying float weatherRatio;

uniform int worldTime;

uniform float rainStrength;
uniform float frameTimeCounter;

uniform sampler2D noisetex;

uniform mat4 gbufferProjection;

float getWeatherRatio() {

  float value = rainStrength;

  float weatherRatioSpeed	= 0.01;

  value = pow(texture2D(noisetex, vec2(1.0) + vec2(frameTimeCounter * 0.005) * weatherRatioSpeed).x, 2.0);

  // Raining.
 value = mix(value, 1.0, rainStrength);

  return value;

}

void main() {
gl_Position = ftransform();

texcoord = gl_MultiTexCoord0;
texcoord2 = gl_MultiTexCoord0.st;
	
weatherRatio = getWeatherRatio();

}
