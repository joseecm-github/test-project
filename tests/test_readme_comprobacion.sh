#!/usr/bin/env bash
# Tests de comportamiento para la línea de comprobación del README.md (task-20261109-002).
set -u
README="README.md"
WELCOME="Bienvenido: este repositorio sirve para probar la fábrica de software."
CHECK="Última comprobación: fusión automática."
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# Líneas del README sin CR ni dependencia del salto final.
mapfile -t LINES < <(tr -d '\r' < "$README"; [ -n "$(tail -c1 "$README")" ] && echo)

# CA1: la línea siguiente a la bienvenida es exactamente la línea de comprobación.
found=0
for i in "${!LINES[@]}"; do
  if [ "${LINES[$i]}" = "$WELCOME" ]; then
    found=1
    next="${LINES[$((i+1))]-}"
    if [ "$next" = "$CHECK" ]; then pass "CA1 línea siguiente a la bienvenida es la de comprobación"
    else fail "CA1 línea siguiente a la bienvenida es '$next', se esperaba la de comprobación"; fi
    break
  fi
done
[ "$found" -eq 1 ] || fail "CA1 no se encontró la línea de bienvenida"

# CA2: la línea de comprobación aparece exactamente una vez.
count=0
for l in "${LINES[@]}"; do [ "$l" = "$CHECK" ] && count=$((count+1)); done
if [ "$count" -eq 1 ]; then pass "CA2 la línea de comprobación aparece una vez"
else fail "CA2 la línea de comprobación aparece $count veces, se esperaba 1"; fi

# CA3: quitando la línea de comprobación, el contenido es idéntico al README original.
EXPECTED=("# test-project" "" "Repositorio de prueba de la AI Factory." "$WELCOME")
REST=()
for l in "${LINES[@]}"; do [ "$l" = "$CHECK" ] || REST+=("$l"); done
if [ "$count" -ge 1 ] && [ "$(printf '%s\n' "${REST[@]}")" = "$(printf '%s\n' "${EXPECTED[@]}")" ]; then
  pass "CA3 sin la línea de comprobación el README es idéntico al original"
else fail "CA3 el README sin la línea de comprobación difiere del original (o la línea no existe)"; fi

# CA4: la línea de bienvenida sigue siendo exactamente la original y única.
wcount=0
for l in "${LINES[@]}"; do [ "$l" = "$WELCOME" ] && wcount=$((wcount+1)); done
if [ "$wcount" -eq 1 ]; then pass "CA4 la línea de bienvenida sigue intacta"
else fail "CA4 la línea de bienvenida aparece $wcount veces, se esperaba 1"; fi

[ "$fails" -eq 0 ]
