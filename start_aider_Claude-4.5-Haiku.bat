@echo off
title Aider Agent - claude-haiku-4-5
echo ===================================================
echo Starte Aider mit claude-haiku-4-5...
echo ===================================================

:: Hier starten wir Aider mit Claude und deaktivieren die Auto-Commits
aider --model claude-haiku-4-5 --no-auto-commits

:: Falls Aider abstürzt oder du es beendest, bleibt das Fenster dank pause offen, damit du Fehler lesen kannst
pause
