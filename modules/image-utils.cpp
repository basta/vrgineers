//
// Created by basta on 8/29/23.
//

#include <string>
#include "image-utils.h"
#include "cstdlib"
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
using namespace std;

#include "../lib/stb_image.h"
#include "../lib/stb_image_write.h"

unsigned char *load_png_from_filename(const std::string filename, int * width, int * height) {
    int comp;
    unsigned char * data = stbi_load(filename.c_str(), width, height, &comp, 0);
    return data;
}

int save_img(const char * filename, unsigned char *data, int width, int height, int channels=3) {
    return stbi_write_png(filename, width, height, channels, data, channels*width);
}
