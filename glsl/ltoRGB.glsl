#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D greenLuminance;
layout(rgba8, binding = 2) uniform image2D allLuminance;
layout(rgba8, binding = 3) uniform image2D colorOut;

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

float greenForRed(ivec2 coord){
    float sum = (
        imageLoad(monoInput, coord + ivec2(1, 0)).x
        + imageLoad(monoInput, coord + ivec2(-1, 0)).x
        + imageLoad(monoInput, coord + ivec2(0, -1)).x
        + imageLoad(monoInput, coord + ivec2(0, 1)).x
        - imageLoad(allLuminance, coord + ivec2(1, 0)).x
        - imageLoad(allLuminance, coord + ivec2(-1, 0)).x
        - imageLoad(allLuminance, coord + ivec2(0, 1)).x
        - imageLoad(allLuminance, coord + ivec2(0, -1)).x
    )/4;
//    return imageLoad(allLuminance, coord).x;
    return sum + imageLoad(allLuminance, coord).x;
}

float blueForRed(ivec2 coord){
    float sum = (
    imageLoad(monoInput, coord + ivec2(1, 1)).x
    + imageLoad(monoInput, coord + ivec2(-1, -1)).x
    + imageLoad(monoInput, coord + ivec2(1, -1)).x
    + imageLoad(monoInput, coord + ivec2(-1, 1)).x
    - imageLoad(allLuminance, coord + ivec2(1, 1)).x
    - imageLoad(allLuminance, coord + ivec2(-1, -1)).x
    - imageLoad(allLuminance, coord + ivec2(-1, 1)).x
    - imageLoad(allLuminance, coord + ivec2(1, -1)).x
    )/4;
    return sum + imageLoad(allLuminance, coord).x;
}

void main() {

    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    float lum = imageLoad(allLuminance, texelCoord).x;

    vec3 finalColor = vec3(0);
    uint channel = getChannelID(texelCoord);

    if (channel == RED) {
        finalColor.r = imageLoad(monoInput, texelCoord).x;
        finalColor.g = greenForRed(texelCoord);
        finalColor.b = blueForRed(texelCoord);
    } else if (channel == BLUE) {
        finalColor.r = blueForRed(texelCoord);
        finalColor.g = greenForRed(texelCoord);
        finalColor.b = imageLoad(monoInput, texelCoord).x;
    } else if (channel == GREEN1) {
        finalColor.r = (
            imageLoad(monoInput, texelCoord + ivec2(0, -1)).x
            + imageLoad(monoInput, texelCoord + ivec2(0, 1)).x
            - imageLoad(allLuminance, texelCoord + ivec2(0, -1)).x
            - imageLoad(allLuminance, texelCoord + ivec2(0, 1)).x
        )/2 + imageLoad(allLuminance, texelCoord).x;
        finalColor.g = imageLoad(monoInput, texelCoord).x;
        finalColor.b = (
            imageLoad(monoInput, texelCoord + ivec2(-1, 0)).x
            + imageLoad(monoInput, texelCoord + ivec2(1, 0)).x
            - imageLoad(allLuminance, texelCoord + ivec2(-1, 0)).x
            - imageLoad(allLuminance, texelCoord + ivec2(1, 0)).x
        )/2 + imageLoad(allLuminance, texelCoord).x;
    } else if (channel == GREEN2) {
        finalColor.r = (
            imageLoad(monoInput, texelCoord + ivec2(-1, 0)).x
            + imageLoad(monoInput, texelCoord + ivec2(1, 0)).x
            - imageLoad(allLuminance, texelCoord + ivec2(-1, 0)).x
            - imageLoad(allLuminance, texelCoord + ivec2(1, 0)).x
        )/2 + imageLoad(allLuminance, texelCoord).x;
        finalColor.g = imageLoad(monoInput, texelCoord).x;
        finalColor.b = (
            imageLoad(monoInput, texelCoord + ivec2(0, -1)).x
            + imageLoad(monoInput, texelCoord + ivec2(0, 1)).x
            - imageLoad(allLuminance, texelCoord + ivec2(0, -1)).x
            - imageLoad(allLuminance, texelCoord + ivec2(0, 1)).x
        )/2 + imageLoad(allLuminance, texelCoord).x;
    }

//    imageStore(colorOut, texelCoord, vec4(vec3(imageLoad(greenLuminance, texelCoord)), 1.));
    imageStore(colorOut, texelCoord, vec4(finalColor, 1.));
}
