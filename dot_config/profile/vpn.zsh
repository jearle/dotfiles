# WireGuard tunnels by name (wg-quick). Without a name: every tunnel.
#   vpn-up [name...]  vpn-down [name...]  vpn-reset [name...]  vpn-status

if [[ $OSTYPE == darwin* ]]; then
  _vpn_dir=/opt/homebrew/etc/wireguard
  # sudo resets PATH, and wg-quick needs bash >= 4 (macOS ships 3.2).
  _vpn_quick() { sudo /opt/homebrew/bin/bash /opt/homebrew/bin/wg-quick "$@"; }
  _vpn_running() { for f in /var/run/wireguard/*.name(N); do print -- ${${f:t}%.name}; done; }
  _vpn_iface() { sudo cat /var/run/wireguard/$1.name 2>/dev/null; }
else
  _vpn_dir=/etc/wireguard
  _vpn_quick() { sudo wg-quick "$@"; }
  _vpn_running() { sudo wg show interfaces | tr ' ' '\n' | grep .; }
  _vpn_iface() { print -- $1; }
fi

_vpn_configured() { sudo sh -c "ls $_vpn_dir/*.conf 2>/dev/null" | xargs -n1 basename 2>/dev/null | sed 's/\.conf$//'; }

vpn-up() {
  local name running=(${(f)"$(_vpn_running)"})
  for name in ${@:-${(f)"$(_vpn_configured)"}}; do
    (( ${running[(Ie)$name]} )) && { print "$name: already up"; continue; }
    _vpn_quick up $name
  done
}

vpn-down() {
  local name
  for name in ${@:-${(f)"$(_vpn_running)"}}; do _vpn_quick down $name; done
}

vpn-reset() {
  local names=(${@:-${(f)"$(_vpn_running)"}})
  vpn-down $names && vpn-up $names
}

vpn-status() {
  local name iface
  for name in ${(f)"$(_vpn_running)"}; do
    iface=$(_vpn_iface $name)
    print "== $name ($iface)"
    sudo wg show $iface endpoints | awk '{print "  endpoint:  " $2}'
    sudo wg show $iface latest-handshakes | awk -v now=$(date +%s) '{ if ($2 == 0) print "  handshake: never"; else print "  handshake: " now - $2 " s ago" }'
  done
}
