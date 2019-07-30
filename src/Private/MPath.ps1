function Resolve-MPathExpression
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $expr,
        
        [Parameter(Mandatory=$false)]
        $document = $null,
        
        [Parameter(Mandatory=$false)]
        $controls = $null
    )

    # Regex to match an individual mpath expression
    $regex = '^(?<tag>[a-zA-Z]+)(?<filter>\[(?<attr>\@[a-zA-Z\-]+|\d+)((?<opr>(\!){0,1}(\=|\~))(?<value>.+?)){0,1}\](\[(?<index>\d+)\]){0,1}){0,1}$'
    $foundControls = $null

    # ensure the expression is valid against the regex
    if ($expr -match $regex)
    {
        $tag = $Matches['tag']
        
        # find initial controls based on the tag from document or previously found controls
        if ($document -ne $null)
        {
            $foundControls = $document.getElementsByTagName($tag)
        }
        else
        {
            $foundControls = $controls | ForEach-Object { $_.getElementsByTagName($tag) }
        }

        # if there's a filter, then filter down the found controls above
        if (![string]::IsNullOrWhiteSpace($Matches['filter']))
        {
            $attr = $Matches['attr']
            $opr = $Matches['opr']
            $value = $Matches['value']
            $index = $Matches['index']

            # filtering by attributes starts with an '@', else we have an index into the controls
            if ($attr.StartsWith('@'))
            {
                $attr = $attr.Trim('@')

                # if there's no operator, then use all controls that have a non-empty attribute
                if ([string]::IsNullOrWhiteSpace($opr))
                {
                    $foundControls = $foundControls | Where-Object { ![string]::IsNullOrWhiteSpace($_.getAttribute($attr)) }
                }
                else
                {
                    # find controls based on validaity of attribute to passed value
                    switch ($opr)
                    {
                        '='
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -ieq $value }
                        }

                        '~'
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -imatch $value }
                        }

                        '!='
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -ine $value }
                        }

                        '!~'
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -inotmatch $value }
                        }
                    }
                }

                # select a control from the filtered controls based on index (could sometimes happen)
                if (![string]::IsNullOrWhiteSpace($index))
                {
                    $foundControls = $foundControls | Select-Object -Skip ([int]$index) -First 1
                }
            }
            else
            {
                # select the control based on index of found controls
                $foundControls = $foundControls | Select-Object -Skip ([int]$attr) -First 1
            }
        }
    }
    else
    {
        throw "MPath expression is not valid: $expr"
    }

    if (($foundControls | Measure-Object).Count -eq 0)
    {
        throw "Failed to find elements for: $expr"
    }

    return $foundControls
}

function Resolve-MPath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $mpath
    )

    # split into multiple expressions
    $exprs = $mpath -split '/'

    # if there are no expression, return null
    if ($exprs -eq $null -or $exprs.length -eq 0)
    {
        return [System.DBNull]::Value
    }

    # find initial controls based on the document and first expression
    $controls = Resolve-MPathExpression $exprs[0] -document $session.Browser.Document

    # find rest of controls from the previous controls found above
    for ($i = 1; $i -lt $exprs.length; $i++)
    {
        $controls = Resolve-MPathExpression $exprs[$i] -controls $controls
    }

    # Monocle only deals with single controls, so return the first
    return ($controls | Select-Object -First 1)
}