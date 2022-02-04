#version 330 core

in vec2 textureUV;

out vec4 FragColor;

uniform sampler1D rtePalette;
uniform sampler2D rteTexture;
uniform vec4 rteColor;

void main() {
  float index = texture(rteTexture, textureUV).x;
  FragColor = texture(rtePalette, index) * rteColor;
  // FragColor = rteColor;
}
