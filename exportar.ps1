# Exporta todos os workflows do n8n (container "n8n") para a pasta workflows/

docker exec -u node n8n sh -c "rm -rf /tmp/export && mkdir -p /tmp/export && n8n export:workflow --all --separate --pretty --output=/tmp/export/"

if (Test-Path ./tmp-export) { Remove-Item ./tmp-export -Recurse -Force }
docker cp n8n:/tmp/export/. ./tmp-export

New-Item -ItemType Directory -Force -Path ./workflows | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false

Get-ChildItem ./tmp-export/*.json | ForEach-Object {
    $wf = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($wf.isArchived) { return }   # pula workflows arquivados

    # Remove metadados pessoais/internos (e-mail, IDs de projeto e usuário)
    $wf.PSObject.Properties.Remove('shared')

    $nome = $wf.name.ToLower()
    $nome = $nome.Normalize([Text.NormalizationForm]::FormD) -replace '\p{Mn}', ''
    $nome = ($nome -replace '[^a-z0-9]+', '-').Trim('-')

    $json = $wf | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) "workflows/$nome.json"), $json, $utf8)
    Write-Host "Exportado: $nome.json"
}

Remove-Item ./tmp-export -Recurse -Force