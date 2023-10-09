#version 460

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D monoInput;
layout(rgba8, binding = 1) uniform image2D debayered;
layout(rgba8, binding = 2) uniform image2D denoised;

// Type definitions
const uint RED = 1u;
const uint GREEN1 = 2u;
const uint GREEN2 = 3u;
const uint BLUE = 4u;

uint getChannelID(ivec2 coord) {
    int x = coord.x;
    int y = coord.y;
    return
    y%2 * x%2 * BLUE// odd row odd col 1,1
    + y%2 * (1-x%2) * GREEN1// odd row, even col 1, 0
    + (1-y%2) * (1-x%2) * RED// even row, even col, 0,0
    + (1-y%2) * x%2 * GREEN2;// 0, 1
}


vec3 mean(ivec2 coord, int filterSize){
    vec3 sum = vec3(0);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            sum += imageLoad(debayered, coord + ivec2(dx, dy)).xyz;
        }
    }
    return sum/pow(filterSize, 2);
}

// Tau^2
vec3 variance(ivec2 coord, int filterSize, vec3 mean){
    vec3 tau2 = vec3(0.);
    for (int dx = -filterSize/2; dx <= filterSize/2; dx++){
        for (int dy = -filterSize/2; dy <= filterSize/2; dy++){
            vec3 pixel = imageLoad(debayered, coord + ivec2(dx, dy)).xyz;
            tau2 += pow(pixel - mean, vec3(2));
        }
    }
    return tau2/pow(filterSize, 2);
}

float DR(ivec2 coord){
    vec3 pixel = imageLoad(debayered, coord).xyz;
    return pixel.r - pixel.g;
}

float DB(ivec2 coord){
    vec3 pixel = imageLoad(debayered, coord).xyz;
    return pixel.b - pixel.g;
}

float greenForRed(ivec2 coord, float red){
    return red - (
    DR(coord + ivec2(1, 0))
    + DR(coord + ivec2(-1, 0))
    + DR(coord + ivec2(0, 1))
    + DR(coord + ivec2(0, -1))
    )/4;
}

float greenForBlue(ivec2 coord, float blue){
    return blue - (
    DB(coord + ivec2(1, 0))
    + DB(coord + ivec2(-1, 0))
    + DB(coord + ivec2(0, 1))
    + DB(coord + ivec2(0, -1))
    )/4;
}

float redForBlue(ivec2 coord, float green){
    return green + (
        DR(coord + ivec2(1, 1))
        + DR(coord + ivec2(-1, 1))
        + DR(coord + ivec2(1, -1))
        + DR(coord + ivec2(-1, -1))
    )/4;
}

float blueForRed(ivec2 coord, float green) {
    return green + (
    DB(coord + ivec2(1, 1))
    + DB(coord + ivec2(-1, 1))
    + DB(coord + ivec2(1, -1))
    + DB(coord + ivec2(-1, -1))
    )/4;
}


void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec3 finalColor = vec3(0.);
    vec3 pixel = imageLoad(debayered, texelCoord).xyz;

    finalColor = pixel;
    uint channel = getChannelID(texelCoord);

    if (channel == RED) {
        finalColor.g = greenForRed(texelCoord, pixel.r);
        finalColor.b = blueForRed(texelCoord, pixel.g);
    } else if (channel == BLUE) {
        finalColor.g = greenForBlue(texelCoord, pixel.b);
        finalColor.r = redForBlue(texelCoord, pixel.g);
    }
    else if (channel == GREEN2) { //top right
        finalColor.r = pixel.g + (
        DR(texelCoord + ivec2(1, 0)) + DR(texelCoord + ivec2(-1, 0))
        )/2;
        finalColor.b = pixel.g + (
        DB(texelCoord + ivec2(0, 1)) + DB(texelCoord + ivec2(0, -1))
        )/2;
    }
    else if (channel == GREEN1) { // bottom left
        finalColor.r = pixel.g + (
        DR(texelCoord + ivec2(0, 1)) + DR(texelCoord + ivec2(0, -1))
        )/2;
        finalColor.b = pixel.g + (
        DB(texelCoord + ivec2(1, 0)) + DB(texelCoord + ivec2(-1, 0))
        )/2;
    }


    imageStore(denoised, texelCoord,
    vec4(
    finalColor, 1.
    )
    );


}
