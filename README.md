# ??? Decentralized Election Voting System

A secure, transparent, and immutable voting system built on the Stacks blockchain using Clarity smart contracts.

## ?? Features

- **?? Secure Voting**: Cryptographically secure voting with tamper-proof records
- **?? Multi-Election Support**: Create and manage multiple elections simultaneously
- **?? Real-time Results**: View election results and candidate vote counts
- **? Time-bounded Elections**: Set start and end blocks for controlled voting periods
- **?? Candidate Management**: Add, view, and deactivate candidates
- **?? Voter Registration**: Secure voter registration system
- **??? Access Control**: Only election organizers can manage their elections
- **?? Vote Tracking**: Complete audit trail of all votes cast

## ?? Contract Functions

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-election` | Retrieve election details by ID |
| `get-candidate` | Get candidate information |
| `get-vote` | Check if a voter has voted in an election |
| `get-voter-registration` | Check if a voter is registered |
| `is-election-active` | Check if an election is currently active |
| `has-voted` | Check if a specific voter has cast their vote |
| `get-election-results` | Get comprehensive election results |

### Public Functions

| Function | Description |
|----------|-------------|
| `create-election` | Create a new election with title, description, and time bounds |
| `add-candidate` | Add candidates to an election (organizer only) |
| `register-voter` | Register to vote in a specific election |
| `cast-vote` | Cast your vote for a candidate |
| `end-election` | Manually end an election (organizer only) |
| `deactivate-candidate` | Remove a candidate from election (organizer only) |

## ??? Usage Guide

### 1. Creating an Election

```clarity
(contract-call? .decentralised-election-voting-system create-election
  "Presidential Election 2024"
  "Vote for the next president"
  u1000  ;; start-block
  u2000) ;; end-block
```

### 2. Adding Candidates

```clarity
(contract-call? .decentralised-election-voting-system add-candidate
  u1     ;; election-id
  "Alice Smith"
  "Experienced leader with vision for change")
```

### 3. Voter Registration

```clarity
(contract-call? .decentralised-election-voting-system register-voter u1)
```

### 4. Casting Votes

```clarity
(contract-call? .decentralised-election-voting-system cast-vote
  u1  ;; election-id
  u1) ;; candidate-id
```

### 5. Checking Results

```clarity
(contract-call? .decentralised-election-voting-system get-election-results u1)
```

## ?? Security Features

- **One Vote Per Person**: Each voter can only vote once per election
- **Time-locked Voting**: Elections have defined start and end times
- **Organizer Controls**: Only election creators can modify their elections
- **Immutable Records**: All votes are permanently recorded on blockchain
- **Registration Required**: Voters must register before casting votes

## ?? Error Codes

| Code | Description |
|------|-------------|
| `u100` | Owner-only operation |
| `u101` | Election/candidate not found |
| `u102` | Unauthorized access |
| `u103` | Resource already exists |
| `u104` | Invalid election |
| `u105` | Voting period closed |
| `u106` | Already voted |
| `u107` | Invalid candidate |
| `u108` | Election not started |
| `u109` | Election ended |

## ?? Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/Decentralised-Election-Voting-System.git
cd Decentralised-Election-Voting-System
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## ?? Contract Architecture

The smart contract uses several data structures:

- **Elections Map**: Stores election metadata and status
- **Candidates Map**: Manages candidate information and vote counts
- **Votes Map**: Records individual votes with timestamps
- **Voter Registrations Map**: Tracks registered voters per election
- **Election Candidates Count**: Maintains candidate counter per election

## ?? Testing

Run the comprehensive test suite:

```bash
clarinet test
```

Tests cover:
- ? Election creation and management
- ? Candidate addition and deactivation
- ? Voter registration process
- ? Vote casting and validation
- ? Access control and permissions
- ? Edge cases and error conditions


## ?? License

This project is licensed under the MIT License 

## ?? Roadmap

- [ ] Multi-signature election creation
- [ ] Delegate voting functionality
- [ ] Advanced result analytics
- [ ] Mobile-friendly voting interface
- [ ] Integration with identity verification systems



---
