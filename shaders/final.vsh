#version 120

varying vec4 texcoord;


//-----------------------------------------------------
//----------------------VOID MAIN----------------------
//-----------------------------------------------------

void main() {
gl_Position = ftransform();

texcoord = gl_MultiTexCoord0;

}
