# GeoLedger: Decentralized Land Registry Smart Contract

A comprehensive Clarity smart contract for decentralized land registry and zoning management on the Stacks blockchain. GeoLedger represents land parcels as NFTs (SIP-009 compliant) and manages their associated metadata, including location, area, and zoning classifications with a built-in governance system for zoning changes.

## Features

### 🏠 NFT-Based Land Registry
- Each land parcel is represented as a unique NFT (SIP-009 compliant)
- Secure ownership tracking and transfer capabilities
- Immutable land parcel metadata storage

### 📍 Comprehensive Metadata Management
- **GPS Coordinates**: Store precise location data for each parcel
- **Area Tracking**: Record parcel size in square meters
- **Zoning Classification**: Manage land use categories (Residential, Commercial, Industrial, Agricultural)

### 🗳️ Decentralized Zoning Governance
- **Proposal System**: Parcel owners can propose zoning changes
- **Community Voting**: Democratic voting mechanism for zoning proposals
- **Transparent Process**: All proposals and votes are recorded on-chain

### 🔒 Security Features
- **Input Validation**: Comprehensive validation for all user inputs
- **Access Control**: Admin-only functions for critical operations
- **Anti-Fraud Measures**: Prevention of duplicate voting and invalid transfers

## Contract Architecture

### Core Components

1. **NFT Implementation**: SIP-009 compliant NFT for land parcels
2. **Metadata Storage**: Structured data maps for parcel information
3. **Proposal System**: Democratic governance for zoning changes
4. **Validation Layer**: Security checks for all inputs and operations

### Data Structures

```clarity
;; Parcel Metadata
{
  gps-coordinates: (string-ascii 64),
  area-sq-meters: uint,
  zoning-class: (string-ascii 40)
}

;; Zoning Proposals
{
  proposer: principal,
  parcel-id: uint,
  proposed-zoning: (string-ascii 40),
  is-approved: bool,
  votes-for: uint,
  votes-against: uint
}
```

## Getting Started

### Prerequisites

- **Clarinet**: Version 0.31.1 or compatible
- **Stacks CLI**: For deployment and interaction
- **Node.js**: For testing and development tools

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd geoledger
```

2. Initialize Clarinet project (if not already done):
```bash
clarinet new geoledger
```

3. Place the contract in the contracts directory:
```bash
cp geoledger.clar contracts/
```

4. Check contract syntax:
```bash
clarinet check
```

### Testing

Run the contract tests:
```bash
clarinet test
```

Check contract analysis:
```bash
clarinet analyze
```

## Usage

### Admin Functions

#### Register a New Parcel
Only the contract admin can register new land parcels:

```clarity
(contract-call? .geoledger register-parcel 
  'SP1234...OWNER
  "40.7128,-74.0060"  ;; GPS coordinates
  u1000               ;; Area in square meters
  "Residential"       ;; Zoning type
)
```

#### Add New Zoning Type
Expand available zoning classifications:

```clarity
(contract-call? .geoledger add-zoning-type "Mixed-Use")
```

### Parcel Owner Functions

#### Transfer Ownership
Transfer a parcel to another address:

```clarity
(contract-call? .geoledger transfer 
  u1                    ;; Token ID
  tx-sender             ;; Current owner
  'SP5678...RECIPIENT   ;; New owner
)
```

#### Propose Zoning Change
Submit a proposal to change parcel zoning:

```clarity
(contract-call? .geoledger propose-zoning-change
  u1            ;; Parcel ID
  "Commercial"  ;; Proposed new zoning
)
```

### Community Functions

#### Vote on Proposals
Participate in zoning governance:

```clarity
(contract-call? .geoledger vote-on-proposal
  u1     ;; Proposal ID
  true   ;; Vote (true = for, false = against)
)
```

#### Finalize Proposal
Execute approved proposals:

```clarity
(contract-call? .geoledger finalize-proposal u1)
```

### Query Functions

#### Get Parcel Information
```clarity
(contract-call? .geoledger get-parcel-metadata u1)
(contract-call? .geoledger get-owner u1)
```

#### Check Proposal Status
```clarity
(contract-call? .geoledger get-proposal u1)
(contract-call? .geoledger has-voted u1 'SP1234...VOTER)
```

#### Get Contract Statistics
```clarity
(contract-call? .geoledger get-parcel-count)
(contract-call? .geoledger get-proposal-count)
```

## Security Considerations

### Input Validation
- **GPS Coordinates**: Must be 1-64 characters long
- **Area**: Must be between 1 and 1,000,000,000 square meters
- **Zoning Types**: Must be 1-40 characters and from approved list
- **Principal Addresses**: Validated to prevent zero address usage

### Access Controls
- **Admin Only**: Parcel registration and zoning type management
- **Owner Only**: Zoning change proposals and transfers
- **Anti-Fraud**: Prevents double voting and self-transfers

### Governance Security
- **One Vote Per Address**: Each address can only vote once per proposal
- **Majority Rule**: Proposals require more votes for than against
- **Transparent Process**: All actions are logged with events

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u101 | ERR-NOT-AUTHORIZED | Caller lacks required permissions |
| u102 | ERR-PARCEL-NOT-FOUND | Referenced parcel doesn't exist |
| u103 | ERR-PROPOSAL-NOT-FOUND | Referenced proposal doesn't exist |
| u104 | ERR-ALREADY-VOTED | User has already voted on this proposal |
| u105 | ERR-VOTING-CLOSED | Proposal voting has ended |
| u106 | ERR-PARCEL-OWNER-ONLY | Only parcel owner can perform this action |
| u107 | ERR-INVALID-ZONING-TYPE | Zoning type not in approved list |
| u108 | ERR-INVALID-INPUT | Input validation failed |

## Events

The contract emits structured events for important actions:

```clarity
{event: "proposal-approved", parcel-id: uint, proposal-id: uint}
{event: "proposal-rejected", proposal-id: uint}
```

## Deployment

### Testnet Deployment
1. Configure Clarinet.toml for testnet
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply -p testnet
```

### Mainnet Deployment
1. Ensure thorough testing on testnet
2. Configure mainnet parameters
3. Deploy with appropriate gas fees

## Development Roadmap

### Current Features
- ✅ Basic NFT functionality
- ✅ Metadata management
- ✅ Zoning governance
- ✅ Input validation
- ✅ Security controls

### Future Enhancements
- 🔄 Time-based voting periods
- 🔄 Weighted voting by land area
- 🔄 Integration with mapping services
- 🔄 Automated compliance checking
- 🔄 Multi-signature admin controls

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with comprehensive tests
4. Ensure all security checks pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or contributions:
- **Issues**: Submit via GitHub Issues
- **Documentation**: Check the `/docs` directory
- **Community**: Join our Discord/Telegram

## Acknowledgments

- Built on the Stacks blockchain
- Implements SIP-009 NFT standard
- Inspired by real-world land registry systems
- Community-driven governance model

---

**⚠️ Important**: This contract is provided as-is for educational and development purposes. Ensure proper auditing before any production use involving real-world land registry or significant financial value.