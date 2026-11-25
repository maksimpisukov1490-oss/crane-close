#!/usr/bin/env bash
# Раскладывает оверлей и скрипт по местам. Конфиг Hyprland не трогает.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/crane"
bin="${HOME}/.local/bin"

mkdir -p "$(dirname "$cfg")" "$bin"

if [ -e "$cfg" ]; then
    backup="${cfg}.bak.$(date +%s)"
    mv "$cfg" "$backup"
    echo "Старый конфиг отложен в $backup"
fi

cp -r "$here/quickshell" "$cfg"
install -Dm755 "$here/bin/crane-close" "$bin/crane-close"

echo
echo "Готово. Осталось добавить в конфиг Hyprland:"
echo
echo "  hypr/exec.lua       — автозапуск оверлея"
echo "  hypr/keybind.lua    — бинд закрытия окна"
echo "  hypr/layer-rule.lua — правило слоя"
echo
echo "Потом:"
echo "  hyprctl reload"
echo "  qs -n -p $cfg -d"
