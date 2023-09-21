#include <iostream>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include "modules/image-utils.h"
#include "modules/glfw-utils.h"

using namespace std;

void error_callback(int error, const char *description) {
    fprintf(stderr, "Error: %s\n", description);
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

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/nearest.glsl",
            argv[1],
            "/home/basta/Projects/vrgineers/out/nearest.png"
            );

    runShaderOnImage(
            "/home/basta/Projects/vrgineers/glsl/coloring.glsl",
            argv[1],
            "/home/basta/Projects/vrgineers/out/coloring.png"
    );


    glfwTerminate();
    save_img("/tmp/out2.png", denoised, width, height,3);
    return 0;
}
