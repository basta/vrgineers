#version 460


layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 5) uniform image2D noncorrectedInput;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

//const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(2.08), vec3(1.), vec3(1.), vec3(1.48) };
//const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(1.), vec3(1.), vec3(1.), vec3(1.) };
const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(1.84), vec3(1.), vec3(1.), vec3(1.65) };

uint getChannelID(ivec2 coord) {
    int x = coord.x;
    int y = coord.y;
    return
    y%2 * x%2 * BLUE// odd row odd col 1,1
    + y%2 * (1-x%2) * GREEN1// odd row, even col 1, 0
    + (1-y%2) * (1-x%2) * RED// even row, even col, 0,0
    + (1-y%2) * x%2 * GREEN2;// 0, 1
}

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    uint channel = getChannelID(texelCoord);

    vec3 finalColor = imageLoad(noncorrectedInput, texelCoord).x * CHANNEL_COLORS[getChannelID(texelCoord)];

//    vec3 finalColor = vec3(imageLoad(noncorrectedInput, texelCoord).x);

    imageStore(monoInput, texelCoord,
        vec4(finalColor, 1.)
    );
}

