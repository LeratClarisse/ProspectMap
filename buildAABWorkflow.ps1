$ErrorActionPreference = "Stop"

Write-Output "Clean Flutter..."
flutter clean

Write-Output "`nPub Get..."
flutter pub get

Write-Output "`nAnalyze..."
flutter analyze

Write-Output "`nBuild AAB..."
flutter build appbundle

Read-Host -Prompt "`nPress Enter to exit"
