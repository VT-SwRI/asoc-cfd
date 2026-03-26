# mock_data.py
# -*- coding: utf-8 -*-

import numpy as np


def generate_spiral_hits(
    center_x=0,
    center_y=0,
    max_radius=40,
    n_points=4000,
    det_min=-50,
    det_max=50,
):
    """Generate a spiral of (x, y) hit coordinates in detector space."""
    t = np.linspace(0, 8 * np.pi, n_points)
    r = np.linspace(0, max_radius, n_points)
    x = center_x + r * np.cos(t)
    y = center_y + r * np.sin(t)

    mask = (x >= det_min) & (x <= det_max) & (y >= det_min) & (y <= det_max)
    return x[mask], y[mask]


def generate_phd_samples(
    mean=128,
    sigma=30,
    n_samples=10_000,
    clamp_min=0,
    clamp_max=256,
):
    """
    Generate example PHD samples in the 0–256 range.

    Default: Gaussian around 128 with std 30, clipped to [0, 256].
    """
    samples = np.random.normal(mean, sigma, size=n_samples)
    samples = np.clip(samples, clamp_min, clamp_max)
    return samples

