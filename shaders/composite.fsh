#version 120

#define CLOUDS2D
#define STARS
#define MOONSUN
#define iMOONSIZE 1 // [1 2 3 4]
#define iSUNGLOWSIZE 1.0 // [1.0 2.0 3.0 4.0]
#define UWFOG
#define FOG

varying vec4 texcoord;
varying vec2 texcoord2;

varying float weatherRatio;

uniform sampler2D gcolor;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D texture;
uniform sampler2D normal;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec3 upPosition;

uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform float frameTimeCounter;
uniform float wetness;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform vec3 skyColor;

uniform int worldTime;

uniform int isEyeInWater;

const int RGBA16 = 1;
const int gcolorformat = RGBA16;

const int noiseTextureResolution = 128; // [64 128]

//varsinit

float comp = 1.0 - near / far / far;
bool hand = texture2D(depthtex0, texcoord2.st).x < 0.56;
float depth0 = texture2D(depthtex0, texcoord2.st).x;
float depth1 = texture2D(depthtex1, texcoord2.st).x;
bool sky	= depth1 > comp;
bool land = depth1 < comp;
float gaux3Material = texture2D(gaux3, texcoord2.st).b;
bool water = gaux3Material > 0.09 && gaux3Material < 0.11;
bool ice = gaux3Material > 0.19 && gaux3Material < 0.21;
bool stainedGlass = gaux3Material > 0.29 && gaux3Material < 0.31;
bool portal = gaux3Material > 0.39 && gaux3Material < 0.41;
bool raindrops = gaux3Material > 0.69 && gaux3Material < 0.71;
bool handgaux = gaux3Material > 0.49 && gaux3Material < 0.51;
bool GAUX1 = gaux3Material > 0.0;

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

				 	 c = mix(c, moonClr , subSurfaceScattering2(normalize(moonPosition), fragpos.xyz, 0.1) * pow(density, 2.0) * TimeMidnight * 0.4 * surfaceScattering);
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
//Moon/Sun
vec3 drawMoonSun(vec3 clr, vec3 fragpos, vec3 sunClr, vec3 moonClr) {

	float sunSkyIlluminationRadius = mix(20.0, 7.5, iSUNGLOWSIZE/4.0f);

	// Get position.
	float sunVector = max(dot(normalize(fragpos), normalize(sunPosition)), 0.0);
	float moonVector = max(dot(normalize(fragpos), normalize(moonPosition)), 0.0);

	// Calculate light vectors.
	float sun	= clamp(pow(sunVector, 2000.0) * 3.0, 0.0, 1.0);
	float moon = clamp(pow(moonVector, (10000 - (iMOONSIZE * 2000))) * 10.0, 0.0, 1.0);
	float sunSkyIllumination = pow(sunVector, sunSkyIlluminationRadius) * 0.3;
	sunSkyIllumination *= 1.7;
	
	float sunFactor = sun + sunSkyIllumination;

	sunFactor	= mix(sunFactor, 0.0, getWorldHorizonPos(fragpos.xyz));
	sunFactor	= mix(sunFactor, sunFactor / 4.0, TimeMidnight);
	moon			= mix(moon, 0.0, getWorldHorizonPos(fragpos.xyz));

	clr = mix(clr, sunClr, sunFactor * (1.0 - rainStrength));
	clr = mix(clr, moonClr, moon * (1.0 - rainStrength));

	return clr;

}
//Moon/Sun
//STARS
vec3 drawStars(vec3 clr, vec3 fragpos) {

	float starsScale = 20.0;
	float starsMovementSpeed = 500.0;

	vec4 worldPos = gbufferModelViewInverse * vec4(fragpos.xyz, 1.0);

	float position = dot(normalize(fragpos.xyz), upPosition);
	float horizonPos = max(1.0 - pow(abs(position) / 75.0, 1.0), 0.0);

	vec2 coord = (worldPos.xz / (worldPos.y / pow(position, 0.75)) / starsScale) + vec2(frameTimeCounter / starsMovementSpeed);

	float noise  = texture2D(noisetex, coord).x;
				noise += texture2D(noisetex, coord * 2.0).x / 2.0;
				noise += texture2D(noisetex, coord * 4.0).x / 4.0;
				noise += texture2D(noisetex, coord * 8.0).x / 8.0;

	noise = max(noise - 1.5, 0.0);
	noise = mix(noise, 0.0, clamp(getWorldHorizonPos(fragpos) + horizonPos + getCloudNoise2D(fragpos, 0), 0.0, 1.0));

	return mix(clr, vec3(1.0) * 20, noise * TimeMidnight * (1 - rainStrength) );

}
//ENDSTARS
//UnderwaterFog
vec3 drawUnderwaterFog(vec3 clr, vec3 fogClr, vec3 fogClrLava, vec3 fragpos) {

	float fogStartDistance	= 7.0;	// Higher -> far.
	float fogDensity 				= 0.8;
	if (isEyeInWater == 2) {
		fogStartDistance = 1.0;
		fogDensity = 0.99;
	}

	float fogFactor = 1.0 - exp(-pow(length(fragpos.xyz) / fogStartDistance, 2.0));
		  	fogFactor = mix(0.0, fogFactor, fogDensity);

	if (bool(isEyeInWater))
	{
		if (isEyeInWater == 1)
		{
			clr = mix(clr.rgb * vec3(0.6, 0.8, 1.0), fogClr, fogFactor);
		}
		else if(isEyeInWater == 2)
		{
			clr = mix(clr.rgb * vec3(0.6, 0.8, 1.0), fogClrLava, fogFactor);
		}
	}
	return clr;

}
//UnderwaterFogEND

