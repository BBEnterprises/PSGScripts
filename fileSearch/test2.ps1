
$MainPath = "e:\FileSearching\queue"

Get-ChildItem $MainPath *.dat |
ForEach-Object {

	$InputParams = Get-Content $_.FullName

#root location
#search string
#sub dir wildcard
#email to inform
#search full files?
#location to move files to [optional]

	$Path = $InputParams[0]
	$Text = $InputParams[1]
	$FolderWildcard = $InputParams[2]
	$PathArray = @()
	$Results = $InputParams[3]
	$FullFileSearch = $InputParams[4]

	if( !$Text ) {
		if( $InputParams[3] )
		{
			Send-MailMessage -From "system@psgconsults.com" -To $InputParams[3] -Subject "File Search Results" -Body "You are missing the search text in this job" -SmtpServer "psg-msexch01.psgconsults.com"
		}

		Remove-Item $_.FullName

		Exit
	}

	Get-ChildItem $Path | 
		Where-Object { $_.Attributes -eq "Directory" -and $_.name -like $FolderWildcard} | 
			ForEach-Object {
				Get-ChildItem $_.FullName | Where-Object { $_.Attributes -ne "Directory" } | 
					ForEach-Object {
						if ( $FullFileSearch -eq "1" )
						{
							$content = Get-Content $_.FullName
						}
						else
						{
							$content = ([char[]](Get-Content $_.FullName -Encoding byte -TotalCount 10000)) -join ''
						}

						If ( $content | Select-String -Pattern $Text) {
							$PathArray += $_.FullName
						}
					}
			}



	if ( $InputParams.Count -ge 6 ) {
		ForEach-Object { $PathArray
			Move-item -path $PathArray -destination $InputParams[5]
		}
	}

	if ( $InputParams.Count -ge 4 ) {

		if( $PathArray.Count -gt 0 )
		{
			if( $InputParams.Count -ge 6 )
			{
				$Body = ($PathArray -join "   --->   " + $InputParams[5] + "`n") + "   --->   " + $InputParams[5]
			}
			else
			{
				$Body = $PathArray -join "`n"
			}
		}
		else
		{
			$Body = "Nothing Found In: " + $Path + "\\" + $FolderWildcard
		}

		Send-MailMessage -From "system@psgconsults.com" -To $InputParams[3] -Subject "File Search Results For: $Text" -Body $Body -SmtpServer "172.31.0.15"
	}

	(get-date -format "yyyyMMdd h:mm") + " | " + ($InputParams -join ",") | out-file -filepath E:\FileSearching\log.txt -append

	#finally, remove the dat file
	Remove-Item $_.FullName
}