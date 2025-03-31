# Pixi-Pack Action

Using the pixi-pack action you can automatically create cross-platform self-extracting binaries that contains your pixi environments.

See also the [pixi-pack-install-script action](https://github.com/Wytamma/pixi-pack-install-script) that can be used to create install scripts for packages from your environments.

# Example 

We have a repo https://github.com/Wytamma/pixi-python that contains a pixi environment with python and uses the pixi-pack action to create a packed version of the environment for mac, linux and windows when a release is created.

The exact environment can be reproduced by running the following commands:

```bash
# Download the environment
wget https://github.com/Wytamma/pixi-python/releases/download/v1.0.8/pixi-python-v1.0.8-osx-arm64.sh -O environment.sh
# Setup the environment
chmod +x environment.sh
./environment.sh
# Activate the environment
source ./environment.sh
```

# Example Workflow

```yaml
name: "Build for Multiple Platforms & Create Release"
on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-and-release:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        platform: ["osx-arm64", "linux-64", "win-64"]
      fail-fast: false

    steps:
      - name: Check out the code
        uses: actions/checkout@v3

      - name: Run Pixi-Pack
        uses: wytamma/pixi-pack-action@v4
        with:
          platform: ${{ matrix.platform }}

      - name: Upload to Release
        uses: softprops/action-gh-release@v2
        with:
          files: "${{ github.event.repository.name }}-*.sh, ${{ github.event.repository.name }}-*.ps1"
```