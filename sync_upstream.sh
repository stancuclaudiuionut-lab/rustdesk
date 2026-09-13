#!/usr/bin/env bash
set -e

echo "=== 1. Preluare modificări din depozitul oficial RustDesk (upstream) ==="
git fetch upstream

echo "=== 2. Îmbinare modificări oficiale în ramura ta master ==="
git merge upstream/master --no-edit || {
    echo "⚠️ Conflicte detectate la îmbinare. Rezolvă conflictele și rulează git commit."
    exit 1
}

echo "=== 3. Actualizare sub-module ==="
git submodule update --init --recursive

echo "=== 4. Trimitere cod actualizat pe GitHub-ul tău (origin) ==="
git push origin master

echo "✅ Gata! Depozitul tău este acum 100% sincronizat cu versiunea oficială RustDesk."
