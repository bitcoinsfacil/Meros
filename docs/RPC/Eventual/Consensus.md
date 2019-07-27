# Consensus Module

### `getElement`

`getElement` replies with the specified Element. It takes in two arguments:
- Merit Holder (string)
- Nonce        (int)

The result is an object, as follows:
- `descendant` (string)
- `holder`     (string)
- `nonce`      (int)

    When `descendant` == "verification":
    - `hash` (string)

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