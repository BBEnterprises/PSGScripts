﻿function getMemUsers {
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
        }
        
        $table | Sort-Object -Property WorkingSet  -Descending |  
        Format-Table Name, WorkingSet;
}

$computers = @();

foreach ($computer in $computers) {
    getMemUsers $computer;
}