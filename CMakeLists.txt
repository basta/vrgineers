cmake_minimum_required(VERSION 3.6)
project(vrgineers)

set(CMAKE_CXX_STANDARD 17)

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

set(OpenGL_GL_PREFERENCE GLVND)

find_package(glfw3 3.3 REQUIRED)
find_package(OpenGL REQUIRED)

add_subdirectory(glad/)

add_executable(vrgineers main.cpp glad/src/glad.c
        modules/image-utils.cpp
        modules/image-utils.h
        lib/CImg/CImg.h
        lib/stb_image.h
        lib/stb_image_write.h
        modules/glfw-utils.cpp
        modules/glfw-utils.h
)

target_link_libraries(vrgineers glad)
target_link_libraries(vrgineers glfw)
target_link_libraries(vrgineers OpenGL::GL)

### CImg
include_directories(lib/CImg)
find_package(PNG REQUIRED)
include_directories(${PNG_INCLUDE_DIR})

target_link_libraries(vrgineers ${PNG_LIBRARY})
