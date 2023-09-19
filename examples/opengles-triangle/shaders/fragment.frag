#version 300 es


precision mediump float;

in vec4 vertexColor;

out vec4 fragColor;


void main() {
    fragColor = vertexColor;
}