//WeatherFXFog
vec3 drawWeatherFXFog(vec3 clr, vec3 fogClr, vec3 fragpos) {
	float fogBaseDistance = 75.0;
	float fogMinDistance = 15.0;

	float fogTimeDistance	= (TimeSunrise * 10) + (TimeSunset * 10) + (TimeMidnight * 15);
	float fogWeatherDistance = (rainStrength * 5.0) + (wetness * 35.0);
	float fogWeatherDensity = (0.6 * wetness) + (0.3 * rainStrength); //0.5 Max
	float fogDayTimeDensity = (0.4 * TimeSunrise) + (0.4 * TimeSunset) + (TimeMidnight * 0.6);
	
	float fogStartDistance = max(fogBaseDistance - (fogTimeDistance + fogWeatherDistance), fogMinDistance);
	float fogDensity = min(fogWeatherDensity + fogDayTimeDensity, 0.9);
	

	float fogFactor = 1.0 - exp(-pow(length(fragpos.xyz) / fogStartDistance, 2.0));
		  	fogFactor = mix(0.0, fogFactor, fogDensity);
			
	clr = mix(clr.rgb, fogClr, min(fogFactor,1.0));
	
	return clr;
}
//WeatherFXFogEND

float mapval(float value, float explow, float exphigh, float outlow, float outhigh) {
	if (outlow > outhigh)
	{
		return clamp(outlow + (value - explow) * (outhigh - outlow) / (exphigh - explow),outhigh,outlow);
	}
	else
	{
		return clamp(outlow + (value - explow) * (outhigh - outlow) / (exphigh - explow),outlow,outhigh);
	}
}

int roundval(float val) {
	/*highp int ret = int(val);
	if (val - ret > 0.5) ret += 1;
	return ret;*/
	if (val >= 0.5){
		return 1;
	}
	else
	{
		return 0;
	}
}

/* DRAWBUFFERS:012 */

void main() {
  vec3 finalComposite = texture2D(gcolor, texcoord.st).rgb;
  
  vec4 aux = texture2D(gaux1, texcoord.st);
  vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord2.st, depth0, 1.0) * 2.0 - 1.0);
  fragposition0 /= fragposition0.w;
  vec4 fragposition1  = gbufferProjectionInverse * (vec4(texcoord2.st, depth1, 1.0) * 2.0 - 1.0);
  fragposition1 /= fragposition1.w;
  if (sky) finalComposite.rgb = skyColor;
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
  if (sky && !raindrops) finalComposite.rgb = draw2DClouds(finalComposite.rgb, skyFragposition.xyz, cloudSun_Color, cloudMoon_Color, cloud_Color);
#endif
#ifdef STARS
if (sky) finalComposite.rgb = drawStars(finalComposite.rgb, skyFragposition.xyz);
#endif
#ifdef MOONSUN
vec3 sun_Color  = vec3(0.0);
			 sun_Color += vec3(1.0, 0.8, 0.6) 	* 1.6	* TimeSunrise;
			 sun_Color += vec3(1.0, 0.93, 0.85) * 1.6	* TimeNoon;
			 sun_Color += vec3(1.0, 0.8, 0.6) 	* 1.6	* TimeSunset;
			 sun_Color += vec3(1.0, 0.45, 0.2)				* TimeMidnight;

vec3 moon_Color = vec3(1.0) * 2.0;

