BINARY_LINK=$HOME/.local/bin/accio-brew

link_binary() {
  command -v accio-brew >/dev/null && return
  mkdir -p "$(dirname "$BINARY_LINK")"
  ln -sf "$TOOL_ROOT/bin/accio-brew" "$BINARY_LINK"
  case ":$PATH:" in
    *":$(dirname "$BINARY_LINK"):"*) ;;
    *) echo "Add accio-brew to your PATH: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
}
