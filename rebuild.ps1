# Aquarium Smart - Rebuild Script
# Run this if you have connection issues

Write-Host "🧹 Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "🔍 Analyzing code..." -ForegroundColor Yellow
flutter analyze

Write-Host ""
Write-Host "✅ Project cleaned and ready!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the app:" -ForegroundColor Cyan
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""
Write-Host "To build release APK:" -ForegroundColor Cyan
Write-Host "  flutter build apk --release" -ForegroundColor White
Write-Host "  flutter install" -ForegroundColor White
