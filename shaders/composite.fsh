#version 120

#define CLOUDS2D
#define UWFOG

varying vec4 texcoord;
varying vec2 texcoord2;

varying float weatherRatio;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform vec3 upPosition;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float frameTimeCounter;
uniform float wetness;
uniform float rainStrength;
uniform float near;
uniform float far;

uniform int worldTime;

uniform int isEyeInWater;

const int RGBA16 = 1;
const int gcolorformat = RGBA16;

const int noiseTextureResolution = 64;

//varsinit

float comp = 1.0 - near / far / far;
bool hand = texture2D(depthtex0, texcoord2.st).x < 0.56;
float depth0 = texture2D(depthtex0, texcoord2.st).x;
float depth1 = texture2D(depthtex1, texcoord2.st).x;
bool sky	= depth1 > comp;
float gaux3Material = texture2D(gaux3, texcoord2.st).b;
bool water = gaux3Material > 0.09 && gaux3Material < 0.11;

//varsinitend
float time = worldTime;
float TimeSunrise		= ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
float TimeNoon			= ((clamp(time, 0.0, 3000.0)) / 3000.0) - ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0);
float TimeSunset		= ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0);
float TimeMidnight	= ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0) - ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0);

float TimeDay			= TimeSunrise + TimeNoon + TimeSunset;
//2DCLOUDS 
float subSurfaceScattering(vec3 vec, vec3 pos, float N) {
	return pow(max(dot(vec, normalize(pos)), 0.0), N) * (N + 1.0) / 6.28;
}

float subSurfaceScattering2(vec3 vec, vec3 pos, float N) {
	return pow(max(dot(vec, normalize(pos)) * 0.5 + 0.5, 0.0), N) * (N + 1.0) / 6.28;
}

float getWorldHorizonPos(vec3 fragpos) {

	float position		= dot(normalize(fragpos.xyz), upPosition);
	float horizonPos	= mix(clamp(1.0 - pow(abs(position) / 10.0, 0.8), 0.0, 1.0), 1.0, 1.0 - clamp(position + length(position), 0.0, 1.0));

	return horizonPos;

}

float getCloudNoise2D(vec3 fragpos, int integer_i) {

	float cloudWindSpeed 	= 0.2;
	float cloudCover 		= 0.65;
	float cloudThickness = 3.5;
	float cloudScale = 170.0;

	float noise2dcl = 0.0;

	#ifdef CLOUDS2D

		vec2 wind = vec2(frameTimeCounter * cloudWindSpeed / 500.0);

		vec4 worldPosCL = gbufferModelViewInverse * vec4(fragpos.xyz, 1.0);
		vec3 worldVectorCL = normalize(worldPosCL.xyz);

		float position = dot(normalize(fragpos.xyz), upPosition);

		worldVectorCL *= (1.0 - integer_i * cloudThickness + 300.0) / worldVectorCL.y;

		vec2 coord2dcl = (worldVectorCL.xz / 130.0 / cloudScale) + wind / 2.5;

		noise2dcl += texture2D(noisetex, coord2dcl					- wind).x;
		noise2dcl += texture2D(noisetex, coord2dcl * 3.5		- wind).x / 3.5;
		noise2dcl += texture2D(noisetex, coord2dcl * 12.25	- wind).x / 12.25;
		noise2dcl += texture2D(noisetex, coord2dcl * 42.87	- wind).x / 42.87;

	#endif

	cloudCover = mix(1.25, 0.1, sqrt(weatherRatio));

	return max(noise2dcl - cloudCover, 0.0);

}

vec3 draw2DClouds(vec3 clr, vec3 fragpos, vec3 sunClr, vec3 moonClr, vec3 cloudClr) {

	float cloudOpacity = 1.8;

	#ifdef CLOUDS2D

		vec4 worldPosCL = gbufferModelViewInverse * vec4(fragpos.xyz, 1.0) / far * 128.0;
		vec3 worldVectorCL = normalize(worldPosCL.xyz);

		float position = dot(normalize(fragpos.xyz), upPosition);
		float horizonPos = max(1.0 - pow(abs(position) / 75.0, 1.0), 0.0);

		vec4 totalcloud = vec4(0.0);

		float cloudDensity = mix(1.0, 0.5, weatherRatio);
		float surfaceScattering = mix(1.0, 0.4, weatherRatio);
		float lightVecSurfaceScattering = mix(((0.4 * TimeSunrise) + (0.3 * TimeSunset)), 0.2, weatherRatio);

		for (int i = 0; i < 8; i++) {

			float cl = getCloudNoise2D(fragpos, i);
			float density = pow(max(1.0 - cl * cloudDensity, 0.0) * (i / 5.0), 2.0);

			vec3 c = cloudClr;
				 	 c = mix(c, sunClr * 0.5, min(subSurfaceScattering2(normalize(sunPosition), fragpos.xyz, 0.1) * pow(density, 2.0) * TimeDay * surfaceScattering, 1.0));
					 c = mix(c, sunClr * (2.0 * rainStrength), min(subSurfaceScattering(normalize(sunPosition), fragpos.xyz, 10.0) * pow(density, 3.0) * (1.0 - TimeNoon) * (1.0 - TimeMidnight * 0.8) * lightVecSurfaceScattering, 1.0));

				 	 c = mix(c, moonClr * (3.0 - (rainStrength * 2.0)), subSurfaceScattering2(normalize(moonPosition), fragpos.xyz, 0.1) * pow(density, 2.0) * TimeMidnight * 0.4 * surfaceScattering);
				 	 c = mix(c, moonClr * (6.0 - (rainStrength * 2.0)), subSurfaceScattering(normalize(moonPosition), fragpos.xyz, 10.0) * pow(density, 3.0) * TimeMidnight * 0.2 * lightVecSurfaceScattering);

			cl = max(cl - (abs(i - 8.0) / 8.) * 0.2, 0.) * 0.08;

			totalcloud += vec4(c.rgb * exp(-totalcloud.a), cl * 1.0);

		}

		totalcloud.a = mix(totalcloud.a, 0.0, horizonPos);
		totalcloud.a = mix(totalcloud.a, 0.0, getWorldHorizonPos(fragpos.xyz));

		clr.rgb = mix(clr.rgb, totalcloud.rgb, min(totalcloud.a * cloudOpacity, 1.0));

	#endif

	return clr;

}
//END 2DCLOUDS
//UnderwaterFog
vec3 drawUnderwaterFog(vec3 clr, vec3 fogClr, vec3 fragpos) {

	float fogStartDistance	= 15.0;	// Higher -> far.
	float fogDensity 				= 1.0;

	vec4 worldPos = gbufferModelViewInverse * vec4(fragpos, 1.0);

	float fogFactor = 1.0 - exp(-pow(length(fragpos.xyz) / fogStartDistance, 2.0));
		  	fogFactor = mix(0.0, fogFactor, fogDensity);

	if (bool(isEyeInWater)) clr = mix(clr.rgb * vec3(0.6, 0.8, 1.0), fogClr, fogFactor);

	return clr;

}
//UnderwaterFogEND

