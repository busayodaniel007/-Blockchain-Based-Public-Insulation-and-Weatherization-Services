# Blockchain-Based Public Insulation and Weatherization Services

A comprehensive smart contract system for managing public insulation and weatherization services on the Stacks blockchain. This system provides transparent, immutable tracking of contractor licensing, program management, certifications, and compliance for energy efficiency improvements.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of public weatherization services:

### 1. Insulation Contractor Licensing Contract (`insulation-licensing.clar`)
- Issues and manages permits for thermal and acoustic insulation installation
- Tracks contractor qualifications and license status
- Manages license renewals and suspensions
- Maintains contractor performance records

### 2. Weatherization Program Management Contract (`weatherization-program.clar`)
- Coordinates energy efficiency improvements for low-income homes
- Manages program enrollment and eligibility verification
- Tracks project completion and funding allocation
- Maintains beneficiary records and program statistics

### 3. Asbestos Abatement Certification Contract (`asbestos-certification.clar`)
- Manages specialized licenses for asbestos removal contractors
- Tracks certification levels and training requirements
- Monitors safety compliance and incident reporting
- Maintains hazardous material handling records

### 4. Energy Audit Coordination Contract (`energy-audit.clar`)
- Manages home energy assessments and efficiency recommendations
- Coordinates between auditors and property owners
- Tracks audit results and improvement recommendations
- Maintains energy efficiency metrics and reporting

### 5. Ventilation System Compliance Contract (`ventilation-compliance.clar`)
- Ensures proper ventilation in insulated buildings
- Manages compliance inspections and certifications
- Tracks ventilation system installations and maintenance
- Monitors air quality standards and building codes

## Key Features

- **Transparent Licensing**: All contractor licenses and certifications are publicly verifiable
- **Program Integrity**: Immutable records of weatherization program participation and outcomes
- **Safety Compliance**: Comprehensive tracking of safety certifications and compliance status
- **Performance Metrics**: Real-time tracking of energy efficiency improvements and program effectiveness
- **Audit Trail**: Complete history of all transactions and status changes

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation rules. The system uses:

- **Role-based Access Control**: Different permission levels for administrators, contractors, and auditors
- **State Management**: Comprehensive tracking of licenses, certifications, and program status
- **Event Logging**: Detailed event emission for all significant state changes
- **Error Handling**: Robust error codes and validation for all operations

## Data Structures

### Contractor Records
- License information and status
- Qualification levels and specializations
- Performance history and ratings
- Contact and business information

### Program Records
- Beneficiary information and eligibility
- Project details and completion status
- Funding allocation and disbursement
- Energy efficiency improvements achieved

### Certification Records
- Certification types and levels
- Training completion and renewal dates
- Safety compliance status
- Incident reports and corrective actions

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation
\`\`\`bash
git clone <repository-url>
cd weatherization-blockchain
npm install
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Register a New Contractor
\`\`\`clarity
(contract-call? .insulation-licensing register-contractor
"John's Insulation LLC"
"thermal-acoustic"
u5)
\`\`\`

### Enroll in Weatherization Program
\`\`\`clarity
(contract-call? .weatherization-program enroll-beneficiary
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNP
u50000
"Single family home")
\`\`\`

### Issue Asbestos Certification
\`\`\`clarity
(contract-call? .asbestos-certification issue-certification
'SP2CONTRACTOR123
"level-3"
u365)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Input validation prevents malicious data entry
- State changes are atomic and consistent
- Event logging provides complete audit trails

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
