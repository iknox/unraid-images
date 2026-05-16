# unraid-images

Wrapper Docker images that back the templates in [unraid-templates](https://github.com/iknox/unraid-templates).

| Subdirectory          | Image                                       | Purpose                                          |
|-----------------------|---------------------------------------------|--------------------------------------------------|
| `garage-env/`         | `ghcr.io/iknox/garage-env`                  | Env-var-configured wrapper around Garage v2.3.0  |
| `wyoming-kokoro-cpu/` | `ghcr.io/iknox/wyoming-kokoro-cpu`          | CPU-only Kokoro TTS over the Wyoming protocol    |

Each subdirectory has its own Dockerfile and README; CI builds and pushes each image to GHCR on changes to its respective subdir.
