//
// Created by basta on 8/30/23.
//

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "glfw-utils.h"
#include "image-utils.h"
#include <iostream>
#include <fstream>
#include <sstream>

#include <chrono>
using namespace std::chrono;

using namespace std;


void MessageCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message,
                     const void *userParam) {
    fprintf(stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
            (type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : ""),
            type, severity, message);
}

GLuint bind_texture_from_array2D3C(const unsigned char *arr, int width, int height, int binding) {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, arr);
    glBindImageTexture(binding, texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8);
    return texture;
}


GLuint bind_texture_from_array2D1C(const unsigned char *arr, int width, int height, int binding) {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    // TODO prozkoumat formáty, nejspíš je tu něco blbě
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, arr);

    glBindImageTexture(binding, texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_R8);
    return texture;
}

void expand_to_three_channels(const unsigned char * one_channel, unsigned char * out_three_channel, int one_length) {
    for (int i = 0; i < one_length; ++i) {
        out_three_channel[i*3] = one_channel[i];
    }
}

void printGLFWError() {
    const char *description;
    if (glfwGetError(&description) != GLFW_NO_ERROR) {
        std::cout << "GLFW Error: " << description << std::endl;
    }
    printf("GLError: 0x%x\n", glGetError());
}

void runTwoShadersOnImage(char *glslPath1, char *glslPath2, const char *imgPath, char *imgSavePath) {
    auto shader1 = ComputeShader::from_file(glslPath1);
    ComputeProgram computeProgram1 = ComputeProgram();
    computeProgram1.attachShader(shader1);

    auto shader2 = ComputeShader::from_file(glslPath2);
    ComputeProgram computeProgram2 = ComputeProgram();
    computeProgram2.attachShader(shader2);

    int width, height;
    auto inImg = load_png_from_filename(imgPath, &width, &height);

    auto debayerTextureData = new unsigned char [width*height*3];
    GLuint debayerTexture = bind_texture_from_array2D3C(debayerTextureData, width, height, 1);


    auto denoiseTextureData = new unsigned char [width*height*3];
    GLuint denoiseTexture = bind_texture_from_array2D3C(debayerTextureData, width, height, 2);

    auto C3in = new unsigned char[width*height*3];
    expand_to_three_channels(inImg, C3in, width*height);
    GLuint texture = bind_texture_from_array2D3C(C3in, width, height, 0);

    computeProgram1.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);


    GLuint query;
    GLint64 result;
    glGenQueries(1, &query);
    glBeginQuery(GL_TIME_ELAPSED, query);

    computeProgram2.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);




    auto outImg = new unsigned char[width * height * 4];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_2D, denoiseTexture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, outImg);

    glEndQuery(GL_TIME_ELAPSED);
    glGetQueryObjecti64v(query, GL_QUERY_RESULT, &result);

    std::cout << "Shader took: " << float(result)/1000000 << "ms\n";



    save_img(imgSavePath, outImg, width, height, 4);
    glDeleteShader(shader1->glID);
    glDeleteProgram(computeProgram1.glID);
    glDeleteShader(shader2->glID);
    glDeleteProgram(computeProgram2.glID);
    printf("INFO Saved shader result to %s\n", imgSavePath);

}

char * imgPathCache = "";
unsigned char * imgDataCache = nullptr;
int widthCache, heightCache;

void runShaderOnImage(char *glslPath, const char *imgPath, char *imgSavePath) {
    auto shader = ComputeShader::from_file(glslPath);
    ComputeProgram computeProgram = ComputeProgram();
    computeProgram.attachShader(shader);
    computeProgram.linkAndUse();
    unsigned char * inImg;
    int width, height;
    if (imgPath == imgPathCache){
        width = widthCache;
        height = heightCache;
        inImg = imgDataCache;
    } else {
        inImg = load_png_from_filename(imgPath, &width, &height);
        imgDataCache = inImg;
        widthCache = width;
        heightCache = height;
        imgPathCache = (char *)imgPath;
    }

    auto outTextureData = new unsigned char [width*height*3];
    GLuint outTexture = bind_texture_from_array2D3C(outTextureData, width, height, 1);

    auto C3in = new unsigned char[width*height*3];
    expand_to_three_channels(inImg, C3in, width*height);
    GLuint texture = bind_texture_from_array2D3C(C3in, width, height, 0);

    auto start = high_resolution_clock::now();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_ALL_BARRIER_BITS);
    auto end = high_resolution_clock::now();

    auto duration = duration_cast<nanoseconds>(end - start);

    cout << "Time taken by function: "
         << duration.count() << " microseconds" << endl;

    auto outImg = new unsigned char[width * height * 4];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_2D, outTexture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, outImg);
    save_img(imgSavePath, outImg, width, height, 4);
    glDeleteShader(shader->glID);
    glDeleteProgram(computeProgram.glID);
    printf("INFO Saved shader result to %s\n", imgSavePath);

}


