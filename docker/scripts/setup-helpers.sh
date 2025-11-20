#!/bin/bash

echo "Setting up Docker helper scripts..."

# Make helper scripts executable
chmod +x artisan artisan-debug composer test shell 2>/dev/null

echo "✓ Helper scripts are now executable"
echo ""
echo "Available commands:"
echo "  ./artisan [command]      - Run artisan commands as www user"
echo "  ./artisan-debug [cmd]    - Run artisan commands with Xdebug enabled"
echo "  ./composer [command]     - Run composer commands as www user"
echo "  ./test [options]         - Run tests as www user"
echo "  ./shell                  - Access container bash as www user"
echo ""
echo "Optional: Add shell aliases to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "  alias artisan='./docker/scripts/artisan'"
echo "  alias composer='./docker/scripts/composer'"
echo "  alias test='./docker/scripts/test'"
echo "  alias shell='./docker/scripts/shell'"
echo ""
echo "Then run: source ~/.bashrc  (or source ~/.zshrc)"
echo ""
echo "⚠️  IMPORTANT: Always use these helpers or add --user www flag"
echo "    Never run: docker compose exec app [command]"
echo "    Always run: docker compose exec --user www app [command]"
echo ""
