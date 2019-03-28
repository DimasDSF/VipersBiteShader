#version 120

varying vec4 color;
varying vec4 texcoord;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform vec3 skyColor;
uniform float rainStrength;

uniform int worldTime;

varying float mat;




void main() {

	vec4 fColor = texture2D(texture, texcoord.st) * color;
	bool water = mat > 0.09 && mat < 0.11;
	bool ice = mat > 0.19 && mat < 0.21;
	bool stainedGlass = mat > 0.29 && mat < 0.31;
	bool portal = mat > 0.39 && mat < 0.41;
	
	float time = worldTime;
	float TimeSunrise		= ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
	float TimeNoon			= ((clamp(time, 0.0, 3000.0)) / 3000.0) - ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0);
	float TimeSunset		= ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0);
	float TimeMidnight	= ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0) - ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0);
	
	vec3 water_Color  = vec3(0.0);
		water_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunrise;
		water_Color += vec3(0.3, 0.65, 1.0)				* TimeNoon;
		water_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunset;
		water_Color += vec3(0.0, 0.6, 1.0)	* 0.1	* TimeMidnight;
	
	if (water) fColor = vec4(mix(color.rgb,mix(water_Color*0.5,skyColor,rainStrength),0.4), 0.85);

/* DRAWBUFFERS:06 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4
  
  gl_FragData[0] = fColor * texture2D(lightmap, lmcoord.st);
  gl_FragData[1] = vec4(lmcoord.t, lmcoord.s, mat, 1.0);

}
