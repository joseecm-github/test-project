#!/usr/bin/env bash
# Tests de comportamiento para docs/notas.md (task-20261109-006).
set -u
NOTAS="docs/notas.md"
fails=0
pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

# CA1: el fichero existe.
if [ -f "$NOTAS" ]; then pass "CA1 $NOTAS existe"
else fail "CA1 $NOTAS no existe"; echo "  (resto de criterios no evaluables)"; exit 1; fi

# Líneas sin CR ni dependencia del salto final.
mapfile -t LINES < <(tr -d '\r' < "$NOTAS"; [ -n "$(tail -c1 "$NOTAS")" ] && echo)

# CA2: la primera línea no vacía es exactamente "# Notas".
first=""; first_idx=-1
for i in "${!LINES[@]}"; do
  if [ -n "${LINES[$i]//[[:space:]]/}" ]; then first="${LINES[$i]}"; first_idx=$i; break; fi
done
if [ "$first" = "# Notas" ]; then pass "CA2 primera línea no vacía es '# Notas'"
else fail "CA2 primera línea no vacía es '$first', se esperaba '# Notas'"; fi

# Viñetas: líneas que empiezan por "- " o "* ".
BULLETS=()
for l in "${LINES[@]}"; do
  case "$l" in "- "*|"* "*) BULLETS+=("$l") ;; esac
done

# CA3: al menos 3 viñetas.
if [ "${#BULLETS[@]}" -ge 3 ]; then pass "CA3 hay ${#BULLETS[@]} viñetas (>= 3)"
else fail "CA3 hay ${#BULLETS[@]} viñetas, se esperaban al menos 3"; fi

# CA4: ninguna viñeta vacía ni con marcadores de relleno.
bad=0
for b in "${BULLETS[@]}"; do
  text="${b:2}"
  stripped="${text//[[:space:]]/}"
  lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$stripped" ]; then fail "CA4 viñeta vacía: '$b'"; bad=1; continue; fi
  if printf '%s' "$lower" | grep -Eq '(^|[^[:alpha:]])(todo|tbd|fixme|xxx)([^[:alpha:]]|$)|lorem ipsum|\.\.\.|…'; then
    fail "CA4 viñeta con marcador de relleno: '$b'"; bad=1; continue
  fi
  # Texto descriptivo: al menos tres palabras con letras.
  words=$(printf '%s' "$text" | grep -Eo '[[:alpha:]áéíóúñüÁÉÍÓÚÑÜ]{2,}' | wc -l)
  if [ "$words" -lt 3 ]; then fail "CA4 viñeta poco descriptiva: '$b'"; bad=1; fi
done
if [ "${#BULLETS[@]}" -gt 0 ] && [ "$bad" -eq 0 ]; then pass "CA4 todas las viñetas tienen texto descriptivo"
elif [ "${#BULLETS[@]}" -eq 0 ]; then fail "CA4 no hay viñetas que revisar"; fi

# CA5: estructura Markdown: H1 "Notas" seguido (tras líneas vacías) de una lista.
if [ "$first_idx" -ge 0 ] && [ "$first" = "# Notas" ]; then
  nxt=""
  for ((j=first_idx+1; j<${#LINES[@]}; j++)); do
    if [ -n "${LINES[$j]//[[:space:]]/}" ]; then nxt="${LINES[$j]}"; break; fi
  done
  h1_count=0
  for l in "${LINES[@]}"; do case "$l" in "# "*) h1_count=$((h1_count+1)) ;; esac; done
  case "$nxt" in
    "- "*|"* "*)
      if [ "$h1_count" -eq 1 ]; then pass "CA5 H1 'Notas' seguido de una lista con viñetas"
      else fail "CA5 hay $h1_count encabezados H1, se esperaba 1"; fi ;;
    *) fail "CA5 tras el H1 viene '$nxt', se esperaba una viñeta" ;;
  esac
else
  fail "CA5 no hay encabezado H1 'Notas' al inicio"
fi

[ "$fails" -eq 0 ]
