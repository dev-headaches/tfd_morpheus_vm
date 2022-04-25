if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
[ServerCertificateValidationCallback]::Ignore()

$accessToken = "${nbmorph_api_key}"
$serverUrl = "https://${morph_url}"
$servername = "${servername}"
$serverApiKey = ((curl "$serverUrl/api/servers?name=$servername" -UseBasicParsing -H @{ "Authorization" = "BEARER $accessToken"}).content | ConvertFrom-Json).servers.apiKey

Set-Location $${env:commonprogramfiles(x86)}
$serviceName = "Morpheus Windows Agent"
Start-Transcript -Path 	"$${env:commonprogramfiles(x86)}\morpheus_install_script.log" -Append -Force
$msiName = "MorpheusAgentSetup.msi"
try {
	$hasDotNet45 = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'  -Name Release).Release | ForEach-Object { $_ -ge 379893 }
  if($hasDotNet45 -eq $True) {
	$msiName = "MorpheusAgentSetup-4_5.msi"
  }	
} catch {
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
try {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12	
} 
Catch {
}
Write-Output "Downloading..."
Write-Output "${nbmorph_api_key}"
Write-Output "$accessToken"
Write-Output "Server API Key: $serverApiKey"
$dS=$false
$dAt=0
Do {
	try {
		$df = "$${env:commonprogramfiles(x86)}\MorpheusAgentSetup.msi"
		$ws = (New-Object System.Net.WebClient).OpenRead("https://${morph_url}//msi/morpheus-agent/$msiName")
		$file = [System.IO.File]::OpenWrite($df)
		$bR=1
		$buf = [array]::createInstance([byte],1000)
		Do {
			$bR = $ws.Read($buf,0,$buf.Length)
			$file.Write($buf,0,$bR)
		}
		While ($bR -gt 0)
		Write-Output "Agent Downloaded..."
		$ws.Flush()
		$file.Flush()
		$ws.Close()
		$file.Close()
		$dS=$true
		break
	}
	Catch [Exception] {
		Write-Output $_.Exception|format-list -force
		$dAt++
		Start-Sleep -s 10
	}	
} While ( $dAt -lt 3 )
if ($dS -ne $true) {exit 1}
if(Get-Service $serviceName -ErrorAction SilentlyContinue) {
 Stop-Service -displayname $serviceName -ErrorAction SilentlyContinue
 Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
 Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
 Start-Sleep -s 5
 try {
 	$serviceId = (get-wmiobject Win32_Product -Filter "Name = 'Morpheus Windows Agent'" | Format-Wide -Property IdentifyingNumber | Out-String).Trim()	
 } 
 Catch {
 	$serviceId = $df
 }
 
 cmd.exe /c "msiexec /x $serviceId /q /passive"
}
Write-Output "Running Msi"
$MSIArguments= @(
"/i"
"MorpheusAgentSetup.msi"
"/qn"
"/norestart"
"/l*v"
"morpheus_install.log"
"apiKey=`"$serverApiKey`""
"host=`"https://${morph_url}/`""
"username=`".\LocalSystem`""
"vmMode=`"true`"" 
"verifySsl=`"false`""
"logLevel=`"3`""
)
$installResults = Start-Process msiexec.exe -Verb runAs -Wait -ArgumentList $MSIArguments
$a = 0
$f = 0
Do {
	try {
		Get-Service $serviceName -ea silentlycontinue -ErrorVariable err
		if([string]::isNullOrEmpty($err)) {
			$f = 1
			Break	
		} else {
			start-sleep -s 10
			$a++
		}
	}
	Catch {
		start-sleep -s 10
		$a++
	}
}
While ($a -ne 6)
Set-Service $serviceName -startuptype "automatic"
$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
& sc.exe failure "$serviceName" reset= 30 actions= restart/30000/restart/30000/restart/4000
if ($service -And $service.State -ne "Running") {Restart-Service -displayname $serviceName}