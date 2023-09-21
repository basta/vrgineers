#version 460

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D imgOutput;

// Type definitions
const uint RED = 1u;
const uint GREEN = 2u;
const uint BLUE = 3u;

const vec3[] CHANNEL_COLORS = {vec3(0.,0.,0.), vec3(1.,0.,0.), vec3(0.,1.,0.), vec3(0.,0.,1.)};

uint getChannel(ivec2 coord) {
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
    uint channel = getChannel(texelCoord);

    finalColor += imageLoad(monoInput, texelCoord).x * CHANNEL_COLORS[getChannel(texelCoord)];

    imageStore(imgOutput, texelCoord,
    vec4(finalColor, 1.)
    );

}
