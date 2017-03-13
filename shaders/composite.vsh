#version 120

varying vec4 texcoord;
varying vec3 ambient_color;

varying float gp00;
varying float gp11;
varying float gp22;
varying float gp32;
varying vec2 igp;

uniform int worldTime;

uniform float rainStrength;

uniform mat4 gbufferProjection;

void main() {
gl_Position = ftransform();

float wtime = float(worldTime);
float hour = wtime / 1000.0 + 6.0;
hour += -24.0 * float(24.0 < hour);

float rain_color = 0.4 - cos(hour / 12.0 * 3.141597) * 0.3;

    ////////////////////ambient color////////////////////
    const ivec4 ToD2[25] = ivec4[25](ivec4(0,50,80,140), //hour,r,g,b
                                     ivec4(1,50,80,140),
                                     ivec4(2,50,80,140),
                                     ivec4(3,60,90,150),
                                     ivec4(4,60,90,150),
                                     ivec4(5,75,106,155),
                                     ivec4(6,160,170,255),
                                     ivec4(7,160,175,255),
                                     ivec4(8,160,180,260),
                                     ivec4(9,165,190,270),
                                     ivec4(10,190,205,280),
                                     ivec4(11,205,230,290),
                                     ivec4(12,220,255,300),
                                     ivec4(13,205,230,290),
                                     ivec4(14,190,205,280),
                                     ivec4(15,165,190,270),
                                     ivec4(16,150,176,260),
                                     ivec4(17,140,160,255),
                                     ivec4(18,128,150,255),
                                     ivec4(19,77,67,194),
                                     ivec4(20,60,90,150),
                                     ivec4(21,60,90,150),
                                     ivec4(22,50,80,140),
                                     ivec4(23,50,80,140),
                                     ivec4(24,50,80,140));
    ivec4 tempa = ToD2[int(floor(hour))];
    ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
    
    ambient_color = mix(vec3(tempa.yzw), vec3(tempa2.yzw), (hour - float(tempa.x)) / float(tempa2.x - tempa.x)) / 255.0;
    ambient_color = mix(ambient_color, vec3(rain_color), rainStrength * 0.5);

	gp00 = gbufferProjection[0][0] * -0.5;
    gp11 = gbufferProjection[1][1] * -0.5;
	gp22 = gbufferProjection[2][2] * 0.5;
	gp32 = gbufferProjection[3][2] * 0.5;
	igp = vec2(-1.0) / vec2(gp00, gp11);
	
texcoord = gl_MultiTexCoord0;

}
