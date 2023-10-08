#include <iostream>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "modules/image-utils.h"
#include "modules/glfw-utils.h"

using namespace std;

// pantome 5600k

void error_callback(int error, const char *description) {
    fprintf(stderr, "Error: %s\n", description);
}

void runAllShadersOn(const char *fname) {
    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/nearest.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/nearest.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/coloring.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/coloring.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/bilinear.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/bilinear.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/green-only.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/green-only.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/green-only-no-extreme.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/green-only-no-extreme.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/bilinear-no-extreme.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/bilinear-no-extreme.png"
    );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/bilinear-no-extreme-iterative.glsl",
            fname,
            "/home/basta/Projects/vrgineers/out/bilinear-no-extreme-iterative.png"
    );

}


int main(int argc, char **argv) {

    std::string filename = argv[1];

    if (!glfwInit()) {
        std::cout << "Initialization failed \n";
        return 1;
    }


    glfwSetErrorCallback(error_callback);

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    GLFWwindow *window = glfwCreateWindow(800, 800, "Compute Shader Example", nullptr, nullptr);
    glfwMakeContextCurrent(window);

    gladLoadGLLoader((GLADloadproc) glfwGetProcAddress);

    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(MessageCallback, 0);

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/bilinear.glsl",
            filename.c_str(),
            "/home/basta/Projects/vrgineers/out/bilinear.png"
    );
    runTwoShadersOnImage(
            "/home/basta/Projects/vrgineers/glsl/bilinear-no-extreme.glsl",
            "/home/basta/Projects/vrgineers/glsl/iterative-debayer.glsl",
            filename.c_str(),
            "/home/basta/Projects/vrgineers/out/iterative-debayer.png"
    );
//
//    runTwoShadersOnImage(
//            "/home/basta/Projects/vrgineers/glsl/bilinear-no-extreme.glsl",
//            "/home/basta/Projects/vrgineers/glsl/denoise.glsl",
//            filename.c_str(),
//            "/home/basta/Projects/vrgineers/out/denoise.png"
//            );

//    runTwoShadersOnImage(
//            "/home/basta/Projects/vrgineers/glsl/bilinear-no-extreme.glsl",
//            "/home/basta/Projects/vrgineers/glsl/denoiseValue.glsl",
//            filename.c_str(),
//            "/home/basta/Projects/vrgineers/out/denoiseValue.png"
//    );

    glfwTerminate();
    return 0;
}
