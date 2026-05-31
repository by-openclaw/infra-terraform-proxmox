#!/usr/bin/env bash
# Copyright (c) BY-SYSTEMS SRL
# SPDX-License-Identifier: Apache-2.0
# Source: https://github.com/by-openclaw/infra-terraform-proxmox
#
# setup-adguard-tls.sh — idempotent post-create provisioning for the AdGuard
# Home test VM. Mirrors the seed pipeline's "secure baseline" philosophy: a
# fresh terraform apply + this script = AdGuard Home with TLS, DoT/DoH/DoQ,
# per-VLAN client policies, fresh admin password, and a daily renewal cron —
# no WebUI clicks.
#
# Re-runs safely. Will:
#   - install lego (latest GitHub release; the Debian-packaged version is
#     too old to include the Cloudflare provider)
#   - drop the Cloudflare DNS API token into /etc/lego/cloudflare.env (root
#     only). Token + zone-read both set from the same scoped token.
#   - issue (or recycle if still valid) a wildcard cert for *.${DOMAIN} via
#     ACME DNS-01 — only if the existing cert expires in <${RENEW_DAYS}d.
#   - patch /opt/AdGuardHome/AdGuardHome.yaml to enable TLS (port_https 443,
#     port_dns_over_tls 853, port_dns_over_quic 853), add the per-VLAN
#     persistent client entries with safe-search/parental on for iot+cctv,
#     and rotate the admin password if one isn't already in the secret store.
#   - install /etc/cron.d/lego-renew-adguard for automatic daily renewal +
#     AdGuard reload.
#
# Designed to be invoked from a terraform local-exec or by hand:
#   ./setup-adguard-tls.sh 10.11.3.101
#
# Env / config sources:
#   - CF token + ACME email: ~/.openclaw/workspace/infra/secrets/
#                            app-cloudflare-by-research-be.json (fields:
#                            api_token, acme_email, zone)
#   - admin password         (read or generated):
#                            ~/.openclaw/workspace/infra/secrets/
#                            app-adguard-test.json (fields: admin_bcrypt,
#                            admin_password)
#
# Limitations:
#   - jq, openssl, python3 (with bcrypt + PyYAML) must be on the OPERATOR
#     machine, ssh + sudo on the target VM.
#   - The wildcard zone is hard-coded to test.by-research.be — pass a
#     different DOMAIN env var to override.

set -euo pipefail

ADGUARD_IP="${1:-10.11.3.101}"
FW="${FW:-10.6.239.195}"
DOMAIN="${DOMAIN:-test.by-research.be}"
WILDCARD="*.${DOMAIN}"
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519_opnsense}"
SSH_USER="${SSH_USER:-by-systems}"
SECRETS_DIR="${HOME}/.openclaw/workspace/infra/secrets"
CF_SECRET="${SECRETS_DIR}/app-cloudflare-by-research-be.json"
AG_SECRET="${SECRETS_DIR}/app-adguard-test.json"
RENEW_DAYS="${RENEW_DAYS:-30}"

err()  { echo "[setup-adguard-tls] ERROR: $*" >&2; exit 1; }
note() { echo "[setup-adguard-tls] $*"; }

[ -f "$CF_SECRET" ] || err "missing Cloudflare secret at $CF_SECRET"

CF_TOKEN=$(jq -r '.fields.api_token' "$CF_SECRET")
ACME_EMAIL=$(jq -r '.fields.acme_email' "$CF_SECRET")

SSH_OPTS=(-o LogLevel=ERROR -o StrictHostKeyChecking=no
          -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
          -o ConnectTimeout=12 -o BatchMode=yes)
PROXY="-o ProxyCommand=ssh -W %h:%p ${SSH_OPTS[*]} -i ${SSH_KEY} by-rune@${FW}"

# Read-or-generate admin password (bcrypt for AdGuard /opt/AdGuardHome.yaml)
if [ -f "$AG_SECRET" ] && jq -e '.fields.admin_bcrypt' "$AG_SECRET" >/dev/null 2>&1; then
    ADMIN_HASH=$(jq -r '.fields.admin_bcrypt' "$AG_SECRET")
    note "reusing existing admin bcrypt hash from ${AG_SECRET##*/}"
