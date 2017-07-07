#version 120

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
varying vec3 lightVector;

uniform float rainStrength;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;


//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {
gl_Position = ftransform();

texcoord = gl_MultiTexCoord0;

}
