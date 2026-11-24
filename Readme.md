# kanata-nova-42

Раскладка nova-42 для встроенной JIS-клавиатуры Panasonic Let's note CF-QV8. kanata читает
клавиатуру по имени "AT Translated Set 2 keyboard" и выпускает виртуальную "kanata virtual
keyboard"; конфиг на машину - configs/cfqv8.kbd.

## Карта раскладки

- Home-row моды: a/; -> Control, s/l -> Alt, d/k -> Meta, f/j -> Shift (удержание 150 мс,
  quick-tap 175 мс, require-prior-idle 150 мс - при быстром наборе всегда тап)
- Muhenkan -> слой Raise, Katakana -> слой Lower (пока держишь), Henkan -> Enter, AltL ->
  Escape, Menu/Compose -> Backspace
- Аккорд Muhenkan+Henkan -> слой std: каждая клавиша выдаёт саму себя; таймаут 100 мс
- Левая колонка: Tab -> `, CapsLock -> Tab, Shift -> ]
- Слой Lower: цифровой ряд -> F1-F12 и медиа (prev/next/play/volume/brightness/mute), hjkl
  -> стрелки, y/u/i/o -> pgup/pgdn/home/end, p -> Del
- Слой Raise: верхние символы US-раскладки хоста через Shift (!@#$%^&*(), [] {} и т.п.)
- Погашены (XX): escape, backspace, enter, f1-f12, 1-0, minus, equal, стрелки,
  ins/del/home/end/pgup/pgdn, sysrq/print/scrolllock/pause/numlock, rightalt, rightbrace,
  backslash, grave, yen, zenkakuhankaku, lctl, rctl, rmet, rsft, lmet

## Установка

apply.sh сам ставит pinned-бинарник kanata v1.12.0 из GitHub releases (zip с проверкой
sha256) в /usr/local/bin; нужны curl и unzip.

```bash
sudo ./apply.sh
./scripts/xremap-apply.sh
```

apply.sh ставит конфиг в /etc/kanata/kanata.kbd, прогоняет kanata --check (при провале
откатывает предыдущий конфиг), устанавливает kanata.service и включает i8042.reset=1.

## xremap

Super-C/V -> буфер обмена: глобально Ctrl+C/V, в foot - Ctrl+Shift+C/V. xremap слушает
только "kanata virtual keyboard"; ./scripts/xremap-apply.sh из активной Sway-сессии -
установка или переустановка. Откат: systemctl --user disable --now xremap.service.

## Откат kanata

sudo systemctl disable --now kanata
