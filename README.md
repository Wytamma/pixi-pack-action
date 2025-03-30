# Pixi-Pack Action

Using the pixi-pack action you can create packed versions of your pixi environments. This action can also be used to create install scripts for packages from these packed environments.

# Example 

We have a repo https://github.com/Wytamma/pixi-python that contains a pixi environment with python and uses the pixi-pack action to create a packed version of the environment.

The version of python in this environment can be installed using the install script command: 

```bash
curl -sSL https://github.com/Wytamma/pixi-python/releases/latest/download/install.sh | bash
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
        uses: wytamma/pixi-pack-action@v2.0.2
        with:
          platform: ${{ matrix.platform }}
          entrypoint: ${ { matrix.platform == 'linux-64' && 'python' || '' } } # create once for unix

      - name: Upload to Release
        uses: softprops/action-gh-release@v2
        with:
          files: "${{ github.event.repository.name }}-*.sh, ${{ github.event.repository.name }}-*.ps1"
```