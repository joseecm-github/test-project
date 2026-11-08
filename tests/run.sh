#!/usr/bin/env bash
# Ejecutor de tests: corre cada tests/test_*.sh; sale con 0 si todos pasan, 1 si alguno falla.
set -u
cd "$(dirname "$0")/.."
status=0
for t in tests/test_*.sh; do
  [ -e "$t" ] || continue
  echo "== $t"
  if ! bash "$t"; then status=1; fi
done
if [ "$status" -eq 0 ]; then echo "TODOS LOS TESTS PASAN"; else echo "HAY TESTS QUE FALLAN"; fi
exit "$status"
