<#
.SYNOPSIS
    Connect to TP-Link Kasa and change Smart Power Switch on/off
.DESCRIPTION
    Connects to TP-Link Kasa and either turns on or off power switch.
.EXAMPLE
    .\Update-TPLinkSwitch.ps1 -Name "Computer Monitor" -Status Off
    - Turns off switch named "Computer Monitor"
.PARAMETER Name
    Name of TP-Link device to connect to. This is the friendly name from the Kasa app.
.Parameter Status
    Can either be ON or OFF. Either turns the selected device on or off.
.NOTES
    File Name: Update-TPLinkSwitch.ps1
    Author: Michael Busse - michael.busse@gmail.com
    Version: 1.0 - October 2018

# Comment-based Help tags were introduced in PS 2.0
#requires -version 2
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][ValidateSet('On','Off')][string]$Status
)

Begin{
}

Process{

    # Set Username, Password and uuID here. Generate a uuIDv4 from here: https://www.uuidgenerator.net/version4 
    $UserName = 'CHANGE_TO_TPLINK_CLOUD_USERNAME'
    $Password = 'CHANGE_TO_CLOUD_PASSWORD'
    $uuID = 'Generate_UUID_And_Insert_Here'
    $Uri = 'https://wap.tplinkcloud.com'

    #Generate JSON body to get token
    $Params = @{
        "appType" = "Kasa_Android"
        "cloudUserName" = $UserName
        "cloudPassword" = $Password
        "terminalUUID" = $uuID
    }

    $Post = @{
        "method" = "login"
        "params" = $Params
    }
    $postJson = ConvertTo-Json -InputObject $Post

    # Invoke WebRequest to TP-Link cloud service and get result
    $auth = Invoke-WebRequest -Uri $Uri -Method Post -Body $postJson -ContentType "application/json" 
    
    # Extract token from result
    $token =  ($auth.Content | ConvertFrom-Json).result.token

    
    # Get device list
    $deviceURI = $Uri + '?token=' + $token

    $getDeviceListParams = @{
        'method' = "getDeviceList"
    }

    $getDeviceListParamsJson = $getDeviceListParams | ConvertTo-Json

    $deviceList = Invoke-WebRequest -Uri $deviceURI -Method Post -Body $getDeviceListParamsJson -ContentType "application/json" 
    $Device = ($deviceList.Content | ConvertFrom-Json).result.devicelist | where {$_.alias -match $Name}

    # If device matching $Name specified.. Then perform on/off action..
    If ($Device){
        
        # On/Off hashtable
        $state = @{
            'On' = '1'
            'Off' = '0'
        }

        # Build JSON request.. the lazy way. Because we can't join that many hastables to a usable json object..
        [string]$jsonRequest = '{"method":"passthrough", "params": {"deviceId": "' + $Device.deviceId + '", "requestData": "{\"system\":{\"set_relay_state\":{\"state\":' + $state.$status + '}}}" }}'

        # Turn plug on/off
        Invoke-WebRequest -Uri $deviceURI -Method Post -Body $jsonRequest -ContentType "application/json"
        
    }
    Else {
        '"' + $Name + '" not found! Use specific name created for device in Kasa app! The following devices were found, specify the correct one with the -Name parameter:' | Write-Output
        ($deviceList.Content | ConvertFrom-Json).result.devicelist.alias
        Exit 1
    }

}

End {
}