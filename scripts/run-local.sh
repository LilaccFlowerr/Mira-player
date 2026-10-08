#!/usr/bin/env bash
# Fedora developer launcher; also supports locally extracted Qt RPMs without root.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
qt_prefix="${MIRA_QT_PREFIX:-}"
if [[ -z "$qt_prefix" && -f "$root/build/CMakeCache.txt" ]]; then
  qt_dir="$(sed -n 's/^Qt6WebEngineCore_DIR:PATH=//p' "$root/build/CMakeCache.txt")"
  if [[ -n "$qt_dir" ]]; then qt_prefix="$(cd "$qt_dir/../../.." && pwd)"; fi
fi
if [[ -n "$qt_prefix" && "$qt_prefix" != /usr ]]; then
  export LD_LIBRARY_PATH="$qt_prefix/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export QTWEBENGINEPROCESS_PATH="$qt_prefix/lib64/qt6/libexec/QtWebEngineProcess"
  export QTWEBENGINE_RESOURCES_PATH="$qt_prefix/share/qt6/resources"
  export QTWEBENGINE_LOCALES_PATH="$qt_prefix/share/qt6/translations/qtwebengine_locales"
fi
exec "$root/build/mira" "$@"
