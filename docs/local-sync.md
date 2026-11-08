# Local Sync

Rsync-over-SSH sync of home config paths (and optional project dirs) to another machine on the LAN. **Sender wins on conflicts.**

## Prerequisites

## Usage

```sh
./scripts/sync-local.sh [options] <host>
```

`host`: SSH target, e.g. `laptop.local` or `user@192.168.1.50`.

### Options

| Option              | Description                                                                |
| ------------------- | -------------------------------------------------------------------------- |
| `-p, --project DIR` | Project dir to sync (repeatable, must be under `$HOME`)                    |
| `-n, --dry-run`     | Show what would transfer, write nothing                                    |
| `-d, --delete`      | Delete remote files that no longer exist locally                           |
| `-h, --help`        | Show help                                                                  |
| `-r, --receive`     | On receiver, show the command to run on the sender based on its IP address |
