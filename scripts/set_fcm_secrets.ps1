# Sets Supabase Edge Function secrets for FCM push (app-closed widget sync).
#
# Prerequisites:
#   1. supabase CLI: scoop install supabase  OR  npm i -g supabase
#   2. supabase login
#   3. supabase link --project-ref shvmqegxbuoszpoizdut
#   4. Firebase service account JSON (see docs/PUSH_WHEN_APP_CLOSED.md)
#
# Usage:
#   .\scripts\set_fcm_secrets.ps1 -ServiceAccountPath "C:\path\to\firebase-adminsdk.json"

param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceAccountPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ServiceAccountPath)) {
    Write-Error "File not found: $ServiceAccountPath"
}

$json = Get-Content $ServiceAccountPath -Raw | ConvertFrom-Json

$projectId = $json.project_id
$clientEmail = $json.client_email
$privateKey = $json.private_key

if (-not $projectId -or -not $clientEmail -or -not $privateKey) {
    Write-Error "JSON must contain project_id, client_email, and private_key"
}

Write-Host "Setting FCM secrets for project: $projectId"
Write-Host "Email: $clientEmail"

# Escape newlines for Supabase CLI (private key must keep line breaks as \n)
$keyOneLine = $privateKey -replace "`r`n", "\n" -replace "`n", "\n"

supabase secrets set "FCM_PROJECT_ID=$projectId"
supabase secrets set "FCM_CLIENT_EMAIL=$clientEmail"
supabase secrets set "FCM_PRIVATE_KEY=$keyOneLine"

Write-Host ""
Write-Host "Done. Edit a shared note on Device A and check Edge Function logs for ok (not skip push)."
Write-Host "Dashboard: https://supabase.com/dashboard/project/shvmqegxbuoszpoizdut/functions/send-shared-note-push/logs"
