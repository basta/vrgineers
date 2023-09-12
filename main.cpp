#include <iostream>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "modules/image-utils.h"
#include "modules/glfw-utils.h"

using namespace std;

void error_callback(int error, const char *description) {
    fprintf(stderr, "Error: %s\n", description);
}


const char *computeShaderCode = R"(
#version 460

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(rgba8, binding = 0) uniform image2D imgOutput;

void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    value.x = float(texelCoord.x)/(gl_NumWorkGroups.x);
    value.y = float(texelCoord.y)/(gl_NumWorkGroups.y);

    imageStore(imgOutput, texelCoord, vec4(0.,0.,1.,1.));
}
)";

GLuint bind_texture_from_array2D3C(const unsigned char *arr, int width, int height, int binding) {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, arr);

    glBindImageTexture(binding, texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8);
    return texture;
}

GLuint bind_texture_from_array2D1C(const unsigned char *arr, int width, int height, int binding) {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, arr);

    glBindImageTexture(binding, texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8);
    return texture;
}


int main(int argc, char **argv) {

    std::string filename = argv[1];
    int width, height;
    auto data = load_png_from_filename(filename, &width, &height);

    auto denoised = new unsigned char[width * height * 3];

    for (int i = 0; i < width * height; i++) {
        denoised[i * 3] = 0;
        denoised[i * 3 + 1] = 0;
        denoised[i * 3 + 2] = 0;

        if (i % 3 == 0) {
            denoised[i * 3] = data[i];
        } else if (i % 3 == 1) {
            denoised[i * 3 + 1] = data[i];
        } else if (i % 3 == 2) {
            denoised[i * 3 + 2] = data[i];
        }
    }

    save_img("/tmp/out.png", denoised, width, height, 3);

    if (!glfwInit()) {
        std::cout << "Initialization failed \n";
        return 1;
    }


    glfwSetErrorCallback(error_callback);

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    GLFWwindow *window = glfwCreateWindow(1, 1, "Compute Shader Example", nullptr, nullptr);
    glfwMakeContextCurrent(window);



    gladLoadGLLoader((GLADloadproc) glfwGetProcAddress);

    glEnable              ( GL_DEBUG_OUTPUT );
    glDebugMessageCallback( MessageCallback, 0 );


    GLuint computeShader = glCreateShader(GL_COMPUTE_SHADER);
    glShaderSource(computeShader, 1, &computeShaderCode, nullptr);
    glCompileShader(computeShader);

    int success;
    glGetShaderiv(computeShader, GL_COMPILE_STATUS, &success);

    char infoLog[512];
    if (!success) {
        glGetShaderInfoLog(computeShader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::COMPUTE::COMPILATION_FAILED\n" << infoLog << std::endl;

    };

    GLuint computeProgram = glCreateProgram();

    glAttachShader(computeProgram, computeShader);
    glLinkProgram(computeProgram);
    glUseProgram(computeProgram);

    GLuint texture = bind_texture_from_array2D1C(data, width, height, 0);

    glDispatchCompute(width, height, 1); // Number of work groups

    glMemoryBarrier(GL_ALL_BARRIER_BITS);


    auto outImg = new unsigned char[width * height * 4];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_2D, texture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, outImg);
    save_img("/tmp/shaderOut.png", outImg, width, height, 4);

    glDeleteShader(computeShader);
    glDeleteProgram(computeProgram);
    glfwTerminate();
    std::cout << "Hello, World!" << std::endl;
    save_img("/tmp/out2.png", denoised, width, height,3);
    return 0;
}