else
    ADMIN_PW=$(openssl rand -base64 18 | tr -d '/+' | cut -c1-22)
    ADMIN_HASH=$(python3 -c "import bcrypt,sys; print(bcrypt.hashpw(sys.argv[1].encode(),bcrypt.gensalt(rounds=10)).decode())" "$ADMIN_PW")
    mkdir -p "$SECRETS_DIR"
    umask 077
    jq -n --arg pw "$ADMIN_PW" --arg hash "$ADMIN_HASH" --arg h "$ADGUARD_IP" '{
        fields: {host: $h, admin_user: "admin", admin_password: $pw,
                 admin_bcrypt: $hash, port_admin: 3000, port_doh: 443,
                 port_dot: 853, port_doq: 853}
    }' > "$AG_SECRET"
    chmod 600 "$AG_SECRET"
    unset ADMIN_PW
    note "generated fresh admin credentials and wrote ${AG_SECRET##*/} (mode 600)"
fi

ssh "$PROXY" "${SSH_OPTS[@]}" -i "$SSH_KEY" "${SSH_USER}@${ADGUARD_IP}" \
    "sudo -n bash -s" <<EOFREMOTE
set -e

# 1) Install latest lego (skip if already current). Debian's lego is too old
#    to ship the cloudflare DNS provider — fetch the GitHub release.
if ! /usr/local/bin/lego --version 2>/dev/null | grep -q "version [5-9]\."; then
    LATEST=\$(curl -s -m 10 https://api.github.com/repos/go-acme/lego/releases/latest \
        | grep tag_name | head -1 | sed -E 's/.*"v([^"]+)".*/\1/')
    apt-get remove -y -qq lego 2>/dev/null || true
    cd /tmp && curl -sL -o lego.tar.gz \
        "https://github.com/go-acme/lego/releases/download/v\${LATEST}/lego_v\${LATEST}_linux_amd64.tar.gz"
    tar -xzf lego.tar.gz -C /usr/local/bin lego
    chmod +x /usr/local/bin/lego
    echo "  installed lego \$(/usr/local/bin/lego --version)"
else
    echo "  lego already current: \$(/usr/local/bin/lego --version)"
fi

# 2) Cloudflare credentials in a 600 root-owned file
umask 077
mkdir -p /etc/lego /etc/lego/cert
cat > /etc/lego/cloudflare.env <<EOFCRED
CF_DNS_API_TOKEN=${CF_TOKEN}
CF_ZONE_API_TOKEN=${CF_TOKEN}
EOFCRED
chmod 600 /etc/lego/cloudflare.env

# 3) Issue (or renew) the wildcard cert. lego itself is idempotent — 'renew'
#    no-ops if --days hasn't expired. First run uses 'run', subsequent 'renew'.
. /etc/lego/cloudflare.env
export CF_DNS_API_TOKEN CF_ZONE_API_TOKEN LEGO_PATH=/etc/lego/cert
CRT=/etc/lego/cert/certificates/_.${DOMAIN}.crt
if [ ! -f "\$CRT" ]; then
    /usr/local/bin/lego run --email "${ACME_EMAIL}" --accept-tos --dns cloudflare \
        --dns.propagation.disable-rns --dns.propagation.wait 60s \
        --domains "${WILDCARD}" --domains "${DOMAIN}" 2>&1 | tail -6
else
    /usr/local/bin/lego renew --dns cloudflare \
        --dns.propagation.disable-rns --dns.propagation.wait 60s \
        --domains "${WILDCARD}" --domains "${DOMAIN}" --days ${RENEW_DAYS} 2>&1 | tail -4 || true
fi

# 4) Install daily renewal cron (idempotent — same file every time)
cat > /etc/lego/renew-adguard.sh <<'EOFRENEW'
#!/bin/bash
set -e
. /etc/lego/cloudflare.env
export CF_DNS_API_TOKEN CF_ZONE_API_TOKEN LEGO_PATH=/etc/lego/cert
if /usr/local/bin/lego renew --dns cloudflare \
    --dns.propagation.disable-rns --dns.propagation.wait 60s \
    --domains "__WILDCARD__" --domains "__BASE__" --days __DAYS__ 2>&1; then
    /usr/bin/systemctl reload-or-restart AdGuardHome
    echo "[\$(date)] renew check OK"
else
    echo "[\$(date)] renew failed (non-zero exit)"
fi
EOFRENEW
sed -i -e "s|__ACME_EMAIL__|${ACME_EMAIL}|" \
       -e "s|__WILDCARD__|${WILDCARD}|" \
       -e "s|__BASE__|${DOMAIN}|" \
       -e "s|__DAYS__|${RENEW_DAYS}|" /etc/lego/renew-adguard.sh
