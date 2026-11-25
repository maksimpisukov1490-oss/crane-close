-- Закрытие окна с анимацией.
-- Заменяет обычный hl.dsp.window.close().
-- Путь обязательно полный: в PATH у Hyprland обычно нет ~/.local/bin.

local home = os.getenv("HOME")
create_bind(vars.kbCloseWindow, hl.dsp.exec_cmd(home .. "/.local/bin/crane-close"))
