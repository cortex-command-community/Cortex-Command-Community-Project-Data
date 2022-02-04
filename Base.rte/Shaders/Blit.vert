#version 330 core

in vec2 textureUV;

out FragColor;

uniform sampler2D rteTexture;


void main() {
  FragColor = texture(rteTexture, vec4(textureUV, 0.0, 1.0));
}
