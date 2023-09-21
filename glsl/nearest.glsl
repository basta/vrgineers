#version 460

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D imgOutput;

// Type definitions
const uint RED = 1u;
const uint GREEN = 2u;
const uint BLUE = 3u;

const vec3[] CHANNEL_COLORS = {vec3(0.,0.,0.), vec3(2.08,0.,0.), vec3(0.,1.,0.), vec3(0.,0.,1.48)};

uint getChannelID(ivec2 coord) {
    int x = coord.x;
    int y = coord.y;
    return
    y%2 * x%2 * BLUE // odd row odd col 1,1
    + y%2 * (1-x%2) * GREEN // odd row, even col 1, 0
    + (1-y%2) * (1-x%2) * RED // even row, even col, 0,0
    + (1-y%2) * x%2 * GREEN; // 0, 1
}


void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    value.x = float(texelCoord.x)/(gl_NumWorkGroups.x);
    value.y = float(texelCoord.y)/(gl_NumWorkGroups.y);

    vec3 finalColor = vec3(0.);
    uint channel = getChannelID(texelCoord);

    finalColor += imageLoad(monoInput, texelCoord).x * CHANNEL_COLORS[getChannelID(texelCoord)];

    if (channel != GREEN) {
        finalColor += CHANNEL_COLORS[GREEN] * imageLoad(monoInput, texelCoord + ivec2(1, 0)).x;
    }

    if (channel == RED) {
        finalColor += CHANNEL_COLORS[BLUE] * imageLoad(monoInput, texelCoord + ivec2(1, 1)).x;
    }

    if (channel == BLUE) {
        finalColor += CHANNEL_COLORS[RED] * imageLoad(monoInput, texelCoord + ivec2(1, 1)).x;
    }

    if (channel == GREEN) {
        finalColor += CHANNEL_COLORS[getChannelID(texelCoord + ivec2(1, 0))] * imageLoad(monoInput, texelCoord + ivec2(1, 0)).x;
        finalColor += CHANNEL_COLORS[getChannelID(texelCoord + ivec2(0, 1))] * imageLoad(monoInput, texelCoord + ivec2(0, 1)).x;
    }

    imageStore(imgOutput, texelCoord,
    vec4(finalColor, 1.)
    );

}
