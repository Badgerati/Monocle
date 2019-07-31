function Resolve-MonocleMPathExpression
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Expression,

        [Parameter(Mandatory=$true, ParameterSetName='Document')]
        $Document,

        [Parameter(Mandatory=$true, ParameterSetName='Elements')]
        $Elements
    )

    # Regex to match an individual mpath expression
    $regex = '^(?<tag>[a-zA-Z]+)(?<filter>\[(?<attr>\@[a-zA-Z\-]+|\d+)((?<opr>(\!){0,1}(\=|\~))(?<value>.+?)){0,1}\](\[(?<index>\d+)\]){0,1}){0,1}$'
    $foundElements = $null

    # ensure the expression is valid against the regex
    if ($Expression -match $regex)
    {
        $tag = $Matches['tag']

        # find initial elements based on the tag from document or previously found elements
        if ($PSCmdlet.ParameterSetName -ieq 'Document') {
            $foundElements = $Document.IHTMLDocument3_getElementsByTagName($tag)
        }
        else {
            $foundElements = ($Elements | ForEach-Object { $_.IHTMLDocument3_getElementsByTagName($tag) })
        }

        # if there's a filter, then filter down the found elements above
        if (![string]::IsNullOrWhiteSpace($Matches['filter']))
        {
            $attr = $Matches['attr']
            $opr = $Matches['opr']
            $value = $Matches['value']
            $index = $Matches['index']

            # filtering by attributes starts with an '@', else we have an index into the elements
            if ($attr.StartsWith('@'))
            {
                $attr = $attr.Trim('@')

                # if there's no operator, then use all elements that have a non-empty attribute
                if ([string]::IsNullOrWhiteSpace($opr)) {
                    $foundElements = $foundElements | Where-Object { ![string]::IsNullOrWhiteSpace($_.getAttribute($attr)) }
                }
                else
                {
                    # find elements based on validaity of attribute to passed value
                    switch ($opr)
                    {
                        '=' {
                            $foundElements = $foundElements | Where-Object { $_.getAttribute($attr) -ieq $value }
                        }

                        '~' {
                            $foundElements = $foundElements | Where-Object { $_.getAttribute($attr) -imatch $value }
                        }

                        '!=' {
                            $foundElements = $foundElements | Where-Object { $_.getAttribute($attr) -ine $value }
                        }

                        '!~' {
                            $foundElements = $foundElements | Where-Object { $_.getAttribute($attr) -inotmatch $value }
                        }
                    }
                }

                # select a element from the filtered elements based on index (could sometimes happen)
                if (![string]::IsNullOrWhiteSpace($index)) {
                    $foundElements = $foundElements | Select-Object -Skip ([int]$index) -First 1
                }
            }
            else {
                # select the element based on index of found elements
                $foundElements = $foundElements | Select-Object -Skip ([int]$attr) -First 1
            }
        }
    }
    else {
        throw "MPath expression is not valid: $Expression"
    }

    if (($foundElements | Measure-Object).Count -eq 0) {
        throw "Failed to find elements for: $Expression"
    }

    return $foundElements
}

function Resolve-MonocleMPath
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $MPath
    )

    # split into multiple expressions
    $exprs = $MPath -split '/'

    # if there are no expression, return null
    if (($null -eq $exprs) -or ($exprs.length -eq 0)) {
        return [System.DBNull]::Value
    }

    # find initial elements based on the document and first expression
    $elements = Resolve-MonocleMPathExpression -Expression $exprs[0] -Document $Browser.Document

    # find rest of elements from the previous elements found above
    for ($i = 1; $i -lt $exprs.length; $i++) {
        $elements = Resolve-MonocleMPathExpression -Expression $exprs[$i] -Elements $elements
    }

    # Monocle only deals with single elements, so return the first
    return ($elements | Select-Object -First 1)
}