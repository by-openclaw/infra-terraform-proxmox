import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

fig, ax = plt.subplots(1, 1, figsize=(14, 18))
ax.set_xlim(0, 14)
ax.set_ylim(0, 18)
ax.axis('off')
fig.patch.set_facecolor('#1a1a2e')
ax.set_facecolor('#1a1a2e')

# ── helpers ──────────────────────────────────────────────────────────────
def box(x, y, w, h, color, radius=0.3, alpha=0.92):
    b = FancyBboxPatch((x, y), w, h,
                       boxstyle=f"round,pad=0.05,rounding_size={radius}",
                       linewidth=1.5, edgecolor='#aaaaaa',
                       facecolor=color, alpha=alpha, zorder=3)
    ax.add_patch(b)

def label(x, y, txt, size=9, color='white', bold=False, ha='center', va='center'):
    w = 'bold' if bold else 'normal'
    ax.text(x, y, txt, fontsize=size, color=color, ha=ha, va=va,
            fontweight=w, zorder=5, fontfamily='monospace')

def arrow(x1, y1, x2, y2, col='#61dafb', lw=2, style='->', dashed=False):
    ls = (0, (4, 3)) if dashed else 'solid'
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle=style, color=col,
                                lw=lw, linestyle=ls), zorder=4)

def hline(x1, x2, y, col='#61dafb', lw=2, dashed=False):
    ls = '--' if dashed else '-'
    ax.plot([x1, x2], [y, y], color=col, lw=lw, linestyle=ls, zorder=4)

def vline(x, y1, y2, col='#61dafb', lw=2, dashed=False):
    ls = '--' if dashed else '-'
    ax.plot([x, x], [y1, y2], color=col, lw=lw, linestyle=ls, zorder=4)

def bus(x1, x2, y, label_txt, col='#61dafb'):
    ax.plot([x1, x2], [y, y], color=col, lw=4, zorder=4)
    ax.text((x1+x2)/2, y+0.18, label_txt, fontsize=8, color=col,
            ha='center', va='bottom', fontfamily='monospace', zorder=5)

# ══════════════════════════════════════════════════════════════════════════
# TITLE
# ══════════════════════════════════════════════════════════════════════════
ax.text(7, 17.5, 'BY-SYSTEMS — PoC Infrastructure', fontsize=13,
        color='#f0f0f0', ha='center', va='center', fontweight='bold',
        fontfamily='monospace')
ax.text(7, 17.1, 'Target topology (OPNsense isolation layer)', fontsize=9,
        color='#888888', ha='center', va='center', fontfamily='monospace')

# ══════════════════════════════════════════════════════════════════════════
# INTERNET
# ══════════════════════════════════════════════════════════════════════════
box(5, 16.1, 4, 0.65, '#16213e')
label(7, 16.43, 'INTERNET', 10, '#61dafb', bold=True)

arrow(7, 16.1, 7, 15.5, col='#61dafb')

# ══════════════════════════════════════════════════════════════════════════
# pfSense (PROD — DO NOT TOUCH)
# ══════════════════════════════════════════════════════════════════════════
box(3.5, 14.6, 7, 0.8, '#2d1515')
label(7, 15.05, 'pfSense  (PROD — DO NOT TOUCH)', 9.5, '#ff6b6b', bold=True)
label(7, 14.75, '10.6.224.1  |  LAN: vmbrOOB  10.6.224.0/20', 8, '#ffaaaa')

# OOB bus
bus(1.5, 12.5, 14.2, 'vmbrOOB  10.6.224.0/20  (OOB bridge — physical NIC)', '#e8a838')
vline(7, 14.6, 14.2, col='#e8a838')

# ══════════════════════════════════════════════════════════════════════════
# PROXMOX HOST
# ══════════════════════════════════════════════════════════════════════════
box(0.4, 4.0, 13.2, 9.9, '#0d2137', radius=0.5)
label(7, 13.65, 'srv-proxmox-poc-01  (10.6.224.105)', 10, '#90caf9', bold=True)
label(7, 13.3,  'Proxmox VE — hypervisor', 8.5, '#607d8b')