chmod 0755 /etc/lego/renew-adguard.sh
cat > /etc/cron.d/lego-renew-adguard <<'EOFCRON'
17 3 * * * root /etc/lego/renew-adguard.sh >> /var/log/lego-renew.log 2>&1
EOFCRON
chmod 0644 /etc/cron.d/lego-renew-adguard
[ -f /var/log/lego-renew.log ] || touch /var/log/lego-renew.log
chmod 0640 /var/log/lego-renew.log

# 5) Patch AdGuardHome.yaml — TLS, DoT/DoH/DoQ, per-VLAN clients, fresh admin
systemctl stop AdGuardHome
python3 <<PYEOF
import yaml
p='/opt/AdGuardHome/AdGuardHome.yaml'
c=yaml.safe_load(open(p))
c['users']=[{'name':'admin','password':'${ADMIN_HASH}'}]
c.setdefault('http',{})['address']='0.0.0.0:3000'
c['tls']={
    'enabled': True,
    'server_name': 'adguard.${DOMAIN}',
    'force_https': False,
    'port_https': 443,
    'port_dns_over_tls': 853,
    'port_dns_over_quic': 853,
    'port_dnscrypt': 0,
    'dnscrypt_config_file': '',
    'allow_unencrypted_doh': False,
    'strict_sni_check': False,
    'certificate_chain': '',
    'private_key': '',
    'certificate_path': '/etc/lego/cert/certificates/_.${DOMAIN}.crt',
    'private_key_path':  '/etc/lego/cert/certificates/_.${DOMAIN}.key',
}
VLAN_CLIENTS=[
    ('mgmt',   '10.11.1.0/24',  'fd11:1::/64'),
    ('dmz',    '10.11.2.0/24',  'fd11:2::/64'),
    ('svc',    '10.11.3.0/24',  'fd11:3::/64'),
    ('vpn',    '10.11.4.0/24',  'fd11:4::/64'),
    ('iot',    '10.11.10.0/24', 'fd11:10::/64'),
    ('voip',   '10.11.11.0/24', 'fd11:11::/64'),
    ('storage','10.11.20.0/24', 'fd11:20::/64'),
    ('media',  '10.11.30.0/24', 'fd11:30::/64'),
    ('gaming', '10.11.32.0/24', 'fd11:32::/64'),
    ('cctv',   '10.11.40.0/24', 'fd11:40::/64'),
]
persistent=[]
for zone, cidr4, cidr6 in VLAN_CLIENTS:
    persistent.append({
        'name': f'vlan-{zone}',
        'ids': [cidr4, cidr6],
        'use_global_settings': True,
        'filtering_enabled': True,
        'parental_enabled': zone in ('iot','cctv'),
        'safe_search': {'enabled': zone=='iot', 'bing':True,'duckduckgo':True,
                        'ecosia':True,'google':True,'pixabay':True,
                        'yandex':True,'youtube':True},
        'safebrowsing_enabled': True,
        'blocked_services': {'schedule':{'time_zone':'Local'},'ids':[]},
        'upstreams': [],
        'upstreams_cache_enabled': False,
    })
c.setdefault('clients',{})['persistent']=persistent
c['clients'].setdefault('runtime_sources',{'whois':True,'arp':True,
                                            'rdns':True,'dhcp':True,'hosts':True})
# Internal name rewrite so adguard.${DOMAIN} resolves to AdGuard itself
rewrites=c.setdefault('filtering',{}).setdefault('rewrites',[])
existing={(r.get('domain'),r.get('answer')) for r in rewrites}
for d,a in [('adguard.${DOMAIN}','${ADGUARD_IP}'),
            ('adguard.${DOMAIN}','fd11:3::101')]:
    if (d,a) not in existing:
        rewrites.append({'domain':d,'answer':a})
yaml.dump(c,open(p,'w'),default_flow_style=False,sort_keys=False)
PYEOF
systemctl start AdGuardHome
sleep 4
echo "  AdGuardHome service: \$(systemctl is-active AdGuardHome)"
ss -tlnp | grep -E ':(53|443|853|3000)\b' | head -4 || true
EOFREMOTE

note "DONE. Listeners + cert + cron + per-VLAN clients in place on ${ADGUARD_IP}."
note "Admin credentials: ${AG_SECRET}"
