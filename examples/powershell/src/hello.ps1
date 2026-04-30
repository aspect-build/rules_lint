function Get-Greeting {
    param([string]$Name = "World")
    return "Hello, $Name!"
}

Write-Output (Get-Greeting)