void runShaderOnImageStdinUniform(char *glslPath, const char *imgPath, char *imgSavePath) {
    auto shader = ComputeShader::from_file(glslPath);
    ComputeProgram computeProgram = ComputeProgram();
    computeProgram.attachShader(shader);
    computeProgram.linkAndUse();

    int width, height;
    auto inImg = load_png_from_filename(imgPath, &width, &height);

    auto outTextureData = new unsigned char [width*height*3];
    GLuint outTexture = bind_texture_from_array2D3C(outTextureData, width, height, 1);

    auto C3in = new unsigned char[width*height*3];
    expand_to_three_channels(inImg, C3in, width*height);
    GLuint texture = bind_texture_from_array2D3C(C3in, width, height, 0);

    auto outImg = new unsigned char[width * height * 4];
    while (true) {

        float uniform;

        cin >> uniform;
        cout << "Setting " << uniform << endl;

        glUniform1f(3, uniform);
        glDispatchCompute(width, height, 1); // Number of work groups
        glMemoryBarrier(GL_ALL_BARRIER_BITS);


        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glBindTexture(GL_TEXTURE_2D, outTexture);
        glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, outImg);
        save_img(imgSavePath, outImg, width, height, 4);
        cout << "Updated\n";
    }
        glDeleteShader(shader->glID);
        glDeleteProgram(computeProgram.glID);
        printf("INFO Saved shader result to %s\n", imgSavePath);
}

void newDebayerOnImage(const char *imgPath, char *imgSavePath) {
    auto greenLShader = ComputeShader::from_file("/home/basta/Projects/vrgineers/glsl/new-debayer.glsl");
    auto greenLProgram = ComputeProgram();
    greenLProgram.attachShader(greenLShader);


    auto colorCShader = ComputeShader::from_file("/home/basta/Projects/vrgineers/glsl/colorCorrect.glsl");
    auto colorCProgram = ComputeProgram();
    colorCProgram.attachShader(colorCShader);

    auto colorLShader = ComputeShader::from_file("/home/basta/Projects/vrgineers/glsl/colorLuminance.glsl");
    auto colorLProgram = ComputeProgram();
    colorLProgram.attachShader(colorLShader);

    auto lToRGBShader = ComputeShader::from_file("/home/basta/Projects/vrgineers/glsl/ltoRGB.glsl");
    auto lToRGBProgram = ComputeProgram();
    lToRGBProgram.attachShader(lToRGBShader);


    int width, height;
    auto inImg = load_png_from_filename(imgPath, &width, &height);

    // Textures
    auto greenLTextureData = new unsigned char [width*height*3];
    auto allLTextureData = new unsigned char [width*height*3];
    auto colorCTextureData = new unsigned char [width*height*3];
    auto lToRGBTextureData = new unsigned char [width*height*3];

    GLuint greenLTexture = bind_texture_from_array2D3C(greenLTextureData, width, height, 1);
    GLuint allLTexture = bind_texture_from_array2D3C(allLTextureData, width, height, 2);
    GLuint colorCTexture = bind_texture_from_array2D3C(colorCTextureData, width, height, 0);
    GLuint lToRGBTexture = bind_texture_from_array2D3C(colorCTextureData, width, height, 3);

    auto C3in = new unsigned char[width*height*3];
    expand_to_three_channels(inImg, C3in, width*height);
    GLuint texture = bind_texture_from_array2D3C(C3in, width, height, 5);

    colorCProgram.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);


    greenLProgram.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);


    colorLProgram.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

    lToRGBProgram.linkAndUse();
    glDispatchCompute(width, height, 1); // Number of work groups
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);


    auto outImg = new unsigned char[width * height * 4];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_2D, lToRGBTexture);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, outImg);
    save_img(imgSavePath, outImg, width, height, 4);
}


ComputeShader::ComputeShader(const char *src) {
    glID = glCreateShader(GL_COMPUTE_SHADER);
    glShaderSource(glID, 1, &src, nullptr);
    glCompileShader(glID);

    int success;
    glGetShaderiv(glID, GL_COMPILE_STATUS, &success);

    char infoLog[512];
    if (!success) {
        glGetShaderInfoLog(glID, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::COMPUTE::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    code = src;
}

ComputeShader *ComputeShader::from_file(const char *fname) {
    std::ifstream t(fname);
    std::stringstream buffer;
    buffer << t.rdbuf();
    if (buffer.str().length() == 0) {
        printf("ERROR: Shader file %s is empty or non-existent", fname);
    }
    return new ComputeShader(buffer.str().c_str());
}

ComputeProgram::ComputeProgram() {
    glID = glCreateProgram();
}

void ComputeProgram::linkAndUse() {
    glLinkProgram(glID);
    glUseProgram(glID);
}

void ComputeProgram::attachShader(ComputeShader *shader) {
    glAttachShader(glID, shader->glID);
}

void ComputeProgram::use() {
    glUseProgram(glID);
}
