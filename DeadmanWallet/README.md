# Social Recovery Wallet with Dead Man's Switch - Smart Contract Documentation

This smart contract is designed to implement a **Social Recovery Wallet** with a **Dead Man's Switch**. It allows a wallet owner to designate trusted individuals (guardians) who can help recover the wallet in the event of inactivity or emergency. The contract enables recovery mechanisms triggered either by **inactivity** (if the wallet owner is inactive for a predefined period) or **emergency** (if the owner is unavailable for any reason). 

The contract also includes features such as multi-signature voting by the guardians, and it tracks the last active timestamp of the wallet owner to detect inactivity.

## Key Features
- **Social Recovery**: Trusted guardians can vote to recover the wallet and transfer ownership if the owner is inactive for too long.
- **Dead Man's Switch**: In the event of inactivity (based on a predefined threshold), guardians can initiate a recovery process.
- **Emergency Recovery**: In case of an emergency, guardians can vote to transfer ownership of the wallet to a new owner.
- **Guardians**: The wallet owner can designate up to 5 guardians who help in the recovery process.
- **Voting Mechanism**: Guardians must vote to trigger the recovery process, ensuring that the decision is consensual and secure.
- **Inactivity Timer**: The contract keeps track of the last active timestamp of the wallet owner. If the owner has been inactive for more than a set period (e.g., 6 months), guardians can initiate a recovery.

## Terminology

- **Wallet Owner**: The primary account that owns the wallet. This is the account that initially deploys the contract and can set and remove guardians.
- **Guardians**: Trusted individuals chosen by the wallet owner who can vote to recover the wallet in case of inactivity or emergency.
- **Recovery Votes**: Votes cast by guardians to approve the recovery of the wallet. A minimum number of votes is required for the recovery to be executed.
- **Inactivity Threshold**: The time period after which the owner is considered inactive. If the owner does not interact with the wallet during this period, guardians can initiate recovery.
- **Emergency Recovery**: A recovery process initiated when the owner is not responding or reachable in an emergency situation.

---

## Contract Variables

### Data Variables
- **contract-owner (principal tx-sender)**: The principal address of the current wallet owner.
- **new-owner (optional principal)**: The address of the new wallet owner that is set during the recovery process.
- **last-active (uint u0)**: The block height when the wallet owner was last active. Used to track inactivity.
- **recovery-votes (uint u0)**: The number of votes collected from guardians in support of the wallet recovery.
- **guardian-count (uint u0)**: The number of guardians set by the wallet owner.

### Constants
- **INACTIVITY-THRESHOLD (u15552000)**: The number of blocks (6 months assuming 10-minute blocks) of inactivity before the wallet owner is considered inactive.
- **REQUIRED-VOTES (u3)**: The number of votes required from guardians for the recovery process to proceed under normal conditions.
- **EMERGENCY-REQUIRED-VOTES (u5)**: The number of votes required from guardians for the recovery process to proceed in an emergency.
- **MAX-GUARDIANS (u5)**: The maximum number of guardians that can be assigned to a wallet.

### Maps
- **guardians (principal bool)**: A map that stores the guardians. The key is the guardian’s principal, and the value is a boolean indicating whether the address is a valid guardian.
- **has-voted (principal bool)**: A map that tracks whether a specific guardian has already voted in favor of the recovery.

---

## Functions

### 1. **set-guardian (guardian principal)**

- **Purpose**: Allows the wallet owner to add a new guardian.
- **Parameters**: 
  - `guardian` (principal): The principal address of the guardian to be added.
- **Restrictions**: 
  - Only the wallet owner can add a guardian.
  - The number of guardians must not exceed the maximum allowed (5 guardians).
- **Returns**: `ok` if successful, error otherwise.

### 2. **remove-guardian (guardian principal)**

- **Purpose**: Allows the wallet owner to remove an existing guardian.
- **Parameters**: 
  - `guardian` (principal): The principal address of the guardian to be removed.
