#!/usr/bin/env bash
# Tests de comportamiento para la línea de comprobación del README.md (task-20261109-003).
set -u
README="README.md"
WELCOME="Bienvenido: este repositorio sirve para probar la fábrica de software."
CHECK="Última comprobación: fusión automática."
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

mapfile -t LINES < <(tr -d '\r' < "$README"; [ -n "$(tail -c1 "$README")" ] && echo)

# CA1: la línea siguiente a la bienvenida es exactamente la línea de comprobación.
found=0
for i in "${!LINES[@]}"; do
  if [ "${LINES[$i]}" = "$WELCOME" ]; then
    found=1
    next="${LINES[$((i+1))]-}"
    if [ "$next" = "$CHECK" ]; then pass "CA1 línea siguiente a la bienvenida es la comprobación"
    else fail "CA1 línea siguiente a la bienvenida es '$next', se esperaba '$CHECK'"; fi
    break
  fi
done
[ "$found" -eq 1 ] || fail "CA1 no se encontró la línea de bienvenida"

# CA2: el texto de comprobación aparece exactamente una vez en todo el fichero.
count=$(grep -oF -- "$CHECK" "$README" | wc -l)
if [ "$count" -eq 1 ]; then pass "CA2 la comprobación aparece una vez"
else fail "CA2 la comprobación aparece $count veces, se esperaba 1"; fi

# CA3: sin la línea añadida, el resto del README es idéntico y en el mismo orden.
EXPECTED=("# test-project" "" "Repositorio de prueba de la AI Factory." "$WELCOME")
REST=()
for l in "${LINES[@]}"; do [ "$l" = "$CHECK" ] || REST+=("$l"); done
if [ "$(printf '%s\n' "${REST[@]}")" = "$(printf '%s\n' "${EXPECTED[@]}")" ]; then
  pass "CA3 el resto del README es idéntico al anterior"
else fail "CA3 el resto del README difiere del anterior"; fi

# CA4: bienvenida y comprobación son texto normal (sin encabezado, lista, cita ni código).
plain() {
  case "$1" in
    "#"*|"-"*|"*"*|"+"*|">"*|'`'*|"~~~"*|"    "*|$'\t'*) return 1 ;;
  esac
  local olre='^[0-9]+[.)]'
  [[ "$1" =~ $olre ]] && return 1
  return 0
}
has_check=0
for l in "${LINES[@]}"; do [ "$l" = "$CHECK" ] && has_check=1; done
if [ "$has_check" -eq 1 ] && plain "$WELCOME" && plain "$CHECK"; then
  pass "CA4 bienvenida y comprobación son texto normal"
else fail "CA4 la línea de comprobación no está presente como texto normal"; fi

[ "$fails" -eq 0 ]
