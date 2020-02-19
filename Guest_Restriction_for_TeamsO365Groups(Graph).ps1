#Keep tenant id, client id, client secret in info.json file run the script 
#this script will take the input from current folder and create output in current folder  (keep the info.json file in same folder where you are running the script)
#this script will change the All Teams groups AllowToAddGuests value to False

#creating token id
$input = get-content info.json | ConvertFrom-Json
$Client_Secret = $input.Client_Secret
$client_Id = $input.client_Id
$Tenantid = $input.Tenantid

#Grant Adminconsent 
$Grant= 'https://login.microsoftonline.com/common/adminconsent?client_id='
$admin = '&state=12345&redirect_uri=https://localhost:1234'
$Grantadmin = $Grant + $client_Id + $admin

start $Grantadmin
write-host "login with your tenant login detials to proceed further"

$proceed = Read-host " Press Y to continue "
if ($proceed -eq 'Y')
{
    write-host "Creating Access_Token"          
              $ReqTokenBody = @{
         Grant_Type    =  "client_credentials"
        client_Id     = "$client_Id"
        Client_Secret = "$Client_Secret"
        Scope         = "https://graph.microsoft.com/.default"
    } 

    $loginurl = "https://login.microsoftonline.com/" + "$Tenantid" + "/oauth2/v2.0/token"
    $Token = Invoke-RestMethod -Uri "$loginurl" -Method POST -Body $ReqTokenBody -ContentType "application/x-www-form-urlencoded"

    $Header = @{
        Authorization = "$($token.token_type) $($token.access_token)"
    }
    
    
    #Get Team details
        write-host "Getting Team details..."
         $getTeams = "https://graph.microsoft.com/beta/groups?filter=resourceProvisioningOptions/Any(x:x eq 'Team')" 
         $Team = Invoke-RestMethod -Headers $Header -Uri $getTeams -Method get -ContentType 'application/json'
         #$Team.value
 
 do{  
foreach($value in $Team.value){
                        $id = $value.id
                        $displayName = $value.displayName
                        #Get group settings
                        $settingsuri = "https://graph.microsoft.com/v1.0/groups/" + "$id" + "/settings"
                        $groupsettings = Invoke-RestMethod -Headers $Header -Uri $settingsuri -Method get -ContentType 'application/json'
                        $Groupvalue = $groupsettings.value
        $body = '{
  "displayName": "Group.Unified.Guest",
  "templateId": "08d542b9-071f-4e16-94b0-74abb372e3d9",
  "values": [
    {
      "name": "CustomBlockedWordsList",
      "value": ""
    },
    {
      "name": "EnableMSStandardBlockedWords",
      "value": "False"
    },
    {
      "name": "ClassificationDescriptions",
      "value": ""
    },
    {
      "name": "DefaultClassification",
      "value": ""
    },
    {
      "name": "PrefixSuffixNamingRequirement",
      "value": ""
    },
    {
      "name": "AllowGuestsToBeGroupOwner",
      "value": "False"
    },
    {
      "name": "AllowGuestsToAccessGroups",
      "value": "True"
    },
    {
      "name": "GuestUsageGuidelinesUrl",
      "value": ""
    },
    {
      "name": "GroupCreationAllowedGroupId",
      "value": "62e90394-69f5-4237-9190-012177145e10"
    },
    {
      "name": "AllowToAddGuests",
      "value": "False"
    },
    {
      "name": "UsageGuidelinesUrl",
      "value": ""
    },
    {
      "name": "ClassificationList",
      "value": ""
    },
    {
      "name": "EnableGroupCreation",
      "value": "True"
    }
  ]
}'
                        
                          if($Groupvalue.id){
                                               #if settings available update the settings
                                               $settingsid = $Groupvalue.id
                                               $patchuri = "https://graph.microsoft.com/v1.0/groups/" +$id+ "/settings/" + "$settingsid" 
                                               $updatesettings = Invoke-RestMethod -Headers $Header -Uri $patchuri -Method Patch -Body $body -ContentType 'application/json'
                                               write-host "settings has been updated for" $displayName
                                              }
                                        else{ 
                                              #create settings template and apply
                                              $createuri = "https://graph.microsoft.com/v1.0/groups/" +$id+ "/settings/"
                                              $newsettings = Invoke-RestMethod -Headers $Header -Uri $createuri -Method Post -Body $body -ContentType 'application/json'
                                              write-host "new settings has been created and applied to Team $displayName"
                                              }

                      $finaluri = "https://graph.microsoft.com/v1.0/groups/" +$id+ "/settings" 
                      $final = Invoke-RestMethod -Headers $Header -Uri $finaluri -Method Get -ContentType 'application/json'          
                      $status = $final.value.values.value
                      
                      write-host "exporting data for Team $displayName"
                      $file = New-Object psobject
                      $file | add-member -MemberType NoteProperty -Name TeamsName $displayName
                      $file | add-member -MemberType NoteProperty -Name AllowToAddGuests $status
                      $file | export-csv output.csv -NoTypeInformation -Append
                      } 
        
                    if ($group.'@odata.nextLink' -eq $null ) 
                        { 
                        break 
                            } 
                    else 
                        { 
                        $group = Invoke-RestMethod -Headers $Header -Uri $group.'@odata.nextLink' -Method Get 
                        }
                   }while($true);
       }
 else 
{
    write-host "You need to login admin consent in order to continue... " 
}
  


  


  