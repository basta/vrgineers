#version 460

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D imgOutput;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(2.08, 0., 0.), vec3(0., 1., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.48) };

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


void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    value.x = float(texelCoord.x)/(gl_NumWorkGroups.x);
    value.y = float(texelCoord.y)/(gl_NumWorkGroups.y);

    vec3 finalColor = vec3(0.);
    uint channel = getChannelID(texelCoord);

    finalColor += imageLoad(monoInput, texelCoord).x * CHANNEL_COLORS[getChannelID(texelCoord)];

    if (channel == RED) {
        finalColor += CHANNEL_COLORS[BLUE] * rb_bilinear(texelCoord);
        finalColor += CHANNEL_COLORS[GREEN1] * g_bilinear(texelCoord);
    } else if (channel == BLUE) {
        finalColor += CHANNEL_COLORS[RED] * rb_bilinear(texelCoord);
        finalColor += CHANNEL_COLORS[GREEN1] * g_bilinear(texelCoord);
    } else if (channel == GREEN2) {
        finalColor += v_bilinear(texelCoord) * CHANNEL_COLORS[BLUE];
        finalColor += h_bilinear(texelCoord) * CHANNEL_COLORS[RED];
    } else if (channel == GREEN1) {
        finalColor += v_bilinear(texelCoord) * CHANNEL_COLORS[RED];
        finalColor += h_bilinear(texelCoord) * CHANNEL_COLORS[BLUE];
    }


    imageStore(imgOutput, texelCoord,
    vec4(finalColor, 1.)
    );

}
