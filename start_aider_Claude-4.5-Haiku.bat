@echo off
title Aider Agent - Claude 3.5 Sonnet
echo ===================================================
echo Starte Aider mit Claude 3.5 Sonnet...
echo ===================================================

:: Hier starten wir Aider mit Claude und deaktivieren die Auto-Commits
aider --model claude-haiku-4-5 --no-auto-commits

:: Falls Aider abstürzt oder du es beendest, bleibt das Fenster dank pause offen, damit du Fehler lesen kannst
pause