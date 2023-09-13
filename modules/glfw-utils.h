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
};



void GLAPIENTRY MessageCallback(GLenum source,
                GLenum type,
                GLuint id,
                GLenum severity,
                GLsizei length,
                const GLchar *message,
                const void *userParam);

#endif //VRGINEERS_GLFW_UTILS_H
