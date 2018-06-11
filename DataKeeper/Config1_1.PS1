$a1 = "10.200.8.55"
$a2 = "10.200.8.53"
$b1 = "10.200.8.56"
$nodes = ( $a1, $a2, $b1 )

$nodeClassDef = @"
    public class Node
    {
        #region PROPERTIES - IPv4, FQDN, Volume

        public String IPv4
        {
            get { return ipv4; }
            private set { ipv4 = value; }
        } private String ipv4;
        

        public String FQDN
        {
            get { return fqdn; }
            private set { fqdn = value; }
        } private String fqdn;
       

        public String Volume
        {
            get { return volume; }
            private set { volume = value; }
        } private String volume;

        #endregion


        public Node(String ipv4, String fqdn, String volume){

            IPv4 = ipv4;
            FQDN = fqdn;
            Volume = volume;

        }

    }
"@

function VerifyConnections {
	Foreach($node in $nodes) {
		if( Test-Connection $node ) {
			Write-Warning("SUCCESS");
		} else {
			Write-Warning("Failure");
		}
	}
}

Add-Type -TypeDefinition $nodeClassDef
$A = New-Object Node("10.200.8.55", "cae-qa-v55.qagroup.com", "E")
VerifyConnections








