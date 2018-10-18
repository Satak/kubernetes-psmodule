
function Enter-KubernetesPod {
    <#
    .SYNOPSIS
        Executes bash or sh command in a container to establish an interactive session inside the container.
    .DESCRIPTION
        https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/
    .EXAMPLE
        Enter-KubernetesPod -Namespace <string> -PodName <string> [-Shell <string>]
        Enters container with selected shell (bash(default), sh)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Namespace,
        [ValidateSet("bash", "sh")][string]$Shell = "bash"
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'PodName'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 2

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesPod -Namespace $Namespace | Select-Object -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $PodName = $PsBoundParameters[$ParameterName]
    }
    process {
        kubectl exec -ti $PodName $Shell -n $Namespace
    }
}

function Remove-KubernetesPod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Namespace
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'PodName'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesPod -Namespace $Namespace | Select-Object -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $PodName = $PsBoundParameters[$ParameterName]
    }
    process {
        kubectl delete pod $PodName -n $Namespace
    }
}

function Get-KubernetesPod {
    [CmdletBinding()]
    param (
        [switch]$All,
        [switch]$Detailed
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'Namespace'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesNamespace
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $Namespace = $PsBoundParameters[$ParameterName]
    }
    process {
        if($All) {
            $fieldSelector = $null
        } else {
            $fieldSelector = '--field-selector=status.phase=Running'
        }
        $jsonPodData = kubectl get pods $fieldSelector -n $Namespace -o json | ConvertFrom-Json | Select-Object -ExpandProperty items
        $jsonPodData | foreach-object {
            $obj = [PSCustomObject]@{
                Name = $_.metadata.name
                Status = $_.status.phase
            }
            if($Detailed) {
                $obj | Add-Member -NotePropertyName App -NotePropertyValue $_.metadata.labels.app
                $obj | Add-Member -NotePropertyName Node -NotePropertyValue $_.spec.nodeName
                $obj | Add-Member -NotePropertyName Restarts -NotePropertyValue $_.status.containerStatuses.restartCount
                $obj | Add-Member -NotePropertyName Image -NotePropertyValue $_.status.containerStatuses.image
            }
            $obj
        }
    }
}

function Get-KubernetesNamespace {
    $jsonNamespaceData = kubectl get namespaces -o json | ConvertFrom-Json
    $jsonNamespaceData.items.metadata.name
}

function ConvertFrom-Base64 {
	[alias("fb64")]
    [CmdletBinding()]
    param(
        [Parameter(
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
        ]
        [string]$Value
    )

    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value))
}

function ConvertTo-Base64 {
	[alias("tb64")]
    [CmdletBinding()]
    param(
        [Parameter(
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
        ]
        [string]$Value
    )

    return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Value))
}

function Get-KubernetesSecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
		[string]$Namespace
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'SecretName'

        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = kubectl get secrets -n $Namespace -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $SecretName = $PsBoundParameters[$ParameterName]
    }
    process {
        if($SecretName) {
            $jsonData = kubectl get secret $SecretName -n $Namespace -o json | ConvertFrom-Json | Select-Object -ExpandProperty data
            $hashTable = @{}
            $jsonData.PSObject.Properties | ForEach-Object {
                $hashTable[$_.Name] = $_.value | ConvertFrom-Base64
            }
            New-Object PSObject -Property $hashTable
        } else {
            kubectl get secrets -n $Namespace -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty name
        }

    }
}

function Get-KubernetesPodPublicIP {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Namespace
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'PodName'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesPod -Namespace $Namespace | Select-Object -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $PodName = $PsBoundParameters[$ParameterName]
    }
    process {

        if(!$PodName) {
            Get-KubernetesPod -Namespace $Namespace -Detailed | ForEach-Object { 
                $ip = kubectl exec $_.Name -n $Namespace -- wget -qO- icanhazip.com 2>$null

                [PSCustomObject]@{
                    Service = $_.App
                    IpAddress = if($ip.GetType().name -ne "String"){$null}else{$ip}
                }
            }
        } else {
            $ip = kubectl exec $PodName -n $Namespace -- wget -qO- icanhazip.com 2>$null
            [PSCustomObject]@{
                Service = $PodName
                IpAddress = if($ip.GetType().name -ne "String"){$null}else{$ip}
            }
        }
    }
}

function Get-KubernetesNode {
    [CmdletBinding()]
    param (
    )
    
    begin {
    }
    
    process {
        $kubeNodeJSONData = kubectl get nodes -o json | ConvertFrom-Json | Select-Object -ExpandProperty items
        $kubeNodeJSONData | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.metadata.name
                ExternalIP = $_.status.addresses | Where-Object {$_.type -eq 'ExternalIP'} | Select-Object -ExpandProperty address
            }
        }
    }
    
    end {
    }
}

function Get-KubernetesPodResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Namespace
    )
    
    begin {
    }
    
    process {
        $kubernetesData = kubectl top pods -n $Namespace
        $kubernetesData | Select-Object -Skip 1 | ForEach-Object {
            $name, $cpu, $mem = $_.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
            
            [pscustomobject]@{
                Name = $name
                CPUCores = [int](($cpu.toCharArray() | Select-Object -SkipLast 1) -join '') / 1000
                MEMMB = [int](($mem.toCharArray() | Select-Object -SkipLast 2) -join '')
            }
        }
    }
    
    end {
    }
}

function Get-KubernetesNodeResource {
    [CmdletBinding()]
    param ()
    
    begin {
    }
    
    process {
        $kubernetesNodeData = kubectl top nodes
        $kubernetesNodeData | Select-Object -Skip 1 | ForEach-Object {
            $name, $cpuCore, $cpuPercent, $memMB, $memPercent = $_.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
            
            [pscustomobject]@{
                Name = $name
                CPUCores = [int](($cpuCore.toCharArray() | Select-Object -SkipLast 1) -join '') / 1000
                CPUPercent = [int](($cpuPercent.toCharArray() | Select-Object -SkipLast 1) -join '')
                MEMMB = [int](($memMB.toCharArray() | Select-Object -SkipLast 2) -join '')
                MEMPercent = [int](($memPercent.toCharArray() | Select-Object -SkipLast 1) -join '')
            }
        }
    }
    
    end {
    }
}

function Get-KubernetesEvictedPod {
    [CmdletBinding()]
    param ()
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'Namespace'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesNamespace
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $Namespace = $PsBoundParameters[$ParameterName]
    }
    process {

        $fieldSelector = '--field-selector=status.phase=Failed'

        $jsonPodData = kubectl get pods $fieldSelector -n $Namespace -o json | ConvertFrom-Json | Select-Object -ExpandProperty items
        $jsonPodData | foreach-object {
            [PSCustomObject]@{
                Name = $_.metadata.name
                Status = $_.status.phase
            }
        }
    }
}

function Clear-KubernetesEvictedPod {
    [CmdletBinding()]
    param (
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'Namespace'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-KubernetesNamespace
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $Namespace = $PsBoundParameters[$ParameterName]
    }
    process {

        Get-KubernetesEvictedPod -Namespace $Namespace | ForEach-Object {
            kubectl delete pod $_.name -n $Namespace
        }
    }
}

# Aliases
New-Alias -Name fb64 -Value ConvertFrom-Base64 -Description "Convert base64 string to normal string."
New-Alias -Name tb64 -Value ConvertTo-Base64 -Description "Convert string to base64."

# Export-ModuleMember -Function * -alias *
