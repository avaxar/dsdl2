#version 300 es


precision highp float;

in vec4 vertexColor;

out vec4 fragColor;


void main() {
    fragColor = vertexColor;
}
