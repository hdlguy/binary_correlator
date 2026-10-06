# These are notes on how to setup to use Ross AI through Claude Code.

## Setup Xilinx Vivado
source /tools/Xilinx/2026.1/Vivado/settings64.sh; source /tools/Xilinx/2026.1/Vitis/settings64.sh;

## Register Vivado MCP and Documents with Claude
claude mcp add --scope user vivado -- /home/pedro/tools/ross/vivado-mcp-server-linux-amd64-2026.9.1 --stdio-bridge
claude mcp add --scope user --transport http amd-doc-search https://ross.amd.com/mcp/doc-search
claude mcp list

## Add Xilinx FPGA skills to claude
cd ~/tools/ross
git clone https://github.com/Xilinx/ross-ai-assistant.git
npx skills add ~/tools/ross/ross-ai-assistant --all --global
ls ~/.claude/skills/


