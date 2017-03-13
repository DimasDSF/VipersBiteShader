#version 120

#define CLOUDS

varying vec4 texcoord;
varying vec3 ambient_color;

varying float gp00;
varying float gp11;
varying float gp22;
varying float gp32;
varying vec2 igp;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float wetness;
uniform float rainStrength;

const int RGBA16 = 1;
const int gcolorformat = RGBA16;

const int noiseTextureResolution = 64;

vec3 invproj(in vec3 p) {
//    vec4 pos = gbufferProjectionInverse * vec4(p * 2.0 - 1.0, 1.0);
//    return pos.xyz / pos.w;
    vec3 pos = p - 0.5;
    float z = gp32 / (pos.z + gp22);
    return vec3(pos.xy * igp, -1.0) * z;
}

float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    return mix(texture2D(noisetex, uv/noiseTextureResolution).x, texture2D(noisetex, (uv + vec2(37.0, 17.0))/noiseTextureResolution).x, f.z);
}

float getCloudNoise(in vec3 worldPos) {
    vec3 coord = worldPos;
    coord.x += frameTimeCounter * 3.0;
    coord *= 0.02;
    float n = noise(coord) * 0.5;
    n += noise(coord * 3.0) * 0.25;
    n += noise(coord * 9.0) * 0.125;
    n += noise(coord * 27.0) * 0.0625;
    n += noise(coord * 81.0) * 0.03125;
    float rain_effect = (0.16 + (rainStrength * 0.16)) * min(1.25, wetness + rainStrength) - 0.6;
    return max(n + rain_effect, 0.0) / (1.0 + rain_effect);
}

float cloudRayMarching(in vec3 start, in vec3 end) {
    vec3 dir = normalize(end - start);
    float ay = abs(dir.y);
    float cutoff = abs((80.0 + 110.0) * 0.5 - start.y) * 0.0025;
    if (max(start.y, end.y) < 80.0 || 110.0 < min(start.y, end.y) || ay < cutoff) {
        // no clouds
        return 0.0;
    }
    float sum = 0.0;
    vec3 ray = start + (max(0.0, 80.0 - start.y) - max(0.0, start.y - 110.0)) * dir / dir.y;
    vec3 step = dir / ay;
    float wall = mix(max(80.0, end.y), min(110.0, end.y), step.y * 0.5 + 0.5);
    float dest = min(ray.y * step.y + 24.0, wall * step.y) * step.y;    // since step.y = +/-1.0
    float dy = abs(dest - ray.y);   // number of steps to dest
    for (int i = 0; i < dy; i++) {
        ray += step;
        sum += getCloudNoise(ray) * 0.04;
    }
    return sum * min(1.0, (ay - cutoff) * 5);
}

/* DRAWBUFFERS:012 */

void main() {
  vec3 finalComposite = texture2D(gcolor, texcoord.st).rgb;
  
  vec4 aux = texture2D(gaux1, texcoord.st);
  vec3 eye = invproj(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r));
  vec4 wpos = gbufferModelViewInverse * vec4(eye, 1.0);
  float no_hand = float(aux.g < 0.35 || 0.45 < aux.g);
#ifdef CLOUDS
  finalComposite += cloudRayMarching(cameraPosition, cameraPosition + wpos.xyz + vec3(0.0, 20.0, 0.0)) * ambient_color * (no_hand * 0.8 + 0.2);
#endif
  vec3 finalCompositeNormal = texture2D(gcolor, texcoord.st).rgb;
  vec3 finalCompositeDepth = texture2D(gcolor, texcoord.st).rgb;

  gl_FragData[0] = vec4(finalComposite, 1.0);
  gl_FragData[1] = vec4(finalCompositeNormal, 1.0);
  gl_FragData[2] = vec4(finalCompositeDepth, 1.0);

}
