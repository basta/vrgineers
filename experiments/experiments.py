import matplotlib.pyplot as plt
import numpy as np
import imglib
img = plt.imread("/home/basta/Projects/vrgineers/RAW/display-text-dark_left_small.png")
# plt.plot(img[0, ::2])
freq = np.fft.fft(img[0, ::2])
img3c = imglib.mono_to_3c(img)
imglib.interpolate_greens(img3c)
imglib.apply_color_correction(img3c)
plt.imshow(img3c)
plt.show()
