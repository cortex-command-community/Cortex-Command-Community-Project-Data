#version 330 core

in vec2 textureUV;

out vec4 FragColor;

uniform sampler1D rtePalette;
uniform sampler2D rteTexture;
uniform vec4 rteColor;


void main() {
     FragColor = vec4(rteColor.rgb, rteColor.a * texture(rtePalette, texture(rteTexture, textureUV).r).a);
}