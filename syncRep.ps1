# Ставим кодировку
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Папка, где всё будет вариться
$WorkDir = "$HOME\git_sync_temp"
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir }

Write-Host "--- СКРИПТ СИНХРОНИЗАЦИИ РЕПОЗИТОРИЕВ ---" -ForegroundColor Cyan

# 1. Спрашиваем ссылки (или можно вписать свои прямо тут)
$SourceUrl = Read-Host "Введите URL репозитория преподавателя"
$MyUrl = Read-Host "Введите URL вашего репозитория"

# Вырезаем названия папок из ссылок
$SourceName = ($SourceUrl -split '/')[-1].Replace(".git","")
$MyName = ($MyUrl -split '/')[-1].Replace(".git","")

$SourcePath = Join-Path $WorkDir $SourceName
$MyPath = Join-Path $WorkDir $MyName

# Функция подготовки: если папка есть — пуллим, если нет — клоним
function Get-Repo($Url, $Path) {
    if (Test-Path "$Path\.git") {
        Write-Host "-> Обновляю существующую папку: $Path"
        Set-Location $Path
        git pull
    } else {
        Write-Host "-> Клонирую новый репозиторий: $Path"
        git clone $Url $Path
    }
}

Write-Host "`n[ШАГ 1] Подготовка локальных копий..." -ForegroundColor Yellow
Get-Repo $SourceUrl $SourcePath
Get-Repo $MyUrl $MyPath

# 2. Зеркалим файлы (ТЗ требует замену файлов и ведение структуры)
Write-Host "`n[ШАГ 2] Копирование файлов (кроме .git)..." -ForegroundColor Yellow
# /MIR - зеркалит содержимое, /XD - игнорит папку гита, чтобы не сбить настройки
robocopy $SourcePath $MyPath /MIR /XD .git /R:1 /W:1 /NP /NJH /NJS

# 3. Пушим результат
Write-Host "`n[ШАГ 3] Проверка изменений и Push..." -ForegroundColor Yellow
Set-Location $MyPath
git add .

# Проверяем, есть ли что пушить, чтобы не плодить пустые коммиты
if (git status --porcelain) {
    $Time = Get-Date -Format "dd.MM.yyyy HH:mm"
    git commit -m "Синхронизация с исходником | $Time"
    git push
    Write-Host "Готово! Все изменения улетели на сервер." -ForegroundColor Green
} else {
    Write-Host "Изменений не найдено, пушить нечего." -ForegroundColor Gray
}

Write-Host "`nСинхронизация завершена. Нажми любую клавишу..."
$null = [Console]::ReadKey()
