#version 120

varying vec4 texcoord;

uniform sampler2D gcolor;
uniform int isEyeInWater;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;

float timefract = worldTime;

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

  gl_FragColor = vec4(color.rgb, 1.0f);
}
