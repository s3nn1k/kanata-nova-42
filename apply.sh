#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="/etc/kanata/kanata.kbd"
CONFIG_SOURCE="$REPOSITORY/configs/cfqv8.kbd"
UNIT_SOURCE="$REPOSITORY/kanata.service"
KANATA_VERSION="1.12.0"
KANATA_ZIP_SHA256="0bedd91567c5d7c54679061baadc37e4f83fb71750003999bc1d11f2c9754f36"
KANATA_URL="https://github.com/jtroo/kanata/releases/download/v${KANATA_VERSION}/linux-binaries-x64.zip"
KANATA_BIN="/usr/local/bin/kanata"

die() {
    echo "apply: $1" >&2
    exit 1
}

restore_previous() {
    if [[ -n "$previous_config" ]]; then
        cp "$previous_config" "$CONFIG_PATH"
    else
        rm -f "$CONFIG_PATH"
    fi
}

install_kanata() {
    if [[ -f "$KANATA_BIN" ]] && "$KANATA_BIN" --version 2>/dev/null | grep -q "kanata ${KANATA_VERSION}"; then
        return
    fi
    local staged
    staged="$(mktemp)"
    curl --fail --location --show-error --retry 2 --connect-timeout 15 --max-time 300 \
        --proto '=https' --tlsv1.2 --output "$staged" "$KANATA_URL"
    printf '%s  %s\n' "$KANATA_ZIP_SHA256" "$staged" | sha256sum --check
    unzip -p "$staged" kanata_linux_x64 > "${staged}.bin"
    install -m 755 "${staged}.bin" "$KANATA_BIN"
    rm -f "$staged" "${staged}.bin"
}

[[ $EUID -eq 0 ]] || die "запускай через sudo: sudo $0"
command -v curl >/dev/null || die "curl не найден - нужен для установки kanata"
command -v unzip >/dev/null || die "unzip не найден - нужен для установки kanata"
install_kanata
[[ -f "$CONFIG_SOURCE" ]] || die "нет конфига $CONFIG_SOURCE"
[[ -f "$UNIT_SOURCE" ]] || die "нет юнита $UNIT_SOURCE"

previous_config=""
cleanup() {
    [[ -z "$previous_config" ]] || rm -f "$previous_config"
}
trap cleanup EXIT

install -d -m 755 /etc/kanata
if [[ -f "$CONFIG_PATH" ]]; then
    previous_config="$(mktemp)"
    cp "$CONFIG_PATH" "$previous_config"
fi
install -m 644 "$CONFIG_SOURCE" "$CONFIG_PATH"

if ! "$KANATA_BIN" --cfg "$CONFIG_PATH" --check; then
    restore_previous
    die "kanata --check провалился - предыдущий конфиг восстановлен"
fi

install -m 644 "$UNIT_SOURCE" /etc/systemd/system/kanata.service
if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl enable kanata
    systemctl restart kanata
else
    echo "apply: systemd не обнаружен - перезапусти kanata вручную" >&2
fi

if command -v grubby >/dev/null; then
    if grubby --update-kernel=ALL --args="i8042.reset=1"; then
        echo "apply: i8042.reset=1 включён для всех ядер - вступит в силу после перезагрузки"
    else
        echo "apply: grubby не обновил kernel-параметры - включи i8042.reset=1 вручную" >&2
    fi
else
    echo "apply: grubby не найден, включи i8042.reset=1 вручную" >&2
fi

echo "apply: $CONFIG_PATH установлен, служба kanata запущена"
