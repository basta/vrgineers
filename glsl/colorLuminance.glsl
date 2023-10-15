#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D greenLuminance;
layout(rgba8, binding = 2) uniform image2D allLuminance;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(2.08, 0., 0.), vec3(0., 1., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.48) };

//          x  y
int lMatrix[5][5] = {
{0, 1, -2, 1, 0},
{1, -4, 6, -4, 1},
{-2, 6, 56, 6, -2},
{1, -4, 6, -4, 1},
{0, 1, -2, 1, 0},
};

uint getChannelID(ivec2 coord) {
    int x = coord.x;
    int y = coord.y;
    return
    y%2 * x%2 * BLUE// odd row odd col 1,1
    + y%2 * (1-x%2) * GREEN1// odd row, even col 1, 0
    + (1-y%2) * (1-x%2) * RED// even row, even col, 0,0
    + (1-y%2) * x%2 * GREEN2;// 0, 1
}

float rb_bilinear(ivec2 coord){
    // # - #
    // - - -
    // # - #
    return (
    imageLoad(monoInput, coord + ivec2(-1, -1)).x
    + imageLoad(monoInput, coord + ivec2(1, 1)).x
    + imageLoad(monoInput, coord + ivec2(1, -1)).x
    + imageLoad(monoInput, coord + ivec2(-1, 1)).x
    )/4.;
}

float g_bilinear(ivec2 coord) {
    // - # -
    // # - #
    // - # -
    return (
    imageLoad(monoInput, coord + ivec2(-1, 0)).x
    + imageLoad(monoInput, coord + ivec2(1, 0)).x
    + imageLoad(monoInput, coord + ivec2(0, -1)).x
    + imageLoad(monoInput, coord + ivec2(0, 1)).x
    )/4;
}

float h_bilinear(ivec2 coord) {
    return (
    imageLoad(monoInput, coord + ivec2(-1, 0)).x
    + imageLoad(monoInput, coord + ivec2(1, 0)).x
    )/2.;
}

float v_bilinear(ivec2 coord) {
    return (
    imageLoad(monoInput, coord + ivec2(0, 1)).x
    + imageLoad(monoInput, coord + ivec2(0, -1)).x
    )/2.;
}

float lFilter(ivec2 coord){
    float sum = 0;
    for (int x = -2; x <= 2; x++){
        for (int y = -2; y <= 2; y++){
            vec3 pixel = imageLoad(monoInput, coord + ivec2(x, y)).rgb;
            float value = pixel.r + pixel.g + pixel.b;
            sum += lMatrix[x][y]*value;
        }
    }
    return sum/64;
}

void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    value.x = float(texelCoord.x)/(gl_NumWorkGroups.x);
    value.y = float(texelCoord.y)/(gl_NumWorkGroups.y);

    vec3 finalColor = vec3(0.);
    uint channel = getChannelID(texelCoord);
    vec3 gLPixel = imageLoad(greenLuminance, texelCoord).xyz;
    vec3 inPixel = imageLoad(monoInput, texelCoord).xyz;

    float w1i = 1
        + abs(inPixel.r - imageLoad(monoInput, texelCoord + ivec2(0, 2)).x)
        + abs(
            imageLoad(greenLuminance, texelCoord + ivec2(0, 1))
            - imageLoad(greenLuminance, texelCoord + ivec2(0, -1))).x;
    float w2i = 1
        + abs(inPixel.r - imageLoad(monoInput, texelCoord + ivec2(-2, 0)).x)
        + abs(
        imageLoad(greenLuminance, texelCoord + ivec2(1, 0))
        - imageLoad(greenLuminance, texelCoord + ivec2(-1, 0))).x;
    float w3i = 1
        + abs(inPixel.r - imageLoad(monoInput, texelCoord + ivec2(0, -2)).x)
        + abs(
        imageLoad(greenLuminance, texelCoord + ivec2(0, 1))
        - imageLoad(greenLuminance, texelCoord + ivec2(0, -1))).x;
    float w4i = 1
        + abs(inPixel.r - imageLoad(monoInput, texelCoord + ivec2(2, 0)).x)
        + abs(
        imageLoad(greenLuminance, texelCoord + ivec2(1, 0))
        - imageLoad(greenLuminance, texelCoord + ivec2(-1, 0))).x;

    float w1 = 1/w1i;
    float w2 = 1/w2i;
    float w3 = 1/w3i;
    float w4 = 1/w4i;

    float colorLum =
        + imageLoad(greenLuminance, texelCoord + ivec2(0, +1)).x * w1
        + imageLoad(greenLuminance, texelCoord + ivec2(1, 0)).x * w2
        + imageLoad(greenLuminance, texelCoord + ivec2(0, -1)).x * w3
        + imageLoad(greenLuminance, texelCoord + ivec2(-1, 0)).x * w4;

    float colorLumBil =
        + imageLoad(greenLuminance, texelCoord + ivec2(0, +1)).x
        + imageLoad(greenLuminance, texelCoord + ivec2(1, 0)).x
        + imageLoad(greenLuminance, texelCoord + ivec2(0, -1)).x
        + imageLoad(greenLuminance, texelCoord + ivec2(-1, 0)).x;

    colorLumBil /= 4;
    colorLum /= w1 + w2 + w3 + w4;

    if (channel == GREEN2 || channel == GREEN1){
        imageStore(allLuminance, texelCoord,
            imageLoad(greenLuminance, texelCoord)
        );
    } else {
        imageStore(allLuminance, texelCoord,
//            vec4(vec3(w1), 1.)
            vec4(vec3(colorLum), 1.)
        );
    }

}