# ── OPNsense VM ──────────────────────────────────────────────────────────
box(1.2, 11.0, 5.2, 2.0, '#162a3a')
label(3.8, 12.7, 'vm-opnsense-poc-01', 9, '#4fc3f7', bold=True)
label(3.8, 12.38,'OPNsense  |  2 vCPU  2GB', 8, '#90caf9')
label(3.8, 12.05,'WAN: vmbrWAN3  bootstrap path', 7.5, '#ffcc80')
label(3.8, 11.72,'LAN: vmbrAPPS  trunk → SDN', 7.5, '#a5d6a7')
label(3.8, 11.28,'GW → 10.6.224.1 (pfSense)', 7.5, '#888888')

# OPNsense WAN tap to OOB bus
vline(3.8, 14.2, 13.0, col='#e8a838', lw=2)
vline(3.8, 13.0, 12.6, col='#e8a838', lw=2)
# (connect box top to bus)
ax.plot([3.8, 3.8], [14.2, 13.0], color='#e8a838', lw=2, zorder=4)

# Rune VM tap to OOB bus
vline(10.2, 14.2, 12.6, col='#e8a838', lw=2)

# ── Rune VM ──────────────────────────────────────────────────────────────
box(7.8, 11.0, 5.0, 2.0, '#1a2a1a')
label(10.3, 12.7, 'rune-vm  (Ubuntu 24.04)', 9, '#a5d6a7', bold=True)
label(10.3, 12.38,'OpenClaw  |  Terraform  |  Ansible', 8, '#81c784')
label(10.3, 12.05,'vmbrOOB  10.6.224.x (DHCP)', 7.5, '#ffcc80')
label(10.3, 11.55,'SSH keys: id_ed25519_rune', 7.5, '#888888')

# ── SDN bus ──────────────────────────────────────────────────────────────
bus(1.2, 12.6, 10.6, 'vmbrAPPS trunk  →  SDN zone poc  →  VNets mgmt / dmz / svc', '#a5d6a7')

# OPNsense LAN → SDN
vline(3.8, 11.0, 10.6, col='#a5d6a7')

# ── PoC VMs cluster ──────────────────────────────────────────────────────
# NetBox VM
box(1.2, 7.6, 3.8, 2.6, '#1a2637')
label(3.1, 9.9, 'vm-netbox-poc-01', 8.5, '#4fc3f7', bold=True)
label(3.1, 9.58,'NetBox  (IPAM / DCIM)', 8, '#90caf9')
label(3.1, 9.25,'10.1.3.31/24', 7.5, '#a5d6a7')
label(3.1, 8.92,'2 vCPU  4GB  50GB', 7.5, '#607d8b')
label(3.1, 8.55,'PostgreSQL :5432 (local)', 7, '#888888')
label(3.1, 8.22,'Redis :6379 (local)', 7, '#888888')
label(3.1, 7.88,'HTTP/S :80/:443', 7, '#888888')

# Bootstrap test VM
box(5.4, 7.6, 3.5, 2.6, '#1e2a1e')
label(7.15, 9.9, 'vm-debian-bootstrap', 8.5, '#a5d6a7', bold=True)
label(7.15, 9.58,'-test-01  (validated (validated))', 8, '#81c784')
label(7.15, 9.25,'10.6.225.11/20 (OOB now)', 7.5, '#ffcc80')
label(7.15, 8.75,'→ move to SDN VNet', 7.5, '#ffcc80')
label(7.15, 8.42,'10.1.1.x/10.1.3.x', 7.5, '#a5d6a7')
label(7.15, 7.88,'Baseline validated', 7, '#888888')

