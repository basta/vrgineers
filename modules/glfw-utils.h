//
// Created by basta on 8/30/23.
//

#ifndef VRGINEERS_GLFW_UTILS_H
#define VRGINEERS_GLFW_UTILS_H

void printGLFWError();
void GLAPIENTRY MessageCallback(GLenum source,
                GLenum type,
                GLuint id,
                GLenum severity,
                GLsizei length,
                const GLchar *message,
                const void *userParam);

#endif //VRGINEERS_GLFW_UTILS_H
