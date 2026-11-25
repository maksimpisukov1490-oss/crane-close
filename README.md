# crane-close

Закрытие окна в стиле перехода PowerPoint **Origami**: скриншот окна
сминается в бумажного журавлика, журавлик улетает, окно закрывается.

Сделано для **Hyprland + Quickshell** (Wayland). Журавлик — настоящая
3D-модель из 16 бумажных граней: на лицевую сторону проецируется содержимое
окна, изнанка чёрная.

## Как это выглядит

1. Жмёшь `SUPER + Q` на активном окне.
2. Поверх окна появляется его скриншот — точь-в-точь как само окно.
3. У листа срезаются углы, и он сминается в точку.
4. Из точки раскрывается журавлик с содержимым окна на гранях.
5. Журавлик улетает вправо-вверх, окно закрывается.

Вся анимация — около 2 секунд, как в PowerPoint.

## Что нужно

- Hyprland (проверено на 0.57, конфиг на Lua).
- Quickshell 0.3+ с поддержкой Qt Quick 3D.
- Python 3, `grim`.
- Мониторы с масштабом 1 (при других масштабах скриншот может не совпасть
  по размеру).

## Установка

1. Разложить файлы:

```sh
mkdir -p ~/.config/quickshell ~/.local/bin
cp -r quickshell ~/.config/quickshell/crane
install -Dm755 bin/crane-close ~/.local/bin/crane-close
```

2. Добавить автозапуск оверлея (в блок `exec-once` своего конфига):

```lua
local home = os.getenv("HOME")
hl.exec_cmd("qs -n -p " .. home .. "/.config/quickshell/crane -d")
```

3. Повесить закрытие окна на скрипт. Важно: **полный путь**, потому что
в PATH у Hyprland обычно нет `~/.local/bin`:

```lua
local home = os.getenv("HOME")
create_bind(vars.kbCloseWindow, hl.dsp.exec_cmd(home .. "/.local/bin/crane-close"))
```

4. Отключить анимацию слоя, иначе оверлей будет выезжать сбоку:

```lua
hl.layer_rule({ match = { namespace = "crane" }, no_anim = true })
```

5. Перезагрузить Hyprland и запустить оверлей:

```sh
hyprctl reload
qs -n -p ~/.config/quickshell/crane -d
```

Готово. `SUPER + Q` теперь закрывает окно с журавликом.

## Как это устроено

| Файл | Что делает |
|---|---|
| `quickshell/shell.qml` | корень оверлея, IPC-команды |
| `quickshell/CraneOverlay.qml` | окно на монитор, таймлайн, сминание листа |
| `quickshell/Crane3D.qml` | сборка журавлика из граней |
| `quickshell/CraneFacet.qml` | одна грань: лицевая сторона и чёрная изнанка |
| `quickshell/facets.js` | 16 граней: точки, UV, глубина, оттенок |
| `bin/crane-close` | скриншот активного окна, IPC, закрытие окна |

Скрипт снимает окно через `grim`, отдаёт картинку оверлею по IPC и закрывает
окно по адресу. Оверлей живёт поверх всех окон, но не ловит мышь и клавиатуру.

Пересобрать грани из SVG:

```sh
cd ~/.config/quickshell/crane
python3 tools/make_facets.py
```

## Ограничения

- Перехватить клик по крестику внутри чужой программы на Wayland нельзя:
  анимация работает только при закрытии через бинд.
- Если оверлей не запущен, окно просто закрывается, без анимации.
- Скриншот снимается с экрана: если окно перекрыто другим окном, на бумаге
  окажется то, что видно. Для активного окна это не проблема.

## Лицензии и атрибуция

Журавлик собран по SVG **«Origami - Crane.svg»** с Wikimedia Commons:

- автор: **Binnette**;
- лицензия: **CC BY-SA 3.0**;
- источник: https://commons.wikimedia.org/wiki/File:Origami_-_Crane.svg

`quickshell/assets/crane.svg` и производный `quickshell/facets.js`
распространяются на условиях CC BY-SA 3.0. Подробности — в
[ATTRIBUTION.md](ATTRIBUTION.md).

На остальной код явная лицензия не задана.
