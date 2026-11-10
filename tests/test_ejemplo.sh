#!/usr/bin/env bash
# Tests de comportamiento para docs/ejemplo.md (task-20261110-003).
set -u
DOC="docs/ejemplo.md"
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# CA1: el fichero existe y es un fichero regular legible.
if [ -f "$DOC" ] && [ -r "$DOC" ]; then
  pass "CA1 $DOC existe y es legible"
else
  fail "CA1 $DOC no existe o no es un fichero regular legible"
  fail "CA2 no se puede leer el título: $DOC no existe"
  fail "CA3 no se pueden contar viñetas: $DOC no existe"
  fail "CA4 no se puede comprobar el renderizado: $DOC no existe"
  exit 1
fi

# Líneas sin dependencia del salto final.
mapfile -t LINES < <(cat "$DOC"; [ -n "$(tail -c1 "$DOC")" ] && echo)

# CA2: la primera línea es exactamente "# Ejemplo" (sin espacios ni CR).
first="${LINES[0]-}"
if [ "$first" = "# Ejemplo" ]; then pass "CA2 la primera línea es '# Ejemplo'"
else fail "CA2 la primera línea es '$first', se esperaba exactamente '# Ejemplo'"; fi

# CA3: al menos 3 líneas que empiezan por "- ", "* " o "+ " seguidas de un carácter no espacio.
bullets=0
for l in "${LINES[@]}"; do
  l="${l%$'\r'}"
  [[ "$l" =~ ^[-*+]\ +[^[:space:]] ]] && bullets=$((bullets+1))
done
if [ "$bullets" -ge 3 ]; then pass "CA3 hay $bullets viñetas con texto"
else fail "CA3 hay $bullets viñetas con texto, se esperaban al menos 3"; fi

# CA4: estructura CommonMark: un único H1 "Ejemplo" y una lista no ordenada
# (ítems consecutivos con el mismo marcador) de al menos 3 elementos.
# Aproximación sin dependencias: se ignoran bloques de código cercados.
h1_count=0; h1_text=""
in_fence=0
max_run=0; run=0; marker=""; prev=""
for l in "${LINES[@]}"; do
  l="${l%$'\r'}"
  if [[ "$l" =~ ^\ {0,3}(\`\`\`|~~~) ]]; then
    in_fence=$((1-in_fence)); run=0; marker=""; prev="$l"; continue
  fi
  [ "$in_fence" -eq 1 ] && { prev="$l"; continue; }
  # H1 ATX.
  if [[ "$l" =~ ^\ {0,3}#([[:space:]]+(.*))?$ ]]; then
    h1_count=$((h1_count+1))
    t="${BASH_REMATCH[2]}"
    t="$(printf '%s' "$t" | sed -E 's/[[:space:]]+#+[[:space:]]*$//; s/[[:space:]]+$//')"
    h1_text="$t"
  fi
  # H1 setext (texto seguido de "===").
  if [[ "$l" =~ ^\ {0,3}=+[[:space:]]*$ ]] && [ -n "${prev//[[:space:]]/}" ] && [ "$run" -eq 0 ]; then
    h1_count=$((h1_count+1)); h1_text="$prev"
  fi
  # Ítems de lista no ordenada; las líneas en blanco no rompen la lista.
  if [[ "$l" =~ ^\ {0,3}([-*+])\ +[^[:space:]] ]]; then
    m="${BASH_REMATCH[1]}"
    if [ "$m" = "$marker" ]; then run=$((run+1)); else marker="$m"; run=1; fi
    [ "$run" -gt "$max_run" ] && max_run="$run"
  elif [ -n "${l//[[:space:]]/}" ] && ! [[ "$l" =~ ^\ {2,} ]]; then
    run=0; marker=""
  fi
  prev="$l"
done
if [ "$h1_count" -eq 1 ] && [ "$h1_text" = "Ejemplo" ]; then pass "CA4 hay un único H1 'Ejemplo'"
else fail "CA4 se encontraron $h1_count H1 (último: '$h1_text'), se esperaba uno solo 'Ejemplo'"; fi
if [ "$max_run" -ge 3 ]; then pass "CA4 hay una lista no ordenada de $max_run elementos"
else fail "CA4 la lista no ordenada más larga tiene $max_run elementos, se esperaban al menos 3"; fi

[ "$fails" -eq 0 ]
