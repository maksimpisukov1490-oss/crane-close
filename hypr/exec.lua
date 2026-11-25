-- Автозапуск оверлея с журавликом.
-- Вставить в блок, который выполняется при старте Hyprland (exec-once).

local home = os.getenv("HOME")
hl.exec_cmd("qs -n -p " .. home .. "/.config/quickshell/crane -d")
