# Install mise - Bitrise Step

This Bitrise step installs [mise](https://mise.jdx.dev/) (formerly rtx), a polyglot runtime manager that can manage multiple language runtimes like Node.js, Python, Ruby, Go, and more.

## Features

- Install mise with a specific version or latest
- Automatically run `mise trust` for configuration files
- Automatically run `mise install` to install tools
- Add shims to PATH for seamless tool access
- Works on both Linux and macOS

## Usage

Add this step to your `bitrise.yml`:

```yaml
workflows:
  primary:
    steps:
      - git::https://github.com/kexi/bitrise-step-mise.git@main:
          title: Install mise
          inputs:
            - mise_version: latest
            - run_trust: "yes"
            - run_install: "yes"
            - use_shims: "yes"
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `mise_version` | `latest` | The version of mise to install. Use "latest" for the latest stable version. |
| `run_trust` | `yes` | Whether to run `mise trust` after installation. |
| `run_install` | `yes` | Whether to run `mise install` after installation. |
| `working_dir` | `$BITRISE_SOURCE_DIR` | The directory where mise commands will be executed. |
| `use_shims` | `yes` | Whether to add the mise shims directory to PATH. |
| `github_token` | (empty) | GitHub token to avoid API rate limiting when installing tools from GitHub. |

## Outputs

| Output | Description |
|--------|-------------|
| `MISE_BIN_PATH` | The path to the mise binary. |
| `MISE_SHIMS_PATH` | The path to the mise shims directory. |

## Configuration Files

This step supports the following mise configuration files:

- `mise.toml`
- `.mise.toml`
- `.tool-versions`

If no configuration file is found, `mise trust` and `mise install` will be skipped without error.

## Examples

### Basic Usage

```yaml
- git::https://github.com/kexi/bitrise-step-mise.git@main:
    title: Install mise
```

### Install Specific Version

```yaml
- git::https://github.com/kexi/bitrise-step-mise.git@main:
    title: Install mise v2024.1.0
    inputs:
      - mise_version: "v2024.1.0"
```

### Skip Trust and Install

```yaml
- git::https://github.com/kexi/bitrise-step-mise.git@main:
    title: Install mise only
    inputs:
      - run_trust: "no"
      - run_install: "no"
```

### Custom Working Directory

```yaml
- git::https://github.com/kexi/bitrise-step-mise.git@main:
    title: Install mise
    inputs:
      - working_dir: "$BITRISE_SOURCE_DIR/frontend"
```

### With GitHub Token (Avoid Rate Limiting)

When installing tools from GitHub (e.g., pnpm, deno), you may hit API rate limits. Use a GitHub token to avoid 403 errors:

```yaml
- git::https://github.com/kexi/bitrise-step-mise.git@main:
    title: Install mise
    inputs:
      - github_token: "$GITHUB_ACCESS_TOKEN"
```

## Local Testing

You can test this step locally using the Bitrise CLI:

```bash
# Run all tests
bitrise run test

# Run specific test
bitrise run test_default
```

## License

MIT License - see [LICENSE](LICENSE) for details.
