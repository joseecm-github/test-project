#!/usr/bin/env bash
# Tests de comportamiento para docs/notas.md (task-20261110-001).
set -u
NOTAS="docs/notas.md"
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# CA1: el fichero existe.
if [ -f "$NOTAS" ]; then
  pass "CA1 $NOTAS existe"
else
  fail "CA1 $NOTAS no existe"
  fail "CA2 no se puede leer el título: $NOTAS no existe"
  fail "CA3 no se pueden contar viñetas: $NOTAS no existe"
  fail "CA4 no se puede revisar el contenido: $NOTAS no existe"
  exit 1
fi

# Líneas sin CR ni dependencia del salto final.
mapfile -t LINES < <(tr -d '\r' < "$NOTAS"; [ -n "$(tail -c1 "$NOTAS")" ] && echo)

# CA2: la primera línea no vacía es exactamente "# Notas".
first=""
for l in "${LINES[@]}"; do
  if [ -n "${l//[[:space:]]/}" ]; then first="$l"; break; fi
done
if [ "$first" = "# Notas" ]; then pass "CA2 la primera línea no vacía es '# Notas'"
else fail "CA2 la primera línea no vacía es '$first', se esperaba '# Notas'"; fi

# CA3: al menos 3 viñetas ("- " o "* ") con texto no vacío.
bullets=0
for l in "${LINES[@]}"; do
  if [[ "$l" =~ ^[-*]\ (.*)$ ]]; then
    text="${BASH_REMATCH[1]}"
    [ -n "${text//[[:space:]]/}" ] && bullets=$((bullets+1))
  fi
done
if [ "$bullets" -ge 3 ]; then pass "CA3 hay $bullets viñetas con texto"
else fail "CA3 hay $bullets viñetas con texto, se esperaban al menos 3"; fi

# CA4: no contiene claves, tokens ni credenciales (patrones habituales).
if grep -Eiq '(api[_-]?key|secret|password|passwd|token|bearer|BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-)[[:space:]]*[:=]?' "$NOTAS"; then
  fail "CA4 $NOTAS parece contener secretos"
else
  pass "CA4 $NOTAS no contiene secretos"
fi

[ "$fails" -eq 0 ]
