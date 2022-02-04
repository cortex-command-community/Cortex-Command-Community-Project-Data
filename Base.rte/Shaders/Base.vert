#version 330 core

in vec2 rteVertexPosition;
in vec2 rteTexUV;
in vec4 rteVertexColor;

out vec4 vertexColor;
out vec2 textureUV;

uniform mat4 rteTransform;
uniform mat4 rteProjection;

void main() {
  gl_Position = rteProjection * rteTransform * vec4(rteVertexPosition, 0.0, 1.0);
  vertexColor = rteVertexColor;
  textureUV = rteTexUV;
}
