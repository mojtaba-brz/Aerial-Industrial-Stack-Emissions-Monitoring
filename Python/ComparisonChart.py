import matplotlib.pyplot as plt
import numpy as np

# Set the style with larger fonts
plt.style.use('seaborn-v0_8-paper')
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman']
plt.rcParams['axes.labelsize'] = 13  # Increased from 12
plt.rcParams['legend.fontsize'] = 12  # Increased from 11

comp_data_dict = {
    "CEMS": {"Initial Cost (inverse)": 0.10, "Running Cost (inverse)": 1.00, "Frequency": 1.00, "Labor Load (inverse)": 1.00, "Accuracy": 1.00},
    "Manual Sampling": {"Initial Cost (inverse)": 1.00, "Running Cost (inverse)": 0.50, "Frequency": 0.20, "Labor Load (inverse)": 0.10, "Accuracy": 0.95},
    "Aerial Monitoring": {"Initial Cost (inverse)": 0.75, "Running Cost (inverse)": 0.75, "Frequency": 0.75, "Labor Load (inverse)": 0.80, "Accuracy": 0.95}
}

# Get metrics and setup angles
metrics = list(comp_data_dict[next(iter(comp_data_dict))].keys())
n_metrics = len(metrics)
theta = np.linspace(0, 2*np.pi, n_metrics, endpoint=False)
theta_closed = np.append(theta, theta[0])  # For closing the curves

# Create figure
fig = plt.figure(figsize=(8, 6))
ax = fig.add_subplot(111, polar=True)

# Plot each method with closed curves
colors = plt.cm.tab10(np.linspace(0, 1., len(comp_data_dict)))
for (key, values), color in zip(comp_data_dict.items(), colors):
    values = list(values.values())
    values_closed = np.append(values, values[0])
    ax.plot(theta_closed, values_closed, label=key, color=color, 
            linewidth=2, marker='o', markersize=8, zorder=2)  # zorder for lines
    ax.fill(theta_closed, values_closed, color=color, alpha=0.15, zorder=1)  # zorder for fills

# Configure axes with ticks in front
ax.set_xticks(theta)
ax.set_xticklabels(metrics, fontsize=20)
ax.set_theta_offset(np.pi / 8)
ax.set_yticklabels([])
ax.tick_params(pad=12)  # Increased padding

# Bring radial grid to back and theta ticks to front
ax.grid(True, linestyle='--', alpha=0.7, zorder=0)
ax.xaxis.set_zorder(10)
# Add radial grid lines with labels
ax.set_rgrids([0.2, 0.4, 0.6, 0.8, 1.0], angle=0, fontsize=11)

# Legend with adjusted position
legend = ax.legend(loc='upper right', bbox_to_anchor=(1.35, 1.1), 
                  frameon=True, framealpha=1, edgecolor='black')
legend.get_frame().set_linewidth(0.5)

# Title with increased weight
# plt.title('Comparison of Monitoring Techniques', pad=35, 
#           fontsize=15, fontweight='semibold')

plt.tight_layout()
plt.show()