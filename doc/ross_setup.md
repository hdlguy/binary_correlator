# These are notes on how to setup to use Ross AI through Claude Code under Ubuntu 24.04LTS.

## Install Claude Code CLI

## Setup Xilinx Vivado and Vitis
source /tools/Xilinx/2025.2/Vivado/settings64.sh; source /tools/Xilinx/2025.2/Vitis/settings64.sh;
Note: Version 2026.1 has limitations. Version 2025.2 works better with Ross.

## Download the Vivado MCP Server
https://www.amd.com/en/support/downloads/ross-agentic-ai.html

## Register Ross MCP and Documents with Claude
claude mcp add --scope user vivado -- /home/pedro/tools/ross/vivado-mcp-server-linux-amd64-2026.9.1 --stdio-bridge
claude mcp add --scope user --transport http amd-doc-search https://ross.amd.com/mcp/doc-search
claude mcp list

## Add Xilinx FPGA skills to claude
cd ~/tools/ross
git clone https://github.com/Xilinx/ross-ai-assistant.git
npx skills add ~/tools/ross/ross-ai-assistant --all --global
ls ~/.claude/skills/

## Start Claude
claude
or
claude --resume # to resume the previous session.
