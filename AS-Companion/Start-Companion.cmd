@echo off
title AS Companion
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Companion.ps1" %*
