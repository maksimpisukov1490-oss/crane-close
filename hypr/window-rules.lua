-- Окно настроек и окно-образец — плавающие, по центру, без общей прозрачности.

hl.window_rule({ match = { class = "ru.crane.Settings" }, float = true, center = true, opacity = "1.0 override" })
hl.window_rule({ match = { class = "ru.crane.Preview" }, float = true, center = true, opacity = "1.0 override" })
