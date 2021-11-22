function Get-SchemaType
{
	param([PSCustomObject]$prop)

	if($prop.TypeNameOfValue.ToString() -eq "System.Object[]")
	{
		[PSCustomObject]@{
			description="???";
			type = "string";
			items = [PSCustomObject]@{
				type="object"; 
				properties=[PSCustomObject]@{}; 
			};
		}
	}
	else
	{
		[PSCustomObject]@{
			description="???";
			type = "string";
		}
	}
}

function Build-SchemaProperty
{
	param([PSCustomObject]$prop)

	switch($prop.TypeNameOfValue.ToString())
	{
		"System.Int64"
		{
			$description = Get-SchemaType $prop
			$description.type = "integer"
			$description | Add-Member -NotePropertyName "schemaFiles" -NotePropertyValue @() -Force
			$description
		}
		"System.Boolean"
		{
			$description = Get-SchemaType $prop
			$description.type = "boolean"
			$description | Add-Member -NotePropertyName "schemaFiles" -NotePropertyValue @() -Force
			$description
		}
		"System.String"
		{
			$description = Get-SchemaType $prop
			$description.type = "string"
			$description | Add-Member -NotePropertyName "schemaFiles" -NotePropertyValue @() -Force
			$description
		}
		"System.Object[]"
		{
			$description = Get-SchemaType $prop
			$description.type = "array"
			$description | Add-Member -NotePropertyName "schemaFiles" -NotePropertyValue @() -Force

			$prop.Value | % {
				if($_.GetType().Name -eq "string")
				{
					$description.items.type = "string"
					$description.items.PSObject.Properties.Remove("properties")
				}
				else
				{
					$_.PSObject.Properties | % {
						$newProp = Build-SchemaProperty $_
						$newProp.PSObject.Properties.Remove("schemaFiles")
						$description.items.properties | Add-Member -NotePropertyName $_.Name -NotePropertyValue $newProp -Force
					}
				}
			}
			$description
		}
	}
}

function Generate-Schema
{
	param([string]$type)

	$schemaDate = (Get-Date -Format "yyyy-MM-dd")
	$schemaDateFolder = Join-Path $PWD "schema" $schemaDate
	$schemaLatest = Join-Path $PWD "schema" "latest" 
	$schemaPath = Join-Path $schemaLatest "foundation" "schema.json"
	$latestSchema = Get-Content $schemaPath | ConvertFrom-Json
	$properties = $latestSchema.Properties.PSObject.Properties.Copy()
	$selectedProperties = $properties | Where { $_.Value.schemaFiles -eq $null -Or $_.Value.schemaFiles -contains $type -Or $_.Value.schemaFiles.Count -eq 0 } 

	$newScheme = $latestSchema
	$newScheme.PSObject.Properties.Remove("properties")
	$newScheme.'$id' = $newScheme.'$id'.Replace("foundation",$type)
	$newProperties = [PSCustomObject]@{}
	$newScheme | Add-Member -MemberType NoteProperty -Name "properties" -Value $newProperties -Force
	$selectedProperties | % {
		$_.Value.PSObject.Properties.Remove("schemaFiles")
		$newScheme.properties | Add-Member -MemberType NoteProperty -Name ($_.Name) -Value ($_.Value) -Force
	}

	$schemaFolder = Join-Path $schemaLatest $type
	$schema = Join-Path $schemaFolder "schema.json"
	New-Item -ItemType Directory -Force -Path $schemaFolder | Out-Null
	Write-Host "Writing sub schema '$type' to latest: $schema"
	$newScheme | ConvertTo-Json -Depth 100 | Set-Content $schema -Force

	$schemaFolder = Join-Path $schemaDateFolder $type
	$schema = Join-Path $schemaFolder "schema.json"
	New-Item -ItemType Directory -Force -Path $schemaFolder | Out-Null
	Write-Host "Writing sub schema '$type' to latest: $schema"
	$newScheme | ConvertTo-Json -Depth 100 | Set-Content $schema -Force
}

function Generate-SubSchemas
{
	$schemaDate = (Get-Date -Format "yyyy-MM-dd")
	$latestFolder = Join-Path $PWD "schema" "latest" "foundation"
	$latestSchema = Join-Path $latestFolder "schema.json"
	$newSchemaFolder = Join-Path $PWD "schema" $schemaDate "foundation"
	$newSchema = Join-Path $newSchemaFolder "schema.json"	
	New-Item -ItemType Directory -Force -Path $newSchemaFolder | Out-Null
	Copy-Item $latestSchema $newSchema -Force | Out-Null

	Generate-Schema "consumer"
	Generate-Schema "api"
	Generate-Schema "job"
	Generate-Schema "ui"
}

function Generate-LatestSchema
{
	param([string[]] $paths = @("C:\Users\chmi\source\search"))
	
	$schemaDate = (Get-Date -Format "yyyy-MM-dd")
	$schema = Join-Path $PWD "schema"
	$schemaLatest = Join-Path $schema "latest"
	$schemaPath = Join-Path $schemaLatest "foundation" "schema.json"
	$latestSchema = Get-Content $schemaPath | ConvertFrom-Json
	$latestSchema.'$id' = "https://mvno.dk/json/$schemaDate/foundation/schema.json"

	$fieldsFound = @{}
	Write-Host ""
	$paths | % {
		Write-Host "Scanning for fields: " $_
		gci -R $_ *.sd.json | Where { $_.Length -gt 0 } | % {
			$sdFile = $_.Fullname
			$sd = Get-Content $sdFile | ConvertFrom-Json
			$sd.PSobject.Properties | % {
				$prop = $_
				$entry = [PSCustomObject]@{
					schema = Build-SchemaProperty $prop;
					file = $sdFile;
				}

				if($fieldsFound.Keys -notcontains $prop.Name -And $prop.Name.EndsWith("schema") -eq $false)
				{
					$fieldsFound.Add($prop.Name, $entry)
				}
			}
		}
	}

	Write-Host ""
	Write-Host "Unique fields found across paths:"
	$fieldsFound.GetEnumerator() | Sort -Property Name | Format-Table

	Write-Host "Adding missing fields to latest schema:"
	$knownFields = $latestSchema.Properties.PSObject.Properties.Name

	$fieldsFound.GetEnumerator() | % {
		if($knownFields -notcontains $_.Key)
		{
			Write-Host "  - "$_.Key
			$schema = $_.Value.schema
			$latestSchema.properties | Add-Member -MemberType NoteProperty -Name $_.Key -Value $schema -Force
		}
	}

	Write-Host "Marking fields not used anywhere as [NotInUse] in latest schema:"
	$fieldsToRemove = $latestSchema.Properties.PSObject.Properties.Name | Where { $fieldsFound.Keys -notcontains $_ }
	$fieldsToRemove | % {
		Write-Host "  - "$_
		if($latestSchema.properties."$_".Description.Contains("[NotInUse]") -eq $false)
		{
			$latestSchema.properties."$_".Description = "[NotInUse] " + $latestSchema.properties."$_".Description
		}
	#	$latestSchema.properties.PSObject.Properties.Remove($_)
	}

	Write-Host "Writing new foundation schema to latest: $schemaPath"
	$latestSchema | ConvertTo-Json -Depth 100 | Set-Content $schemaPath
}
