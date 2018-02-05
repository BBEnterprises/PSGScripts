function Find-ChildProcess {
    param($id, $depth);

    $children = Get-WmiObject -Class Win32_Process -Filter "ParentProcessID=$id" |
    Select-Object -Property ProcessName, ProcessID;

    if ($children) {
        $depth += 1;
        $formatStr = $("`t" * $depth) + "{0}`t{1}";
        foreach ($child in $children) {
            if ($globalPidList -contains $child.ProcessId) { #Skip the process if we've already evaluated it
                continue;
            }
            Write-Host ($formatStr -f $child.ProcessName, $child.ProcessID);
            $global:globalPidList += $child.ProcessId;
            Find-ChildProcess $child.ProcessID $depth;
        }
    }
}

function getParentProcess {
    param($proc);

    $parentPid = Get-WmiObject -Class Win32_Process -filter ("ProcessID=" + $proc.Id) | select ParentProcessID;

    return $parentPid.ParentProcessId;
}

function getRootProcs {
    param($procName);
    $procs = @();
    $pids  = @();
    $depth = 0;


    if ($procName) {
        Get-Process -Name $procName | %{
            $procs += ,$_;
            $pids  += ,$_.Id;
        }
    }
    else {
        Get-Process | %{
            $procs += ,$_;
            $pids  += ,$_.Id;
        }
    }
   
    foreach ($proc in $procs) {
        if ($pids -notcontains (getParentProcess $proc) ) { #If the proc's parent pid isn't in our array of PIDs, it must be a 'root' level process and not a child of the process we're looking for. 
            $global:globalPidList += $proc.Id;
            Write-Host (("{0}`t{1}") -f $proc.Name, $proc.Id)
            Find-ChildProcess $proc.Id $depth;
        }
    }
}

#######################
#Main Block Below Here#
#######################
$procName      = 'chrome';
$globalPidList = @(); #Global list of PIDs, we'll use this to make sure we don't evaluate any given process twice; prevents infinite recursion problems when a PID is its own grandparent #JustWindowsThings

getRootProcs $procName;
