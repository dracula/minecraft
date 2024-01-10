#version 150
#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
	if (vertexDistance > 800.0
        && color.r > 0.2479 && color.r < 0.2481
        && color.g > 0.2479 && color.g < 0.2481
        && color.b > 0.2479 && color.b < 0.2481) {
        color = vec4(0.9412, 0.9412, 0.9412, 1.0);
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
