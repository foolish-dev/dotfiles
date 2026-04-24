# Open Code — ROG Zephyrus G14 Configuration

This is the agent configuration for **Open Code** (opencode.ai) integrated into your dotfiles environment.

## Quick Start

```bash
# 1. Ensure HexStrike server is running (for hexstrike-ai tools):
cd ~/dotfiles && source hexstrike-env/bin/activate && python3 hexstrike_server.py --quiet &

# 2. Restart Open Code and select this agent config:
opencode restart
# → In the UI, go to Settings → Agents → Select "Open Code — ROG Zephyrus G14 Optimized"
```

## Tools Available

### HexStrike AI MCP (`hexstrike-ai`)

Access **150+ cybersecurity tools** via HTTP API at `http://127.0.0.1:8888`:

| Tool | Use Case | Example Command |
|------|----------|-----------------|
| `nmap` / `rustscan` / `masscan` | Port scanning & service detection | `/hexstrike rustscan -r 192.168.1.0/24 --top-ports 1000` |
| `nikto` / `zap` / `nuclei` | Web vulnerability scanning | `/hexstrike nuclei -u https://target.com --severity high,medium --tags cve,rce,lfi` |
| `sqlmap` | SQL injection testing | `/hexstrike sqlmap -u "http://target/page?id=1"` |
| `dirsearch` / `ffuf` / `gobuster` | Directory/file discovery | `/hexstrike dirsearch -u https://target.com --extensions php,html,js,txt,json --threads 50` |
| `wafw00f` | WAF fingerprinting | `/hexstrike wafw00f target.com` |

**Command reference:** See the full list in [`agents.json`](./agents.json).

### SuperClaude Sequential Thinking (`superclaude-sequential-thinking`)

Multi-step problem solving with systematic code analysis:

| Command | Use Case |
|---------|----------|
| `/sc:pm` | Project management session (task breakdown, progress tracking) |
| `/sc:research` | Deep research with systematic information gathering |
| `/sc:implement` | Code implementation assistance |
| `/sc:code-review` | Code review and improvement suggestions |

### SuperClaude Context7 (`superclaude-context7`)

Official library documentation search across npm, pypi, maven, crates.io.

**Command:** `/sc:context7 search "package-name"` — Search for docs/examples

### LM Studio Models (`lmstudio`)

Local LLM inference with these models configured:

| Model | VRAM (4-bit) | Use Case |
|-------|--------------|----------|
| `crow-9b-heretic-4.6` | ~7GB | Default — open-source coding assistant |
| `qwen3.5-9b-claude-4.6...` | ~8GB | Bilingual (EN/Chinese) reasoning + thinking model |
| `gemma-3-12b-it-heretic` | ~7GB | Google's open model for code tasks |

### SuperClaude Playwright / Chrome DevTools

Additional MCP servers for E2E testing and debugging (see [`agents.json`](./agents.json)).

## Agents

| Agent | Description | Entry Point |
|-------|-------------|-------------|
| `@hexstrike-analyst` | Security research assistant — conducts authorized vulnerability assessments and CTF recon | `/hexstrike analyze --help` |
| `@superclaude-architect` | Codebase architect — understands, diagrams, navigates complex projects | `/sc:pm` |
| `@superclaude-expert` | Library documentation & testing expert | `/sc:context7 search query` |

## Mode Settings

```json
{
  "default": "direct",        // Use tools directly when appropriate
  "explanations": true,       // Explain reasoning/decisions
  "thinkAloud": false,        // Don't stream internal thoughts (unless asked)
  "avoidBragging": true,      // No self-congratulation
  "verboseReasoning": false   // Concise output by default
}
```

## Security Notice

The `@hexstrike-analyst` agent has access to **150+ security tools**. Always:

- Verify authorization before scanning any target
- Use for CTF challenges, authorized pentesting engagements, or educational exercises only
- Respect rate limits and avoid aggressive scanning of internet-exposed systems

## Troubleshooting

**HexStrike server not responding?**

```bash
# Check if running
ps aux | grep hexstrike_server

# Restart
cd ~/dotfiles && source hexstrike-env/bin/activate && python3 hexstrike_server.py --quiet &

# Health check (wait ~10s after restart)
curl -s http://127.0.0.1:8888/health | jq '.'
```

**LM Studio not responding?**
- Check LM Studio is running and models are loaded in the UI
- Default model: `crow-9b-heretic-4.6` at `http://127.0.0.1:1234/v1`

---

For the full dotfiles setup guide, see [`README.md`](../../dotfiles/README.md).
