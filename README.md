# Cursed Ascent Starknet Contracts

## Requirements

- `Python3.9` (for `cairo-lang-0.10.0`)
- Docker

## Installation

- If not done before, [install Cairo](https://www.cairo-lang.org/docs/quickstart.html#visual-studio-code-setup):

```sh
sudo apt install -y libgmp3-dev
python3.9 -m venv ~/cairo_venv
source ~/cairo_venv/bin/activate
```

- Install [protostar](https://docs.swmansion.com/protostar/docs/tutorials/introduction):

```sh
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash

# Check if protostar works in a new terminal.
protostar -v
```

- Pull the [`starknet-devnet`](https://github.com/Shard-Labs/starknet-devnet) image for local tests:

```sh
docker pull shardlabs/starknet-devnet:latest
```

---
