-- Окно настроек и окно-образец — плавающие, по центру.

hl.window_rule({ match = { class = "ru.crane.Settings" }, float = true, center = true })
hl.window_rule({ match = { class = "ru.crane.Preview" }, float = true, center = true })
