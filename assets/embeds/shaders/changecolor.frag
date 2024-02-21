#pragma header

uniform bool change;
const vec3 yellow = vec3(0.9882352941176471, 0.9882352941176471, 0.0);
const vec3 red = vec3(1.0, 0.0, 0.0);

void main() {
    vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);

    if (change) {
        if (tex.rgb == yellow) {
            tex.rgb = red;
        }
    }

    gl_FragColor = tex;
}