/* DRAWBUFFERS:012 */

void main() {
  vec3 finalComposite = texture2D(gcolor, texcoord.st).rgb;
  
  vec4 aux = texture2D(gaux1, texcoord.st);
  float no_hand = float(aux.g < 0.35 || 0.45 < aux.g);
#ifdef CLOUDS2D
  vec4 skyFragposition  = gbufferProjectionInverse * (vec4(texcoord2.st, 1.0, 1.0) * 2.0 - 1.0);
  skyFragposition /= skyFragposition.w;
  //Cloud colors
  vec3 cloud_Color  = vec3(0.0);
			 cloud_Color += vec3(1.0, 0.8, 0.6)		* 0.2		* TimeSunrise;
			 cloud_Color += vec3(1.0, 0.9, 0.8)		* 0.2		* TimeNoon;
			 cloud_Color += vec3(1.0, 0.8, 0.6)		* 0.2		* TimeSunset;
			 cloud_Color += vec3(0.7, 0.8, 1.0)		* 0.01	* TimeMidnight;

			 cloud_Color *= 1.0 - weatherRatio;
 			 cloud_Color += vec3(1.0, 1.0, 1.0)		* 0.1		* TimeSunrise		* weatherRatio;
 			 cloud_Color += vec3(0.9, 0.95, 1.0)	* 0.1		* TimeNoon			* weatherRatio;
 			 cloud_Color += vec3(1.0, 1.0, 1.0)		* 0.1		* TimeSunset		* weatherRatio;
			 cloud_Color += vec3(0.7, 0.8, 1.0)		* 0.007	* TimeMidnight	* weatherRatio;

  vec3 cloudSun_Color  = vec3(0.0);
			 cloudSun_Color += vec3(1.0, 0.7, 0.4)			* TimeSunrise;
			 cloudSun_Color += vec3(1.0, 0.85, 0.7) 		* TimeNoon;
			 cloudSun_Color += vec3(1.0, 0.7, 0.4)			* TimeSunset;
			 cloudSun_Color += vec3(1.0, 0.45, 0.2)			* TimeMidnight;

			 cloudSun_Color *= 1.0 - weatherRatio;
			 cloudSun_Color += vec3(1.0, 0.9, 0.8)			* TimeSunrise		* weatherRatio;
			 cloudSun_Color += vec3(1.0, 1.0, 1.0)			* TimeNoon			* weatherRatio;
			 cloudSun_Color += vec3(1.0, 0.9, 0.8)			* TimeSunset		* weatherRatio;
			 cloudSun_Color += vec3(1.0, 0.45, 0.2)			* TimeMidnight	* weatherRatio;

  vec3 cloudMoon_Color = vec3(0.85, 0.9, 1.0)					* TimeMidnight;

			 cloudMoon_Color *= 1.0 - weatherRatio;
			 cloudMoon_Color += vec3(0.85, 0.9, 1.0) * 0.5	* TimeMidnight		* weatherRatio;
  //end cloudcolors
  if (sky) finalComposite.rgb = draw2DClouds(finalComposite.rgb, skyFragposition.xyz, cloudSun_Color, cloudMoon_Color, cloud_Color);
#endif
#ifdef UWFOG
  vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord2.st, depth0, 1.0) * 2.0 - 1.0);
  fragposition0 /= fragposition0.w;
  vec3 underwater_Color  = vec3(0.0);
		   underwater_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunrise;
		   underwater_Color += vec3(0.3, 0.65, 1.0)				* TimeNoon;
		   underwater_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunset;
		   underwater_Color += vec3(0.0, 0.6, 1.0)	* 0.1	* TimeMidnight;
  finalComposite.rgb = drawUnderwaterFog(finalComposite.rgb, underwater_Color * 0.13, fragposition0.xyz);
#endif
  vec3 finalCompositeNormal = texture2D(gcolor, texcoord.st).rgb;
  vec3 finalCompositeDepth = texture2D(gcolor, texcoord.st).rgb;

  gl_FragData[0] = vec4(finalComposite, 1.0);
  gl_FragData[1] = vec4(finalCompositeNormal, 1.0);
  gl_FragData[2] = vec4(finalCompositeDepth, 1.0);

}
