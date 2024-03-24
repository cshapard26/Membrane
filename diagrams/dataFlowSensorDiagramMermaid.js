sequenceDiagram
	participant A as Client
	participant B as Smart Contract
	participant C as Blockchain
	participant D as Server
	participant E as Institutions

	D -) B: Public key
	A --) B: Request Server public key
	B -) A: Public key
	A -) B: Hash of encrypted data (commit)
	B -) C: Hashed data
	A -) B: Encrypted data (reveal)
	alt commit == reveal
        par to Server
		    B -) D: Encrypted data transfer (Chainlink)
        and to Client
            B -) A: Payment
        end
	else commit != reveal
		A --> D: Abort
	end
	D --) C: Signature callback
    E -) D: Public key
    E --) D: Data request
    D --) B: Authentication request
    B -) D: Authentication status
    alt Approved
		D -) E: One-time key
        D --) C: Signature callback
	else Denied
		C --> E: Abort
	end
	
