class pool {
    [string] $computer;
    [string] $name;
    [string] $procID;
    [decimal]$NPMk;
    [decimal]$PMm;
    [decimal]$WSm;
    [decimal]$VMm;
    [decimal]$PRIVm;
    [decimal]$CPUs;

    pool ([string]$compName, [string]$poolName, [string]$poolPID) {
        $this.computer = $compName;
        $this.name     = $poolName;
        $this.procID   = $poolPID;

        $proc = Invoke-Command -ComputerName $this.computer -ArgumentList($this.procID) -ScriptBlock {
            param($procID);
            Get-Process -PID $procID;
        }

        $this.NPMk  = $proc.NPM / 1KB;
        $this.PMm   = $proc.PM  / 1MB;
        $this.WSm   = $proc.WS  / 1MB;
        $this.VMm   = $proc.VM  / 1MB;
        $this.PRIVm = $proc.PrivateMemorySize / 1MB;
        $this.CPUs  = $proc.CPU;
    }
}

function getPools {
    param(
        [ref]   $pools,
        [string]$computer
    );

    Get-WmiObject -ComputerName $computer -Namespace 'root\WebAdministration' -Class 'WorkerProcess' | %{
        $pools.Value += [pool]::new($computer, $_.AppPoolName, $_.ProcessId);
    }
}

function writeReport {
    param(
         [array]    $pools
        ,[hashtable]$cfgParams
    );

    [DateTime]$dateTime = [DateTime]::Now;
    [string]$format     = '"{0}","{1}","{2}","{3}","{4}","{5}","{6}","{7}","{8}","{9}"';
    #[string]$header     = $format -f 'DateTime', 'Computer', 'Name', 'PID', 'NPMk', 'PMm', 'WSm', 'VMm', 'PRIVm', 'CPUs';


    #$header | Out-File -FilePath $cfgParams.logFile -Encoding ascii -Append;

    foreach ($pool in $pools) {
        [string]$record = $format -f `
            $dateTime, `
            $pool.Computer, `
            $pool.Name, `
            $pool.procID, `
            $pool.NPMk, `
            $pool.Pmm, `
            $pool.WSm, `
            $pool.VMm, `
            $pool.PRIVm, `
            $pool.CPUs;

        $record | Out-File -FilePath $cfgParams.logFile -Encoding ascii -Append;
    }

}

############
#Main Block#
############
[array]    $pools     = @();
[string]   $computer  = 'hss-prod-web01';
[hashtable]$cfgParams = @{
    'logFile' = 'D:\ScriptLogs\poolMemMon.csv';
};


getPools    ([ref]$pools) $computer;
writeReport $pools $cfgParams;