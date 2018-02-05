#$webRequest = [Net.WebRequest]::Create("https://srv06u03118.pdx.supervalu.com:58443/Escript")
$webRequest = [Net.WebRequest]::Create("https://167.234.1.45:50025/Escript")
try { $webRequest.GetResponse() } catch {}
$cert = $webRequest.ServicePoint.Certificate
$bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
set-content -value $bytes -encoding byte -path "$pwd\superv.Com.cer"