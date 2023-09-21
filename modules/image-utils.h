//
// Created by basta on 8/29/23.
//

#ifndef VRGINEERS_IMAGE_UTILS_H
#define VRGINEERS_IMAGE_UTILS_H

#include <string>
unsigned char * load_png_from_filename(std::string filename, int * width, int * height);
int save_img(const char * filename, unsigned char *data, int width, int height, int channels);
#endif //VRGINEERS_IMAGE_UTILS_H