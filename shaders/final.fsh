#version 120

#define HDR_ON
#define SLOWHDR_ON

varying vec4 texcoord;
varying vec3 ambient_color;
varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;
varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D noisetex;
uniform sampler2D gcolor;
uniform int isEyeInWater;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;

float timefract = worldTime;

float RainPowerColorAmp(){
	float RainAmplifier;
	RainAmplifier = exp( -(pow(rainStrength, 2) / 2) ) ;
	return max(RainAmplifier, 0.5);
}

vec3 convertToHDR(in vec3 color){
  vec3 colorHDR;

	vec3 OEcolor;
	vec3 UEcolor;
	
	if (isEyeInWater == 1){
		UEcolor = color * RainPowerColorAmp() * 0.4f;
		OEcolor = color * RainPowerColorAmp() * 1.1f;
	}
	else {
		UEcolor = color * RainPowerColorAmp() * 0.5f;
		OEcolor = color * RainPowerColorAmp() * 1.2f;
	}

	#ifndef HDR_ON
	colorHDR = color * RainPowerColorAmp();
	#else
	colorHDR = mix(UEcolor, OEcolor, color);
	#endif

  return colorHDR;
}

vec3 ApplyEyeAdapt(in vec3 color){
	vec3 ColorAdapted;
	
	vec3 OEAdaptedColor;
	vec3 UEAdaptedColor;

	float time = worldTime;
	float TimeSunrise		= ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0) + (1.0 - (clamp(time, 0.0, 3000.0)/3000.0));
	float TimeNoon			= ((clamp(time, 0.0, 3000.0)) / 3000.0) - ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0);
	float TimeSunset		= ((clamp(time, 9000.0, 12000.0) - 9000.0) / 3000.0) - ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0);
	float TimeMidnight		= ((clamp(time, 12000.0, 14000.0) - 12000.0) / 2000.0) - ((clamp(time, 22000.0, 24000.0) - 22000.0) / 2000.0);
	float TimeDay			= TimeSunrise + TimeNoon + TimeSunset;
	
	float skyLight = max(eyeBrightnessSmooth.y/240.0,0.0);
	float skyLightTimeDep = max(1-rainStrength, 0.7) * ((skyLight * TimeDay) + ((skyLight * 0.7) * (1-TimeDay)));
	float blockLight = max(eyeBrightnessSmooth.x/240.0,0.0);
	float brightnessSum = min(skyLightTimeDep+(blockLight*1.5), 1.0);
	
	if (isEyeInWater == 1){
		UEAdaptedColor = color;
		OEAdaptedColor = color * 1.6f;
	}
	else {
		UEAdaptedColor = color;
		OEAdaptedColor = color * 3.0;
	}
	
	ColorAdapted = mix(OEAdaptedColor, UEAdaptedColor, brightnessSum);
	
	return ColorAdapted;
}

vec2 underwaterRefraction(vec2 coord){

	float	refractionMultiplier = 0.003;
	float	refractionSpeed	= 4.0;
	float refractionSize = 2.0;

	vec2 refractCoord = vec2(sin(frameTimeCounter * refractionSpeed + coord.x * 25.0 * refractionSize + coord.y * 12.5 * refractionSize));
	vec2 ret;
	if (isEyeInWater == 1)
	{
		ret = coord + refractCoord * refractionMultiplier;
	}
	else if (isEyeInWater == 2)
	{
		ret = coord + refractCoord * 0.5 * refractionMultiplier;
	}
	else
	{
		ret = coord;
	}
	
	return ret;

}

vec3 doFogBlur(vec3 clr, vec3 fragpos, vec2 coord) {

	float blurStartDistance = 75.0;
	float blurFactor = 3.0;
	float blendFactor = 0.6;

	if (bool(isEyeInWater)) {
		blurStartDistance = 7.5;
	} else {
		blendFactor *= rainStrength;
	}

	float fogFactor = (1.0 - exp(-pow(length(fragpos) / blurStartDistance, 2.0)));

	return mix(clr, texture2D(gcolor, coord.xy, blurFactor * fogFactor).rgb, blendFactor);

}


//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {

	vec2 newTexcoord = underwaterRefraction(texcoord.xy);

	vec3 color = texture2D(gcolor, newTexcoord.st).rgb;

	// Set up positions.
	vec4 fragposition = gbufferProjectionInverse * (vec4(newTexcoord.st, texture2D(depthtex1, newTexcoord.st).x, 1.0) * 2.0 - 1.0);
       fragposition /= fragposition.w;

	vec3 fragpos = vec3(newTexcoord.st, texture2D(depthtex0, newTexcoord.st).r);

	color.rgb = doFogBlur(color.rgb, fragposition.xyz, newTexcoord);
	
	#ifdef SLOWHDR_ON
	color.rgb = ApplyEyeAdapt(color.rgb);
	#endif
	
	color = convertToHDR(color);

  gl_FragColor = vec4(color.rgb, 1.0f);
}