if (sky) finalComposite.rgb = drawMoonSun(finalComposite.rgb, skyFragposition.xyz, sun_Color, moon_Color);
#endif
vec3 underwater_Color  = vec3(0.0);
		underwater_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunrise;
		underwater_Color += vec3(0.3, 0.65, 1.0)				* TimeNoon;
		underwater_Color += vec3(0.3, 0.65, 1.0)	* 0.6	* TimeSunset;
		underwater_Color += vec3(0.0, 0.6, 1.0)	* 0.1	* TimeMidnight;
vec3 lava_Color = vec3(1.0, 1.0, 0.05);
finalComposite.rgb = drawUnderwaterFog(finalComposite.rgb, underwater_Color * 0.30, lava_Color, fragposition0.xyz);
if (portal) finalComposite.rgb = mix(finalComposite.rgb * vec3(1.0,1.0,mapval(sin(frameTimeCounter),0.0,1.0,1.0,2.0)),vec3(0.0,0.0,0.0),min(1.0,max(0.0,length((gbufferModelViewInverse * vec4(fragposition0.xyz, 1.0)).xyz)*0.05)));
#ifdef FOG
vec3 fog_Color = vec3(0.0);
		fog_Color += vec3(0.8, 0.8, 0.8) * 0.4		* TimeSunrise;
		fog_Color += vec3(0.8, 0.8, 0.8) * 0.7		* TimeNoon;
		fog_Color += vec3(0.8, 0.8, 0.8) * 0.4		* TimeSunset;
		fog_Color += vec3(0.8, 0.8, 0.8) * 0.15		* TimeMidnight;
		if (stainedGlass || ice) finalComposite.rgb = mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz),texture2D(texture,texcoord.st).rgb,0.5);
		if (isEyeInWater == 1) finalComposite.rgb = mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), vec3(0.3, 0.65, 1.0) * 0.3, 0.5);
		if(isEyeInWater == 0 && sky && water){
			//finalComposite.rgb = mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), mix(vec3(0.3, 0.65, 1.0) * TimeDay, skyColor + fog_Color, rainStrength), 0.3);
			//finalComposite.rgb = mix(mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), mix(vec3(0.3, 0.65, 1.0) * TimeDay, skyColor + fog_Color, rainStrength), 0.3), mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), vec3(0.3, 0.65, 1.0) * 0.3 * max(0.45, TimeDay), 0.6), roundval(length((gbufferModelViewInverse * vec4(fragposition1.xyz, 1.0)).xyz)*min(((1/far)+0.0007),1.0)));
			//finalComposite.rgb = mix(mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), mix(vec3(0.3, 0.65, 1.0) * TimeDay, skyColor + fog_Color, rainStrength), 0.3), mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), vec3(0.3, 0.65, 1.0) * 0.3 * max(0.45, TimeDay), 0.6), roundval(length((gbufferModelViewInverse * vec4(fragposition1.xyz, 1.0)).xyz)*min(((1/far)+0.0007),1.0)));
			if (roundval(length((gbufferModelViewInverse * vec4(fragposition1.xyz, 1.0)).xyz)*min(((1/far)+0.0007),1.0)) == 0) finalComposite.rgb = mix(finalComposite.rgb,mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), mix(vec3(0.3, 0.65, 1.0) * TimeDay, skyColor + fog_Color, rainStrength), 0.3), 0.5);
			if (roundval(length((gbufferModelViewInverse * vec4(fragposition1.xyz, 1.0)).xyz)*min(((1/far)+0.0007),1.0)) == 1) finalComposite.rgb = mix(finalComposite.rgb,mix(drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition1.xyz), vec3(0.3, 0.65, 1.0) * 0.3 * max(0.45, TimeDay), 0.6), 0.5);
		}
		if(isEyeInWater == 0) finalComposite.rgb = drawWeatherFXFog(finalComposite.rgb, fog_Color, fragposition0.xyz);
#else
	if (stainedGlass || ice) finalComposite.rgb = mix(finalComposite.rgb,texture2D(texture,texcoord.st).rgb,0.5);
	if (isEyeInWater == 1) finalComposite.rgb = mix(finalComposite.rgb, vec3(0.3, 0.65, 1.0) * 0.3, 0.5);
#endif

  vec3 finalCompositeNormal = texture2D(normal, texcoord.st).rgb;
  vec3 finalCompositeDepth = texture2D(gcolor, texcoord.st).rgb;

  gl_FragData[0] = vec4(finalComposite, 1.0);
  gl_FragData[1] = vec4(finalCompositeNormal, 1.0);
  gl_FragData[2] = vec4(finalCompositeDepth, 1.0);

}
