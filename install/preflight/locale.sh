#!/bin/bash

# Asahi Alarm ships LANG=C and Omarchy Mac has no ISO step to replace it, so a
# by-hand install runs non-UTF-8: byte-wise sorting, ASCII-only \u escapes, and
# any tool that reads the locale for its encoding.
locale_conf="${OMARCHY_LOCALE_CONF:-/etc/locale.conf}"
locale_gen="${OMARCHY_LOCALE_GEN:-/etc/locale.gen}"

# Already on a UTF-8 locale, whichever one: leave the user's choice alone.
if [[ -f $locale_conf ]] && grep -qiE '^LANG=.*(utf-?8)' "$locale_conf"; then
  echo "Locale is already UTF-8 ($(sed -n 's/^LANG=//p' "$locale_conf" | head -1))"
  return 0 2>/dev/null || exit 0
fi

if (( ${EUID:-$(id -u)} == 0 )); then
  as_root=()
else
  as_root=(sudo)
fi

echo "Setting up locale (en_US.UTF-8)..."

if ! locale -a 2>/dev/null | grep -qi "en_US.utf-\?8"; then
  if grep -q '^#en_US.UTF-8' "$locale_gen" 2>/dev/null; then
    "${as_root[@]}" sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "$locale_gen"
  elif ! grep -q '^en_US.UTF-8' "$locale_gen" 2>/dev/null; then
    echo "en_US.UTF-8 UTF-8" | "${as_root[@]}" tee -a "$locale_gen" >/dev/null
  fi

  "${as_root[@]}" locale-gen >/dev/null 2>&1
fi

echo "LANG=en_US.UTF-8" | "${as_root[@]}" tee "$locale_conf" >/dev/null

# The session that ran this keeps its inherited LANG; everything after it here
# should see the new one.
export LANG=en_US.UTF-8

echo "Locale set to en_US.UTF-8"
