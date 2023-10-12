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
            float value = imageLoad(monoInput, coord + ivec2(x, y)).r;
            sum += lMatrix[x+2][y+2]*value;
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
    vec3 pixel = imageLoad(monoInput, texelCoord).xyz;

    float luminance = lFilter(texelCoord); // green only for now

    imageStore(imgOutput, texelCoord,
        vec4(vec3(luminance), 1.)
    );

}
