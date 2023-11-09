[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')       | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework')      | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')          | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null

#GUI stuff:
#Edit this to choose an icon for the systray 
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("Filepath of the icon you want to use")  
################################################################################################################################"
# ACTIONS FROM THE SYSTRAY
################################################################################################################################"

# ----------------------------------------------------
# Part - Add the systray menu
# ----------------------------------------------------        

$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "StatusLight"
$Main_Tool_Icon.Icon = $icon
$Main_Tool_Icon.Visible = $true

$Menu_Start = New-Object System.Windows.Forms.MenuItem
$Menu_Start.Enabled = $false
$Menu_Start.Text = "Auto"

$Menu_Stop = New-Object System.Windows.Forms.MenuItem
$Menu_Stop.Enabled = $true
$Menu_Stop.Text = "Stop"

$Menu_Busy = New-Object System.Windows.Forms.MenuItem
$Menu_Busy.Enabled = $true
$Menu_Busy.Text = "Set Busy"

$Menu_Free = New-Object System.Windows.Forms.MenuItem
$Menu_Free.Enabled = $true
$Menu_Free.Text = "Set Free"

$Menu_Off = New-Object System.Windows.Forms.MenuItem
$Menu_Off.Enabled = $true
$Menu_Off.Text = "Off"

$Menu_Exit = New-Object System.Windows.Forms.MenuItem
$Menu_Exit.Text = "Exit"

#add items to context menu

$contextmenu = New-Object System.Windows.Forms.ContextMenu
$Main_Tool_Icon.ContextMenu = $contextmenu
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Start)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Stop)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Busy)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Free)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Off)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)


function Kill-Tree {
    Param([int]$ppid)
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid } | ForEach-Object { Kill-Tree $_.ProcessId }
    Stop-Process -Id $ppid
}

$Main_Tool_Icon.Add_Click({                    
    If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
        $Main_Tool_Icon.GetType().GetMethod("ShowContextMenu",[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic).Invoke($Main_Tool_Icon,$null)
    }
})

# When Start is clicked, start job and get its pid
$Menu_Start.add_Click({
    $Menu_Stop.Enabled = $true
    $Menu_Start.Enabled = $false
    $Menu_Free.Enabled = $false
    $Menu_Busy.Enabled = $false
    $Menu_Off.Enabled = $true

    Stop-Job -Name "job"
    Start-Job -ScriptBlock $runloop -Name "job"
    [System.GC]::Collect()
 })

 

 # When Stop is clicked, kill job
$Menu_Stop.add_Click({
    $Menu_Stop.Enabled = $false
    $Menu_Start.Enabled = $true
    $Menu_Free.Enabled = $false
    $Menu_Busy.Enabled = $true
    $Menu_Off.Enabled = $true

    Stop-Job -Name "job"
    SetAvailable
 })

 $Menu_Free.add_Click({
    $Menu_Stop.Enabled = $false
    $Menu_Start.Enabled = $true
    $Menu_Free.Enabled = $false
    $Menu_Busy.Enabled = $true
    $Menu_Off.Enabled = $true

    SetAvailable
 })

  $Menu_Busy.add_Click({
    $Menu_Stop.Enabled = $false
    $Menu_Start.Enabled = $true
    $Menu_Free.Enabled = $true
    $Menu_Busy.Enabled = $false
    $Menu_Off.Enabled = $true

    SetBusy
 })

 $Menu_Off.add_Click({
    $Menu_Stop.Enabled = $false
    $Menu_Start.Enabled = $true
    $Menu_Free.Enabled = $true
    $Menu_Busy.Enabled = $true
    $Menu_Off.Enabled = $false

    Stop-Job -Name "job"
    SetOff
 })

 

# When Exit is clicked, close everything and kill the process
$Menu_Exit.add_Click({
    $Main_Tool_Icon.Visible = $false
    $window.Close()
    Stop-Job -Name "job"
    SetOff
    Stop-Process $pid
 })

 # Edit these functions with the location of your control scripts and the network interface you actually want to use
 function SetOff {
$currentIP = Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4| Select IPAddress -ExpandProperty IPAddress
$currentIP = $currentIP.ToString()
$OffScript = "Filepath of Off script"
python.exe $OffScript $currentIP
}


 function SetAvailable{

$currentIP = Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4| Select IPAddress -ExpandProperty IPAddress
$currentIP = $currentIP.ToString()
$availableScript = "Filepath of Available script"
python.exe $availableScript $currentIP
}

function SetBusy{

$currentIP = Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4| Select IPAddress -ExpandProperty IPAddress
$currentIP = $currentIP.ToString()
$busyScript = "Filepath of Busy script"
python.exe $busyScript $currentIP
}

#Edit this run loop with the filepaths and the network interface you actually want to use
 $runloop = {
$currentIP = Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4| Select IPAddress -ExpandProperty IPAddress
$currentIP = $currentIP.ToString()
$availableScript = "Filepath of available script"
$busyScript = "Filepath of busy script"
$currentStatus = "available"
python.exe $availableScript $currentIP

#loop that actually does stuff
while($true){
    #Get Zoom status or sleep if not running
    try{
        #get current status of zoom
        $zoomStatus = (Get-NetUDPEndpoint -OwningProcess (gps Zoom).Id -EA 0|measure).Count
        #check if status is anything other than the "not in meeting" statuses
        if($zoomStatus -ne 1 -and $zoomStatus -ne 0){
            #Write-Output "Zoom is running"
            #check if current status is available and only change if needed
            if($currentStatus -eq "available"){
                #set status to busy and sleep for 5 minutes
                $currentStatus = "busy"
                python.exe $busyScript $currentIP
                #Write-Output "set to busy and waiting 3 minutes"
                Start-Sleep 180
            }
        }
            #if status is "not in a meeting"
        else{
            #Write-Output "Zoom is not running"
            #check if status is already set to available or not
            if($currentStatus -eq "busy"){
                $currentStatus = "available"
                python.exe $availableScript $currentIP
                #Write-Output "Set to available"
            }
        }
    }
    #catch if zoom is not running and set status to 0
    catch{
        $zoomStatus = 0
        if($currentStatus -eq "busy"){
        $currentStatus = "available"
        python.exe $availableScript $currentIP
        }
        #Write-Output "Zoom not running - set to available"
    }
    #sleep for one minute before checking again
    #Write-Output "Currently: $currentStatus. waiting one minute"
    Start-Sleep 60
}
}

Start-Job -ScriptBlock $runloop -Name "job"

$Menu_Stop.Enabled = $true
$Menu_Start.Enabled = $false
$Menu_Free.Enabled = $false
$Menu_Busy.Enabled = $false
$Menu_Off.Enabled = $true

 # Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()

# Create an application context for it to all run within.
# This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)