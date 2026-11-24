#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="/etc/kanata/kanata.kbd"
CONFIG_SOURCE="$REPOSITORY/configs/cfqv8.kbd"
UNIT_SOURCE="$REPOSITORY/kanata.service"
LEGACY_UNIT="keyd.service"
LEGACY_RESUME_HOOK="/usr/lib/systemd/system-sleep/xremap-resume.sh"

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

[[ $EUID -eq 0 ]] || die "запускай через sudo: sudo $0"
command -v kanata >/dev/null || die "kanata не найден - установи: sudo dnf copr enable alternateved/kanata && sudo dnf install kanata"
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

if ! kanata --cfg "$CONFIG_PATH" --check; then
    restore_previous
    die "kanata --check провалился - предыдущий конфиг восстановлен"
fi

install -m 644 "$UNIT_SOURCE" /etc/systemd/system/kanata.service
if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl enable kanata
    systemctl restart kanata
    if systemctl list-unit-files "$LEGACY_UNIT" --no-legend | grep -q .; then
        systemctl disable --now "$LEGACY_UNIT"
    fi
    rm -f /etc/keyd/cfqv8.conf /etc/keyd/nova.conf /etc/keyd/default.conf
else
    echo "apply: systemd не обнаружен - перезапусти kanata вручную" >&2
fi
rm -f "$LEGACY_RESUME_HOOK"

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
