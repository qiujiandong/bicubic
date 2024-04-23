import numpy as np
import matplotlib.pyplot as plt

x = np.linspace(-15, 15, 31)
y = 4 * np.sin(x * np.pi / 4) / x / np.pi

x1 = np.linspace(-8, -4, 5)
x2 = np.linspace(-4, 0, 5)
x3 = np.linspace(0, 4, 5)
x4 = np.linspace(4, 8, 5)

y1 = -0.5 * abs(x1 / 4) ** 3 + 2.5 * abs(x1 / 4) ** 2 - 4 * abs(x1 / 4) + 2
y2 = 1.5 * abs(x2 / 4) ** 3 - 2.5 * abs(x2 / 4) ** 2 + 1
y3 = 1.5 * abs(x3 / 4) ** 3 - 2.5 * abs(x3 / 4) ** 2 + 1
y4 = -0.5 * abs(x4 / 4) ** 3 + 2.5 * abs(x4 / 4) ** 2 - 4 * abs(x4 / 4) + 2

y_cubic = np.concatenate([y1, y2, y3, y4])
x_cubic = np.concatenate([x1, x2, x3, x4])

y[15] = 1
plt.stem(x, y, label="Sa(n)")
plt.stem(x_cubic, y_cubic, linefmt="r-", markerfmt="ro", label="paper")
plt.legend()
plt.xlabel("x")
plt.ylabel("sa(n)")
plt.grid(True)
plt.show()
