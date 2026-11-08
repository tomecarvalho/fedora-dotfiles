#!/bin/sh
# Detect timezone from public IP and apply it with timedatectl.

valid_tz() {
  case "$1" in
    ""|*[!A-Za-z0-9_/+-]*) return 1 ;;
  esac
  [ -f "/usr/share/zoneinfo/$1" ]
}

fetch() {
  case "$1" in
    ip-api.com)
      curl -sf --max-time 10 "http://ip-api.com/line/?fields=timezone" ;;
    ipinfo.io)
      curl -sf --max-time 10 "https://ipinfo.io/timezone" ;;
    worldtimeapi.org)
      curl -sf --max-time 10 "https://worldtimeapi.org/api/ip" \
        | sed -n 's/.*"timezone":"\([^"]*\)".*/\1/p' ;;
    ipapi.co)
      curl -sf --max-time 10 "https://ipapi.co/timezone" ;;
  esac
}

for service in ip-api.com ipinfo.io worldtimeapi.org ipapi.co; do
  echo "Determine timezone: trying service $service..."
  tz=$(fetch "$service" | tr -d '\r\n')
  if valid_tz "$tz"; then
    if sudo timedatectl set-timezone "$tz"; then
      echo "Timezone set to $tz"
      exit 0
    fi
    echo "timedatectl failed to set $tz" >&2
    exit 1
  fi
done

echo "Failed to determine timezone. To set manually, run the following command:"
echo "sudo timedatectl set-timezone Europe/Lisbon"
exit 1