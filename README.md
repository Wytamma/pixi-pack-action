# Pixi-Pack Action


```yaml
name: "Build for Multiple Platforms & Create Release"
on:
  push:
    tags:
      - "v*.*.*"  # e.g., "v1.0.0"

jobs:
  build-and-release:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        platform: [linux-64]
      fail-fast: false

    steps:
      - name: Check out the code
        uses: actions/checkout@v3

      - name: Run Pixi-Pack
        uses: wytamma/pixi-pack-action
        with:
          platform: ${{ matrix.platform }}
          name: example-${{ github.ref_name }}-${{ matrix.platform }}

      - name: Upload artifact
        id: upload_artifact
        uses: actions/upload-artifact@v4
        with:
          # We'll just use the extension is .ps1 or .sh
          path: "example-${{ github.ref_name }}-${{ matrix.platform }}.*"

      - name: Print URL
        run: |
          echo "==> URL: ${{ steps.upload_artifact.outputs.artifact-url }}"

      - name: Upload to Release
        uses: softprops/action-gh-release@v2
        if: startsWith(github.ref, 'refs/tags/')
        with:
          files: "*.sh, *.ps1"
```