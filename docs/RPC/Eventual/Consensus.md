# Consensus Module

### `getSendDifficulty`

`getSendDifficulty` replies with a Send Difficulty. It takes in one argument:
- Merit Holder (int): Optional; defaults to -1.

The result is a string of the current difficulty if the Merit Holder is -1, or if it isn't, what the specified Merit Holder voted. If the Merit Holder does have any votes, an empty string will be returned.

### `getDataDifficulty`

`getDataDifficulty` replies with a Data Difficulty. It takes in one argument:
- Merit Holder (int): Optional; defaults to -1.

The result is a string of the current difficulty if the Merit Holder is -1, or if it isn't, what the specified Merit Holder voted. If the Merit Holder does have any votes, an empty string will be returned.

### `getGasPrice`

`getGasPrice` replies with the current Gas Price. It takes in one argument:
- Merit Holder (string): Optional; defaults to null.

The result is int of the gas price if the Merit Holder is null, or if it isn't, what the specified Merit Holder voted.

### `getStatus`

`getStatus` replies with the Status for the specified Transaction. It takes in one argument:
- hash (string)

The result is an object, as follows:
- `verifiers`  (array of strings): The list of verifiers for this Transaction.
- `merit`      (int):              Merit of all the Merit Holders who verified this Transaction.
- `threshold`  (int):              Merit needed to become verified.
- `verified`   (bool):             Whether or not the Transaction is verified.
- `competing` (bool):              Whether or not the Transaction has competitors. If it does, and isn't already verified, it can only be verified at the end of its Epoch.

### `publishSignedVerification`

`publishSignedVerification` parses the serialized Signed Verification, adds it to the local Consensus DAG, and if it's valid, publishes it. It takes in one argument.
- Signed Verification (string)

The result is a bool of true.

### `publishSignedSendDifficulty`

`publishSignedSendDifficulty` parses the serialized Signed Send Difficulty, adds it to the local Consensus DAG, and if it's valid, publishes it. It takes in one argument.
- Signed Send Difficulty (string)

The result is a bool of true.

### `publishSignedDataDifficulty`

`publishSignedDataDifficulty` parses the serialized Signed Data Difficulty, adds it to the local Consensus DAG, and if it's valid, publishes it. It takes in one argument.
- Signed Data Difficulty (string)

The result is a bool of true.

### `publishSignedGasPrice`

`publishSignedGasPrice` parses the serialized Signed Gas Price, adds it to the local Consensus DAG, and if it's valid, publishes it. It takes in one argument.
- Signed Gas Price (string)

The result is a bool of true.

### `publishSignedMeritRemoval`

`publishMeritRemoval` parses the serialized Signed Merit Removal, adds it to the local Consensus DAG, and if it's valid, publishes it. It takes in one argument.
- Signed Merit Removal (string)

The result is a bool of true.
