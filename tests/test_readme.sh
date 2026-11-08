#!/usr/bin/env bash
# Tests de comportamiento para la frase de bienvenida del README.md (task-20261108-001).
set -u
README="README.md"
ANCHOR="Repositorio de prueba de la AI Factory."
WELCOME="Bienvenido: este repositorio sirve para probar la fábrica de software."
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# Líneas del README sin CR ni dependencia del salto final.
mapfile -t LINES < <(tr -d '\r' < "$README"; [ -n "$(tail -c1 "$README")" ] && echo)

# CA1: la línea siguiente al ancla es exactamente la frase de bienvenida.
found=0
for i in "${!LINES[@]}"; do
  if [ "${LINES[$i]}" = "$ANCHOR" ]; then
    found=1
    next="${LINES[$((i+1))]-}"
    if [ "$next" = "$WELCOME" ]; then pass "CA1 línea siguiente al ancla es la bienvenida"
    else fail "CA1 línea siguiente al ancla es '$next', se esperaba la bienvenida"; fi
    break
  fi
done
[ "$found" -eq 1 ] || fail "CA1 no se encontró la línea ancla"

# CA2: la frase aparece exactamente una vez.
count=0
for l in "${LINES[@]}"; do [ "$l" = "$WELCOME" ] && count=$((count+1)); done
if [ "$count" -eq 1 ]; then pass "CA2 la bienvenida aparece una vez"
else fail "CA2 la bienvenida aparece $count veces, se esperaba 1"; fi

# CA3: quitando la línea de bienvenida, el contenido es idéntico al README anterior.
EXPECTED=("# test-project" "" "$ANCHOR")
REST=()
for l in "${LINES[@]}"; do [ "$l" = "$WELCOME" ] || REST+=("$l"); done
if [ "$(printf '%s\n' "${REST[@]}")" = "$(printf '%s\n' "${EXPECTED[@]}")" ]; then
  pass "CA3 el resto del README es idéntico al anterior"
else fail "CA3 el resto del README difiere del anterior"; fi

# CA4: la línea ancla sigue presente y sin modificar.
anchor_count=0
for l in "${LINES[@]}"; do [ "$l" = "$ANCHOR" ] && anchor_count=$((anchor_count+1)); done
if [ "$anchor_count" -eq 1 ]; then pass "CA4 la línea ancla sigue presente"
else fail "CA4 la línea ancla aparece $anchor_count veces"; fi

[ "$fails" -eq 0 ]
