//
// Created by basta on 8/30/23.
//

#ifndef VRGINEERS_GLFW_UTILS_H
#define VRGINEERS_GLFW_UTILS_H

void printGLFWError();

class ComputeShader{
public:
    const char * code;
    GLuint glID;

    explicit ComputeShader(const char * code);
    static ComputeShader * from_file(const char * fname);
};

class ComputeProgram {
public:
    GLuint glID;
    ComputeProgram();
    void linkAndUse();
    void attachShader(ComputeShader shader);

    void attachShader(ComputeShader *shader);
};

GLuint bind_texture_from_array2D1C(const unsigned char *arr, int width, int height, int binding);

GLuint bind_texture_from_array2D3C(const unsigned char *arr, int width, int height, int binding);

void runShaderOnImage(char * glslPath, char * imgPath, char * imgSavePath);



void GLAPIENTRY MessageCallback(GLenum source,
                GLenum type,
                GLuint id,
                GLenum severity,
                GLsizei length,
                const GLchar *message,
                const void *userParam);

#endif //VRGINEERS_GLFW_UTILS_H