# Future VM slot
box(9.2, 7.6, 3.5, 2.6, '#1a1a2e')
label(10.95, 9.9, 'vm-???-poc-xx', 8.5, '#607d8b', bold=True)
label(10.95, 9.58,'future VMs', 8, '#546e7a')
label(10.95, 9.1, '10.1.x.x/24', 7.5, '#4a5568')
label(10.95, 8.1, '(planned)', 7, '#404040')
# dashed border override
b2 = FancyBboxPatch((9.2, 7.6), 3.5, 2.6,
                    boxstyle="round,pad=0.05,rounding_size=0.3",
                    linewidth=1.5, edgecolor='#444466',
                    linestyle='--', facecolor='#1a1a2e', alpha=0.5, zorder=3)
ax.add_patch(b2)

# PoC VMs → SDN
vline(3.1,  10.2, 10.6, col='#a5d6a7')
vline(7.15, 10.2, 10.6, col='#a5d6a7', dashed=True)
vline(10.95,10.2, 10.6, col='#444466', dashed=True)

# ── Storage ──────────────────────────────────────────────────────────────
box(1.2, 4.3, 5.5, 2.9, '#211a00')
label(3.95, 6.9, 'Synology NAS', 9, '#ffd54f', bold=True)
label(3.95, 6.58,'lib-synology-dsm (Python)', 8, '#ffcc80')
label(3.95, 6.25,'poc-data  (Proxmox storage pool)', 7.5, '#ffb74d')
label(3.95, 5.85,'NFS/iSCSI → Proxmox', 7.5, '#888888')
label(3.95, 5.52,'(BLOCKED)  rune-api DSM user blocked', 7.5, '#ff8a65')
label(3.95, 5.2, '   (Application→DSM=Allow needed)', 7, '#888888')
label(3.95, 4.65,'10.6.224.x (OOB)', 7.5, '#607d8b')

# Synology → OOB bus
vline(3.95, 7.2, 14.2, col='#e8a838', lw=1.5, dashed=True)

# ── Physical switches note ────────────────────────────────────────────────
box(7.5, 4.3, 5.7, 2.9, '#1a1020')
label(10.35, 6.9, 'Physical Switches', 9, '#ce93d8', bold=True)
label(10.35, 6.58,'Arista 7060 + 7020', 8, '#ba68c8')
label(10.35, 6.25,'10.6.224.x (OOB)', 7.5, '#9575cd')
label(10.35, 5.8, '[X]  no fake env bridge names', 7.5, '#ff8a65')
label(10.35, 5.47,'   no physical NIC attached', 7, '#888888')
label(10.35, 5.14,'[X]  PoC VMs never reach', 7.5, '#ff8a65')
label(10.35, 4.81,'   physical switch fabric', 7, '#888888')
label(10.35, 4.45,'Configs → git (collect-all-configs.sh)', 7, '#607d8b')

# ══════════════════════════════════════════════════════════════════════════
# LEGEND
# ══════════════════════════════════════════════════════════════════════════
box(0.4, 0.2, 13.2, 3.55, '#111122', radius=0.3)
label(7, 3.5, 'LEGEND', 8, '#aaaaaa', bold=True)

items = [
    ('#e8a838', 'vmbrOOB — physical OOB bridge  (10.6.224.0/20)'),
    ('#a5d6a7', 'vmbrAPPS trunk → SDN zone poc → VNets mgmt/dmz/svc'),
    ('#61dafb', 'Internet / pfSense uplink'),
    ('#ff8a65', 'Isolation boundary — PoC VMs cannot reach physical switch fabric'),
    ('#ffd54f', 'Storage — Synology NAS (poc-data pool)'),
    ('#888888', '- - -  Planned / future'),
]
for i, (col, txt) in enumerate(items):
    row = 3.1 - i * 0.45
    ax.plot([0.7, 1.1], [row, row], color=col, lw=3)
    label(1.25, row, txt, 7.5, '#cccccc', ha='left')

plt.tight_layout(pad=0.3)
plt.savefig('/tmp/poc-infra.png', dpi=150, bbox_inches='tight',
            facecolor='#1a1a2e')
print("saved /tmp/poc-infra.png")
