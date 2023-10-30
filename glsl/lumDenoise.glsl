#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 2) uniform image2D allLuminance;
layout(rgba8, binding = 6) uniform image2D denoisedLum;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(2.08, 0., 0.), vec3(0., 1., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.48) };

vec3 mean(ivec2 coord, int filterSize){
    vec3 sum = vec3(0);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            sum += imageLoad(allLuminance, coord + ivec2(dx, dy)).xyz;
        }
    }
    return sum/pow(filterSize, 2);
}

// Tau^2
vec3 variance(ivec2 coord, int filterSize, vec3 mean){
    vec3 tau2 = vec3(0.);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            vec3 pixel = imageLoad(allLuminance, coord + ivec2(dx, dy)).xyz;
            tau2 += pow(pixel - mean, vec3(2));
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
    vec3 noiseVariance = vec3(0.0004);//TODO REMOVE
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec3 lum = vec3(imageLoad(allLuminance, texelCoord).x);

    vec3 finalColor = vec3(0);
    uint channel = getChannelID(texelCoord);

    int filterSize = 7;
    vec3 avg = mean(texelCoord, filterSize);
    vec3 areaVariance = variance(texelCoord, filterSize, avg);
    float areaVarianceVal = max(areaVariance.x, max(areaVariance.y, areaVariance.z));

    vec3 tauRatio = clamp(vec3(0.), vec3(1.), noiseVariance/areaVariance);

    imageStore(denoisedLum, texelCoord,
    vec4(
        lum - tauRatio*(lum - avg), 1.
    )
    );

}
