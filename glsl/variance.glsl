#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 2) uniform image2D lumInput;
layout(rgba8, binding = 7) uniform image2D varOut;

// Type definitions
const uint RED = 1u;
const uint GREEN = 2u;
const uint BLUE = 3u;

const float GAIN = 5;

const vec3[] CHANNEL_COLORS = { vec3(0., 0., 0.), vec3(1., 0., 0.), vec3(0., 1., 0.), vec3(0., 0., 1.) };

vec3 mean(ivec2 coord, int filterSize){
    vec3 sum = vec3(0);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            sum += imageLoad(lumInput, coord + ivec2(dx, dy)).xyz;
        }
    }
    return sum/pow(filterSize, 2);
}

// Tau^2
vec3 variance(ivec2 coord, int filterSize, vec3 mean){
    vec3 tau2 = vec3(0.);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            vec3 pixel = imageLoad(lumInput, coord + ivec2(dx, dy)).xyz;
            tau2 += pow(pixel - mean, vec3(2));
        }
    }
    return tau2/pow(filterSize, 2);
}

void main() {
    const vec3 noiseVariance = vec3(0.0004);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    vec3 finalColor = vec3(0.);
    int filterSize = 7;
    vec3 avg = mean(texelCoord, filterSize);
    vec3 areaVariance = variance(texelCoord, filterSize, avg);

    vec3 tauRatio = clamp(vec3(0.), vec3(1.), noiseVariance/areaVariance);

    imageStore(varOut, texelCoord,
    vec4(
        tauRatio, 1.
    )
    );


}
