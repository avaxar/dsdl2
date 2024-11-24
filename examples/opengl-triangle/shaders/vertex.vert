#version 300 es


precision highp float;

layout (location = 0) in vec3 vertex;
layout (location = 1) in vec4 color;

out vec4 vertexColor;


void main() {
    gl_Position = vec4(vertex, 1);
    vertexColor = color;
}
