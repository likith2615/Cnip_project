#!/bin/bash
# ======================================================================
# Launch V2V Web Visualizer from WSL / Linux Terminal
# ======================================================================

echo "======================================================================"
echo " Starting V2V Web Visualizer..."
echo "======================================================================"

if command -v wslview >/dev/null 2>&1; then
    wslview visualizer/index.html
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open visualizer/index.html
elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start visualizer\\index.html
else
    echo "Please open visualizer/index.html in your web browser."
fi
