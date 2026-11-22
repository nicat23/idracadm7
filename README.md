# ACME.sh with Dell iDRAC Support

A containerized version of the popular ACME.sh SSL certificate management tool with integrated Dell iDRAC support for enterprise server environments. This image includes Dell's `racadm` utility for seamless iDRAC certificate management and automation, built on a minimal Wolfi base image for security and efficiency.

## About

This Docker image combines the power of [acme.sh](https://github.com/acmesh-official/acme.sh) - a pure Unix shell script implementing the ACME client protocol - with Dell iDRAC management capabilities. It's designed for enterprise environments where SSL certificates need to be automatically deployed to Dell servers via iDRAC. The image is built on `nicat23/racadm:latest`, a Wolfi-based minimal image (0 CVEs) that includes Dell Server Administrator tools and the racadm CLI utility.

## Credits

- **Original ACME.sh Project**: [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)
- **ACME.sh Author**: Neil Pang and contributors
- **Dell iDRAC Integration**: This image includes Dell Server Administrator tools for iDRAC management
- **iDRAC Deployment Hook Inspiration**: The included `idrac.sh` deploy hook was inspired by [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7) and [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)

## Features

- ✅ Full ACME.sh functionality for Let's Encrypt and other ACME CAs
- ✅ Dell iDRAC integration via `racadm` command
- ✅ Automated iDRAC certificate deployment with included `idrac.sh` deploy hook
- ✅ Support for multiple DNS providers and deployment hooks
- ✅ Automatic certificate renewal via cron
- ✅ Custom deploy, DNS API, and notification scripts support
- ✅ Built on Wolfi (Chainguard) for minimal footprint and zero known CVEs
- ✅ Non-root execution for enhanced security

## Quick Start

First, start the container in detached mode using Docker Compose:

```bash
docker compose up -d
```

### Basic Certificate Issuance

```bash
docker exec -t acme.sh --issue -d example.com --standalone
```

### Automated iDRAC Certificate Deployment with Deploy Hook

Use the included `idrac.sh` deploy hook for streamlined certificate deployment:

```bash
# Set environment variables for iDRAC connection
export DEPLOY_IDRAC_HOST="192.168.1.100"
export DEPLOY_IDRAC_USER="root"
export DEPLOY_IDRAC_PASS="password"

# Issue and automatically deploy certificate to iDRAC
docker exec -t acme.sh --issue --dns dns_cf -d "idrac.example.com" --deploy-hook idrac
```

Or deploy an existing certificate:

```bash
# Deploy existing certificate using the idrac.sh hook
docker exec -t acme.sh --deploy -d "idrac.example.com" --deploy-hook idrac
```

### Manual iDRAC Certificate Deployment

```bash
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /certs/example.com/fullchain.cer
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslkeyupload -t 1 -f /certs/example.com/example.com.key
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password racreset
```

### Run as Daemon (with automatic renewals)

The `docker-compose.yml` example already runs the container as a daemon.

## Usage

### Available Commands

The container supports all standard acme.sh commands:

```bash
# Issue a certificate
docker exec -t acme.sh --issue -d example.com --dns dns_cloudflare

# Renew certificates
docker exec -t acme.sh --renew-all

# List certificates
docker exec -t acme.sh --list
```

### Dell iDRAC Management

Use the `racadm` command directly:

```bash
# Check iDRAC status
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password getconfig -g cfgRacTuning

# Upload SSL certificate to iDRAC
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /certs/example.com/fullchain.cer

# Reset the iDRAC to apply the new certificate
docket exec -t acme.sh racadm -r 192.168.1.100 -u root -p password racreset
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LE_WORKING_DIR` | `/acmebin` | ACME.sh binary directory |
| `LE_CONFIG_HOME` | `/acme.sh` | ACME.sh configuration directory |
| `LE_CERT_HOME` | `/certs` | Directory for generated certificates |
| `HOME` | `/acme.sh` | Home directory for the acme user |
| `AUTO_UPGRADE` | `0` | Enable automatic acme.sh upgrades (0 = disabled, 1 = enabled) |
| `PAGER` | `cat` | Disable pager for text output |
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP address or hostname for deploy hook |
| `DEPLOY_IDRAC_USER` | - | iDRAC username for deploy hook |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password for deploy hook |
| `TZ` | - | Timezone (e.g., `America/Chicago`, `UTC`) |

## Configuration

This container is designed to be configured through volume mounts, allowing you to persist data and customize its behavior.

### Directory Structure

- `/acmebin`: The installation/binary directory for the `acme.sh` script itself.
- `/acme.sh`: Persistent storage for `acme.sh` configuration files. Your `account.conf`, `crontab`, and other settings will be stored here.
- `/certs`: The output directory for your generated SSL certificates.
- `/hooks`: A directory for your custom scripts. You can mount your own scripts here, which will be used by `acme.sh`.
  - `/hooks/deploy`: For custom deploy hooks.
  - `/hooks/dnsapi`: For custom DNS API handlers.
  - `/hooks/notify`: For custom notification scripts.

### User and Permissions

The container runs as the non-root `acme` user (UID 1000, GID 1000) for enhanced security. All volumes should be accessible by this user. When using the image, ensure volume mounts have appropriate permissions for the acme user.

## Custom Script Structure

The image is designed with a modular and extensible architecture:

```text
├─ hooks
│  ├─ deploy
│  │  └─ idrac.sh
│  ├─ dnsapi/
│  └─ notify/
├─ init
│  └─ overlay.sh
└─ entry.sh
```

- **`hooks/deploy/idrac.sh`**: The custom deployment hook for Dell iDRAC servers, automatically copied into the acme.sh environment.
- **`init/overlay.sh`**: A startup script that copies custom hooks from `/hooks` into the acme.sh directories during container initialization.
- **`entry.sh`**: The main entrypoint script for the container that manages startup logic and command routing.

### Startup and Initialization

When the container starts:

1. **Overlay Setup**: `overlay.sh` scans the `/hooks` directory for custom scripts (`deploy`, `dnsapi`, `notify`) and copies them into the acme.sh environment.
2. **Crontab Generation**: If running in `daemon` mode without an existing crontab, one is automatically generated with randomized timing to prevent thundering herd scenarios.
3. **Command Routing**: The entry.sh script routes commands appropriately:
   - `daemon`: Starts the Supercronic daemon for automated certificate renewals
   - `--<acme.sh flag>`: Passes directly to acme.sh with proper configuration
   - Other commands: Executed as-is (e.g., `racadm`, shell commands)

## Docker Compose Example

```yaml
services:
  acme-sh:
    image: nicat23/idrac-acme.sh:v6
    build:
      context: .
    container_name: acme.sh
    user: "1000:1000"
    command: daemon
    environment:
      - TZ=America/Chicago
    volumes:
      - ./certs:/certs
      - ./hooks:/hooks
      - ./config:/acme.sh
    restart: unless-stopped
```

**Notable Changes:**
- Updated to `v6` image tag with enhanced features
- Now includes build context configuration for local builds
- Uses non-root user `1000:1000` for improved security
- Changed volume mount from `/config` to `/acme.sh` for consistency with container paths
- Uses `restart: unless-stopped` for better restart behavior
- Added timezone environment variable support

## Building from Source

You can build the Docker image locally for development or customization purposes.

### Build Command

```bash
docker build -t nicat23/idrac-acme.sh:v6 .
```

Or using docker-compose:

```bash
docker compose build
```

### Build-time Arguments

The `Dockerfile` supports several build-time arguments (`ARG`) to customize the image:

- `ACME_VERSION`: Version of ACME.sh to install (default: `3.1.0`)
- `AUTO_UPGRADE`: Set to `1` to enable automatic upgrades of `acme.sh`, or `0` to disable (default: `0`)

You can customize these during the build process. For example:

```bash
docker build --build-arg ACME_VERSION=3.1.0 --build-arg AUTO_UPGRADE=1 -t nicat23/idrac-acme.sh:v6 .
```

**Note:** The base image `nicat23/racadm:latest` is built on Chainguard Wolfi and includes Dell RACADM 11.4.0.0 compiled from RHEL 9 (x86-64-v2 compatible). See [nicat23/racadm](https://github.com/nicat23/racadm) for base image details.

### Security and Optimization

Recent updates include:
- **Wolfi-based runtime**: Chainguard Wolfi minimal distribution with 0 known CVEs and reduced attack surface
- **Multi-stage build**: Separates Dell RACADM compilation (RHEL 9) from lightweight Wolfi runtime
- **Non-root execution**: Container runs as the `acme` user (UID 1000, GID 1000) for enhanced security
- **Minimal dependencies**: Only essential packages included (ca-certificates, libstdc++, OpenSSL libraries)
- **Line-ending handling**: CRLF line endings are automatically normalized for cross-platform compatibility
- **Optimized for amd64**: Built specifically for x86-64-v2 architecture for compatibility
- **CVE security**: Base images include latest security patches and are regularly updated

## CI/CD and Automation

This repository includes GitHub Actions workflows for automated image building and publishing:

- **`.github/workflows/build.yml`**: Main build workflow that constructs and publishes Docker images to container registries
- **`.github/workflows/issue.yml`**: Automated issue handling workflow

The build workflow handles multi-platform builds and automatic image tagging, ensuring consistent deployment across different environments.

## Supported Platforms

- **`linux/amd64`**: Supported and tested. The container is built for this platform.
- **`windows`**: Tested. The container can be run on Windows with a compatible Docker environment.
- **`macOS`**: Untested.
- **`linux/arm64`**: Not supported. The Dell iDRAC tools (`racadm`) require an x86 architecture and will not run on ARM-based systems.

## License

This Docker image is provided as-is. Please refer to the original [acme.sh license](https://github.com/acmesh-official/acme.sh/blob/master/LICENSE.md) for the underlying ACME client.

## Contributing

Issues and pull requests are welcome. For major changes related to the core acme.sh functionality, please contribute to the [upstream project](https://github.com/acmesh-official/acme.sh).

## Support

- For acme.sh specific issues: [acme.sh GitHub Issues](https://github.com/acmesh-official/acme.sh/issues)
- For Dell iDRAC questions: Dell's official documentation
- For Docker image issues: Open an issue in this repository

## Links

- [acme.sh Official Repository](https://github.com/acmesh-official/acme.sh)
- [acme.sh Documentation](https://github.com/acmesh-official/acme.sh/wiki)
- [Let's Encrypt](https://letsencrypt.org/)
- [Dell iDRAC Documentation](https://www.dell.com/support/manuals/us/en/04/idrac9-lifecycle-controller-v3.30.30.30/idrac_3.30.30.30_ug/)
