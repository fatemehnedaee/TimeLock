## TimeLock

Time locks are a powerful tool in the world of smart contracts, offering an added layer of security and transparency to transactions. They function by delaying the execution of specific functions within a smart contract for a predetermined amount of time.

Here's a breakdown of how time locks work:

**Basic Function**:

- A timelock smart contract acts as an intermediary between the triggering of an action and its execution.

- Upon triggering (e.g., a transaction being initiated), the timelock contract holds the action in a queue until the designated time period has elapsed.

- Once the timelock expires, the action will be executed by a person within the specified time interval.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

