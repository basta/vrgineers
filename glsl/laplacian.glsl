#version 460
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba8, binding = 1) uniform image2D colorIn;
layout(rgba8, binding = 2) uniform image2D sharpenedOut;

vec3 laplace4(ivec2 coord){
    return (
        - imageLoad(colorIn, coord + ivec2(1, 0))
        - imageLoad(colorIn, coord + ivec2(-1, 0))
        - imageLoad(colorIn, coord + ivec2(0, 1))
        - imageLoad(colorIn, coord + ivec2(0, -1))
        + 4.0 * imageLoad(colorIn, coord)).rgb;
}

vec3 mean(ivec2 coord, int filterSize){
    vec3 sum = vec3(0);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            sum += imageLoad(colorIn, coord + ivec2(dx, dy)).xyz;
        }
    }
    return sum/pow(filterSize, 2);
}

vec3 variance(ivec2 coord, int filterSize, vec3 mean){
    vec3 tau2 = vec3(0.);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            vec3 pixel = imageLoad(colorIn, coord + ivec2(dx, dy)).xyz;
            tau2 += pow(pixel - mean, vec3(2));
        }
    }
    return tau2/pow(filterSize, 2);
}

vec3 laplace8(ivec2 coord){
    return (
    - imageLoad(colorIn, coord + ivec2(1, 0))
    - imageLoad(colorIn, coord + ivec2(-1, 0))
    - imageLoad(colorIn, coord + ivec2(0, 1))
    - imageLoad(colorIn, coord + ivec2(0, -1))
    - imageLoad(colorIn, coord + ivec2(-1, -1))
    - imageLoad(colorIn, coord + ivec2(1, -1))
    - imageLoad(colorIn, coord + ivec2(1, 1))
    - imageLoad(colorIn, coord + ivec2(-1, 1))
    + 8.0 * imageLoad(colorIn, coord)).rgb;
}

vec3 laplaceD(ivec2 coord){
    return (
    - imageLoad(colorIn, coord + ivec2(-1, -1))
    - imageLoad(colorIn, coord + ivec2(1, -1))
    - imageLoad(colorIn, coord + ivec2(1, 1))
    - imageLoad(colorIn, coord + ivec2(-1, 1))
    + 4.0 * imageLoad(colorIn, coord)).rgb;
}


void main() {
const vec3 noiseVariance = vec3(0.00003); //tohle je blbost, protože už to kouká na denoised data
//    const vec3 noiseVariance = vec3(0.004);
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec3 color = imageLoad(colorIn, coord).rgb;
    vec3 laplace = clamp(vec3(-1.), 0.5*laplaceD(coord), vec3(0.));
//    vec3 laplace = clamp(vec3(-1.), 1*laplaceD(coord), vec3(0.));
    vec3 sharpened = color + laplace;
    vec3 avg = mean(coord, 7);

    vec3 areaVariance = variance(coord, 7, avg);

    vec3 tauRatio = clamp(vec3(0.), vec3(1.), noiseVariance/areaVariance);

    imageStore(sharpenedOut, coord, vec4(sharpened - tauRatio*(sharpened - color), 1.0));
}
