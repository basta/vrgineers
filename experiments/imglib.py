import numpy as np
from enum import Enum

import tqdm.auto

COLOR_CORRECTION = np.array([2.08, 1., 1.48])


class CHANNEL(Enum):
    NULL = 0
    RED = 1
    GREEN = 2
    BLUE = 3

    @staticmethod
    def for_loc(x: int, y: int) -> "CHANNEL":
        xeven = x % 2 == 0
        yeven = y % 2 == 0
        if xeven and yeven:
            return CHANNEL.RED
        elif xeven and not yeven:
            return CHANNEL.GREEN
        elif not xeven and yeven:
            return CHANNEL.GREEN
        elif not xeven and not yeven:
            return CHANNEL.BLUE

    def to_color(self) -> np.array:
        return [
            np.array([0, 0, 0]),
            np.array([1, 0, 0]),
            np.array([0, 1, 0]),
            np.array([0, 0, 1]),
        ][self.value]


def mono_to_3c(img: np.array):
    out = np.copy(img)
    out = np.expand_dims(out, 2)
    out = np.pad(out, [[0, 0], [0, 0], [0, 2]])
    for x in tqdm.auto.tqdm(range(img.shape[0])):
        for y in range(img.shape[1]):
            out[x, y] = CHANNEL.for_loc(x, y).to_color() * img[x, y]
    return out


def apply_color_correction(img: np.array):
    for x in tqdm.auto.tqdm(range(1, img.shape[0] - 1)):
        for y in range(1, img.shape[1] - 1):
            for c in range(3):
                img[x, y, c] *= COLOR_CORRECTION[c]


def interpolate_greens(img: np.array) -> np.array:
    for x in tqdm.auto.tqdm(range(1, img.shape[0] - 1)):
        for y in range(1, img.shape[1] - 1):
            if CHANNEL.for_loc(x, y) != CHANNEL.GREEN:
                img[x, y, 1] = (
                                       img[x - 1, y, 1]
                                       + img[x, y - 1, 1]
                                       + img[x + 1, y, 1]
                                       + img[x, y + 1, 1]
                               ) / 4
