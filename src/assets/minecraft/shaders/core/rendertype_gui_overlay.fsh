#version 150

in vec4 vertexColor;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
    vec4 color = vertexColor;
    if (color.a == 0.0) {
        discard;
    }
    if (color.r == 255/255.0 && color.g == 255/255.0 && color.b == 255/255.0 && color.a == 128/255.0) {
    color = vec4(0.74117, 0.57647, 0.97647, color.a);
    }
    fragColor = color * ColorModulator;
}
