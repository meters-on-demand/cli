
function Get-Attributes {
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]
        $ParameterSetName,
        [Parameter(Position = 1)]
        [System.Boolean]
        $Mandatory,
        [Parameter(Position = 2)]
        [int]
        $Position
    )
    $Attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $a = [System.Management.Automation.ParameterAttribute]@{ }
    if ($ParameterSetName) { $a.ParameterSetName = $ParameterSetName }
    if ($Mandatory) { $a.Mandatory = $Mandatory }
    if ($Position) { $a.Position = $Position }
    $Attributes.Add($a)
    return $Attributes
}

function Get-Parameter {
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $ParameterName,
        [Parameter(Mandatory, Position = 1)]
        [type]
        $Type,
        [Parameter(Mandatory, Position = 2)]
        [System.Collections.ObjectModel.Collection[System.Attribute]]
        $Attributes
    )
    return [System.Management.Automation.RuntimeDefinedParameter]::new(
        $ParameterName, $Type, $Attributes
    )
}
