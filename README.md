# unraid-images

Wrapper Docker images that back the templates in [unraid-templates](https://github.com/iknox/unraid-templates).

| Subdirectory          | Image                                       | Purpose                                          |
|-----------------------|---------------------------------------------|--------------------------------------------------|
| `garage-env/`         | `ghcr.io/iknox/garage-env`                  | Env-var-configured wrapper around Garage v2.4.1  |
| `mcp-searxng/`        | `ghcr.io/iknox/mcp-searxng`                 | MCP server exposing SearXNG search to agents     |

Each subdirectory has its own Dockerfile and README; CI builds and pushes each image to GHCR on changes to its respective subdir.

The local LLM templates (`qwen38-flash-next-gufo`, `deepseek-v4-flash-vulkan`) use kyuz0's published images directly and are not built here.
