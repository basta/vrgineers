#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 3) uniform image2D colorIn;
layout(rgba8, binding = 6) uniform image2D lumIn;
//layout(rgba8, binding = 5) uniform image2D chromaDenoiseOut;
layout(rgba8, binding = 1) uniform image2D chromaDenoiseOut;
layout(rgba8, binding = 7) uniform image2D inTauR;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(2.08, 0., 0.), vec3(0., 1., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.48) };

vec3 meanCD(ivec2 coord, int filterSize){
    vec3 sum = vec3(0);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            sum += imageLoad(colorIn, coord + ivec2(dx, dy)).xyz
            - imageLoad(lumIn, coord + ivec2(dx, dy)).xyz;
        }
    }
    return sum/pow(filterSize, 2);
}

vec3 variance(ivec2 coord, int filterSize, vec3 mean){
    vec3 tau2 = vec3(0.);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            vec3 pixel = imageLoad(colorIn, coord + ivec2(dx, dy)).xyz;
            vec3 lum = imageLoad(lumIn, coord + ivec2(dx, dy)).xyz;
            tau2 += pow(pixel - vec3(lum) - mean, vec3(2));
        }
    }
    return tau2/pow(filterSize, 2);
}

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
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    vec3 avgCD = meanCD(texelCoord, 7);
    vec3 tauRatio = imageLoad(inTauR, texelCoord).xyz;


    uint channel = getChannelID(texelCoord);
    vec3 avgOut = avgCD + imageLoad(lumIn, texelCoord).xyz;
    vec3 sharpOut = imageLoad(colorIn, texelCoord).xyz;
    vec3 finalColor = sharpOut - tauRatio*(sharpOut - avgOut);
    imageStore(chromaDenoiseOut, texelCoord, vec4(finalColor, 1.));
}