- **Restrictions**: 
  - Only the wallet owner can remove a guardian.
  - The guardian must exist in the list of guardians.
- **Returns**: `ok` if successful, error otherwise.

### 3. **initiate-recovery (new-owner-principal principal)**

- **Purpose**: Allows a guardian to initiate the recovery process if the wallet owner has been inactive for more than the inactivity threshold.
- **Parameters**: 
  - `new-owner-principal` (principal): The address of the new wallet owner.
- **Restrictions**: 
  - The caller must be a valid guardian.
  - The wallet owner must be inactive (no activity for more than 6 months).
  - The guardian can only vote once.
- **Returns**: `true` if successful, error otherwise.

### 4. **emergency-recovery (new-owner-principal principal)**

- **Purpose**: Allows a guardian to initiate emergency recovery to transfer wallet ownership.
- **Parameters**: 
  - `new-owner-principal` (principal): The address of the new wallet owner.
- **Restrictions**: 
  - The caller must be a valid guardian.
  - The guardian can only vote once.
- **Returns**: `true` if successful, error otherwise.

### 5. **execute-recovery**

- **Purpose**: Executes the wallet recovery process after collecting the required number of recovery votes.
- **Restrictions**: 
  - The number of recovery votes must meet or exceed the `REQUIRED-VOTES` threshold.
- **Returns**: `ok` if successful, error otherwise.

### 6. **execute-emergency-recovery**

- **Purpose**: Executes the emergency recovery process after collecting the required number of emergency recovery votes.
- **Restrictions**: 
  - The number of emergency recovery votes must meet or exceed the `EMERGENCY-REQUIRED-VOTES` threshold.
- **Returns**: `ok` if successful, error otherwise.

### 7. **reset-timer**

- **Purpose**: Resets the inactivity timer. Only the wallet owner can reset the timer, indicating that the owner is still active.
- **Returns**: `ok` if successful, error otherwise.

---

## Read-Only Functions

### 1. **get-owner**

- **Purpose**: Returns the current wallet owner’s principal address.
- **Returns**: The principal address of the current owner.

### 2. **get-last-active**

- **Purpose**: Returns the block height when the wallet owner was last active.
- **Returns**: The last active block height.

### 3. **is-guardian (address principal)**

- **Purpose**: Checks if the specified address is a guardian of the wallet.
- **Returns**: `true` if the address is a guardian, `false` otherwise.

### 4. **get-recovery-votes**

- **Purpose**: Returns the current number of recovery votes collected from the guardians.
- **Returns**: The number of recovery votes.

### 5. **has-guardian-voted (address principal)**

- **Purpose**: Checks if a specified guardian has already voted for the recovery process.
- **Returns**: `true` if the guardian has voted, `false` otherwise.

### 6. **get-guardian-count**

- **Purpose**: Returns the number of guardians currently assigned to the wallet.
- **Returns**: The number of guardians.

---

## Example Usage

1. **Owner adds guardians**:
   ```clojure
   (set-guardian principal("guardian1"))
   (set-guardian principal("guardian2"))
   ```

2. **Guardian initiates recovery**:
   ```clojure
   (initiate-recovery principal("new-owner"))
   ```

3. **Guardians vote for recovery**:
   ```clojure
   (execute-recovery)
   ```

4. **Owner resets inactivity timer**:
   ```clojure
   (reset-timer)
   ```

---

## Security Considerations
- Only the wallet owner can add or remove guardians.
- Guardians can only vote once for recovery, preventing malicious actors from tampering with the process.
- The wallet’s owner can reset the inactivity timer to prevent accidental recovery if they are still active.
- The contract ensures that both inactivity-based recovery and emergency recovery require multiple guardian votes, ensuring consensus before executing the transfer of ownership.

---

This contract provides a robust and secure social recovery mechanism for a cryptocurrency wallet. By using guardians, inactivity detection, and emergency recovery, it ensures that the wallet owner can be protected in the event of incapacitation, while maintaining control and security through a decentralized recovery process.