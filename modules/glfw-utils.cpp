//
// Created by basta on 8/30/23.
//

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "glfw-utils.h"
#include <iostream>

using namespace std;


void MessageCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message,
                     const void *userParam) {
    fprintf(stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
            (type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : ""),
            type, severity, message);
}


void printGLFWError() {
    const char *description;
    if (glfwGetError(&description) != GLFW_NO_ERROR) {
        std::cout << "GLFW Error: " << description << std::endl;
    }
    printf("GLError: 0x%x\n", glGetError());
}


ComputeShader::ComputeShader(const char * src) {
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