
function Write-File() {
	param( 
		
		
		[Parameter(Mandatory=$False, Position=0)]
		[string]$Text = "2010 Scripting Games: Advanced Event 8--Creating Text Files of Specific Sizes`n", 
		
		[Parameter(Mandatory=$False, Position=1)]
		[int]$Size = (100kb, 1mb, 10mb, 100mb), 
		
		[Parameter(Mandatory=$False, Position=2)]
		[string]$Folder = ".",

		[Parameter(Mandatory=$False, Position=3)]
		[string]$FilenamePrefix= "WriteFileOutput"
	) 
	
	createFile $Text $Size $Folder $FilenamePrefix 
}

# A not too fancy way to convert file size to an appropriate unit. 
# Should work for a few years, because it already supports terabytes ;) 
function convertSizeUnit($_size) { 
	switch ($_size) 
	{ 
	{ $_ -ge 1TB } { $sizeText = "$($_/1TB)T"; break;} 
	{ $_ -ge 1GB } { $sizeText = "$($_/1GB)G"; break;} 
	{ $_ -ge 1MB } { $sizeText = "$($_/1MB)M"; break;} 
	{ $_ -ge 1KB } { $sizeText = "$($_/1KB)K"; break;} 
	default {$sizeText = "${_}B"} 
	} 
	return $sizeText 
} 

# Function creates a file with a given size using the text passed as parameter 
function createFile($_text, $_size, $_folder, $filename) { 
	# The total char length should be the desired file size minus 2, because an 
	# empty file seems to have 2 bytes, for some reason. Note that we will use 
	# ASCII encoding, which means 1 char = 1 byte. 
	$charLength = $_size - 2 

	# Assuring the string ends with one carriage return/new line 
	# (just to make the file look nicer). 
	$_text = $_text.trim() + "`r`n" 

	# Calculating how many times we should repeat the text 
	$div = [Math]::Truncate($charLength / $_text.Length) 

	# We most likely will need to repeat only a portion of the text to achieve 
	# the desired size 
	$remainder = $charLength % $_text.Length 

	if ($remainder -gt 0) { 
		# Yep, we will need to pad the file with a few characters from the text 
		# to make the size exact. Who would've thought? 
		$finalText = $_text * $div + ($_text[0..($remainder - 1)] -join '') 
	} else { 
		# Wow, the text fits perfectly to the desired size! 
		$finalText = $_text * $div 
	} 
	
	# Creating the filename according to the size unit 
	$fileName += "_" + $(convertSizeUnit $_size) + ".txt" 

	# Now we create the file using ASCII encoding (1 byte per char) 
	Out-File -InputObject $finalText -encoding ASCII -filepath (Join-Path $_folder $fileName) 
} 
