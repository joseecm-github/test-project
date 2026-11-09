#!/usr/bin/env bash
# Tests de comportamiento para docs/guia.md (task-20261109-004).
set -u
export LC_ALL=C.UTF-8 2>/dev/null || true
DOC="docs/guia.md"
L1="# Guía"
L2="Este documento se creó con la fábrica de software."
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# CA1: el fichero existe.
if [ -f "$DOC" ]; then pass "CA1 $DOC existe"
else
  fail "CA1 $DOC no existe"
  for c in CA2 CA3 CA4 CA5; do fail "$c no evaluable: $DOC no existe"; done
  exit 1
fi

# Líneas tal cual (sin quitar CR), tolerando la ausencia de salto final.
mapfile -t LINES < <(cat "$DOC"; [ -n "$(tail -c1 "$DOC")" ] && echo)

# CA2: primera línea exacta.
if [ "${LINES[0]-}" = "$L1" ]; then pass "CA2 primera línea es '$L1'"
else fail "CA2 primera línea es '${LINES[0]-}', se esperaba '$L1'"; fi

# CA3: segunda línea exacta.
if [ "${LINES[1]-}" = "$L2" ]; then pass "CA3 segunda línea es la frase de presentación"
else fail "CA3 segunda línea es '${LINES[1]-}', se esperaba '$L2'"; fi

# CA4: exactamente dos líneas, sin nada más (se admite un salto final).
content="$(cat "$DOC"; echo x)"; content="${content%x}"
if [ "$content" = "$L1"$'\n'"$L2"$'\n' ] || [ "$content" = "$L1"$'\n'"$L2" ]; then
  pass "CA4 el fichero tiene exactamente las dos líneas"
else fail "CA4 el fichero tiene ${#LINES[@]} líneas o contenido adicional"; fi

# CA5: decodifica como UTF-8 y contiene í y ó correctamente codificados.
if python3 -I -c 'import sys; t=open(sys.argv[1],"rb").read().decode("utf-8"); sys.exit(0 if ("í" in t and "ó" in t) else 1)' "$DOC" 2>/dev/null; then
  pass "CA5 UTF-8 válido con í y ó"
else fail "CA5 no decodifica como UTF-8 o faltan í/ó"; fi

[ "$fails" -eq 0 ]
