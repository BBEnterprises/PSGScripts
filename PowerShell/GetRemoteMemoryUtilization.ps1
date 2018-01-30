function getMemUsers {
    param($computer);

    $table = @();

    Get-Process |         
        Group-Object -Property ProcessName |
        %{
            $process = $_;
            $table += New-Object psobject -Property @{
                Name       = $process.Name
                WorkingSet = ($process.Group | Measure-Object WorkingSet -Sum).Sum / 1KB
            };
            
            #Write-Host ("{0}`t{1}" -f $_.Name, ($_.Group | Measure-Object WorkingSet -Sum).Sum);
        }

        

        
        $table | Sort-Object -Property WorkingSet  -Descending |  
        Format-Table Name, WorkingSet;
}

$computers = @();

getMemUsers 127.0.0.1;

