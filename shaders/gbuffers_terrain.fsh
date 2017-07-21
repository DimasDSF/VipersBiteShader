#version 120

#define RAIN_PUDDLES

varying vec2 lmcoord;
varying vec4 lmcoord4;
varying vec4 color;
varying float mat;
varying vec2 texcoord;
varying vec4 texcoord4;
varying vec3 normal;
varying vec3 worldpos;
varying float canbewet;

varying float glowmult;

uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform vec3 upPosition;
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform float wetness;

vec3 Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;
	vec3 p = floor(pos);
	vec3 f = fract(pos);
		 f = f * f * (3.0f - 2.0f * f);

	vec2 uv =  (p.xy + p.z * vec2(17.0f, 37.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f, 37.0f)) + f.xy;
	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	vec3 xy1 = texture2D(noisetex, coord).xyz;
	vec3 xy2 = texture2D(noisetex, coord2).xyz;
	return mix(xy1, xy2, vec3(f.z));
}

float GetModulatedRainSpecular(in vec3 pos)
{
	//pos.y += frameTimeCounter * 3.0f;
	pos.xz *= 1.0f;
	pos.y *= 0.2f;

	// pos.y += Get3DNoise(pos.xyz * vec3(1.0f, 0.0f, 1.0f)).x * 2.0f;

	vec3 p = pos;

	float n = Get3DNoise(p).y;
		  n += Get3DNoise(p / 2.0f).x * 2.0f;
		  n += Get3DNoise(p / 4.0f).x * 4.0f;

		  n /= 7.0f;

	return n;
}


//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {


#ifdef RAIN_PUDDLES
//RainSpec

vec2 parallaxCoord = texcoord4.st;

float w = wetness;
vec4 spec = texture2D(specular, parallaxCoord);

float wet = GetModulatedRainSpecular(worldpos.xyz) * (lmcoord.t);
wet = clamp(wet * 1.5f - 0.2f, 0.0f, 1.0f);
spec.g *= max(0.0f, clamp((wet * 1.0f + 0.2f), 0.0f, 1.0f) - (1.0f - w) * 1.0f);
spec.b += max(0.0f, (wet) - (1.0f - w) * 1.0f) * w;

vec4 lightmap4 = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	lightmap4.r = clamp((lmcoord4.s * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	lightmap4.b = clamp((lmcoord4.t * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

	lightmap4.b = pow(lightmap4.b, 1.0f);
	lightmap4.r = pow(lightmap4.r, 3.0f);

float wetfactor = clamp(lightmap4.b * 1.05f - 0.9f, 0.0f, 0.1f) / 0.1f;
	 	   wetfactor *= w;
spec.g *= wetfactor;

vec4 rainpuddlesccolor = color;
if (canbewet > 0.90)
{
	rainpuddlesccolor = color - vec4(color.r/2 * spec.b, color.g/2 * spec.b, color.b/2 * spec.b, color.a/2 * spec.g);
}
 

//RainSpecEND
#else
vec4 rainpuddlesccolor = color;
#endif


/* DRAWBUFFERS:04 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

	gl_FragData[0] = (texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * glowmult * rainpuddlesccolor);
	gl_FragData[1] = vec4(lmcoord.t, mat, lmcoord.s, 1.0);
}
