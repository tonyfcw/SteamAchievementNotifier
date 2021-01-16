﻿#STEAM ACHIEVEMENT NOTIFIER
#All scripts and content created by: o Jackson 1 o (https://github.com/Jackson0ne).
#Updated: 14/01/2021 (22:00)

#PLEASE ENSURE YOU HAVE RUN "SteamAchievementNotifier-SETUP.ps1" BEFORE STARTING THIS SCRIPT!

#Stops errors when no game is running.
$ErrorActionPreference = "SilentlyContinue";

#Gets OS Drive Letter.
$drive = ((Get-Item $PSScriptRoot).PSDrive.Name);

#Checks for API Key and Steam64ID - Prompt in console if it doesn't exist.
$apikey = (Get-Content "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\apikey.txt");
$steam64id = (Get-Content "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\steam64id.txt");

if ($apikey -eq $null) {
    cls;
    $apiprompt = Read-Host "Paste your API Key and press Enter (Get API Key here: https://steamcommunity.com/login/home/?goto=%2Fdev%2Fapikey)";
    $apiprompt > ${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\apikey.txt;
    cls;
    }

if ($steam64id -eq $null) {
    cls;
    $steam64prompt = Read-Host "Paste your Steam64ID and press Enter (Get Steam64ID here: https://steamid.io/lookup)";
    $steam64prompt > ${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\steam64id.txt;
    cls;
    }

#If Steam isn't already running, start it.
$steamproc = Get-Process steam;
if ($steamproc -eq $null) {
    Start-Process -FilePath "${drive}:\Program Files (x86)\Steam\steam.exe";
}

#Stores current static game stats in AppData\Local\SteamAchievementNotifier\Store to compare with later.
$currentgame = Invoke-RestMethod "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$apikey&steamids=$steam64ID";
$appid = $currentgame.response.players.gameid;
$gamename = $currentgame.response.players.gameextrainfo;

if ($appid -eq $null) {
    cls;
    Write-Host "Steam Achievement Notifier: ";
    Write-Host "No Steam game detected." -ForegroundColor Red;
    sleep 2;
    &"$PSScriptRoot\SteamAchievementNotifier.ps1";
    exit;
} else {
    cls;
    Write-Host "Steam Achievement Notifier: ";
    Write-Host "Now tracking achievements for ${gamename}." -ForegroundColor Cyan;
    sleep 5;
    cls;
    }

$getcheev = Invoke-RestMethod "http://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=$appid&key=$apikey&steamid=$steam64ID" | ConvertTo-Json -Compress -Depth 100 | Out-File "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\cheev.json";
$cheev = (Get-Content "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\cheev.json" | ConvertFrom-Json);

$getdesc = Invoke-RestMethod "http://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v0002/?key=$apikey&appid=$appid&l=english&format=json" | ConvertTo-Json -Compress -Depth 100 | Out-File "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\desc.json";
$desc = (Get-Content "${drive}:\Users\$env:username\AppData\Local\SteamAchievementNotifier\Store\desc.json" | ConvertFrom-Json);

#Loops to compare stored stats in AppData\Local\SteamAchievementNotifier\Store to live API stats.
do {
    
    $appcheck = Invoke-RestMethod "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$apikey&steamids=$steam64ID";
    Clear-Variable -Name appid;
    Set-Variable -Name appid -Value $appcheck.response.players.gameid;
    if ($appid -eq $null) {
        cls;
        Write-Host "Steam Achievement Notifier: ";
        Write-Host "No Steam game detected." -ForegroundColor Red;
        sleep 2;
        &"$PSScriptRoot\SteamAchievementNotifier.ps1";
        exit;
        }

    $random = Get-Random -Maximum 9999999;

    $currentCheev = Invoke-RestMethod "http://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=$appid&key=$apikey&steamid=${steam64ID}?__random=$random";

    for ($i = 0; $i -lt $desc.game.availableGameStats.achievements.Length; $i++) {
        $gameID = $currentCheev.playerstats.gameName + ": " + $desc.game.availableGameStats.achievements[$i].displayName;
        $currentStatus = $currentCheev.playerstats.achievements[$i].achieved;
        $currentDesc = $desc.game.availableGameStats.achievements[$i].description;
        $currentIcon = $desc.game.availableGameStats.achievements[$i].icon;
        $currentName = $desc.game.availableGameStats.achievements[$i].displayName;
        $cheevBoolean = if ($currentStatus -eq 1) {"Achieved"} else {"Locked"};

    if ($currentStatus -ne $cheev.playerstats.achievements[$i].achieved) {
        New-BurntToastNotification -AppLogo $currentIcon -Sound IM -Text "$gameID", "$currentDesc";
        Write-Host Achievement ($i+1) """$currentName"" | ($currentDesc) |" $cheevBoolean;
        $cheev.playerstats.achievements[$i].achieved = $currentStatus;
        }
    }

    sleep 1;

} while ($true);