Write-Warning "You must manually break out of this script."
Write-Host "running..."

while($true) {
	for ($i=1; $i -lt 11; $i++) {
		for ($j=1; $j -lt 101; $j++) {
			"testing" > G:\$i\$j\test
			rm G:\$i\$j\test
		}
	}
}
