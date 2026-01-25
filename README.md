# proc-scan

Lightweight Process Integrity Verifier  
Cross-layer anomaly detection for Linux systems

---

## Abstract

`proc-scan` is a minimalistic integrity verification utility designed to detect discrepancies between kernel-exposed process structures and userland process enumeration tools.

It performs cross-validation between:

- `/proc` (kernel-backed process view)
- `ps -e` (userland enumeration)

Any inconsistency may indicate stealth techniques such as userland hooking, process hiding, or unstable system state.

The tool is read-only and introduces no kernel modifications.

---

## Threat Model

proc-scan is designed to identify:

- Userland process hiding via LD_PRELOAD or library hooks
- Tampered `ps` output
- Inconsistent enumeration between kernel and userland
- Suspicious orphaned entries
- Race-condition terminations during scan window

It does **not** detect:
- Kernel-level rootkits modifying `/proc`
- eBPF stealth injection
- Advanced DKOM manipulation
- Hypervisor-based stealth

---

## Architecture

Detection logic is based on simple set reconciliation:

1. Collect PID set from `/proc`
2. Collect PID set from `ps`
3. Compute symmetric differences
4. Classify anomalies

This avoids heuristic scoring and instead relies on deterministic mismatch detection.

---

## Output Semantics

| Status                    | Meaning |
|---------------------------|----------|
| HIDDEN (ROOTKIT?)         | PID exists in `/proc` but not returned by `ps` |
| DIED (Race Condition)     | PID listed in `ps` but no longer exists in `/proc` |
| SECURE                    | No inconsistencies detected |

---

## Usage

### Prebuilt Binary

Download from Releases.

#### Linux (x86_64)

```bash
chmod +x versa-hsl-linux-x86_64
./versa-hsl-linux-x86_64
```

#### Linux (aarch64)

```bash
chmod +x versa-hsl-linux-aarch64
./versa-hsl-linux-aarch64
```

#### Windows (x86_64)

```
versa-hsl-windows-x86_64.exe
```

No GHC required.

---

### Build From Source

Requirements:
- GHC 9.x

```bash
git clone https://github.com/VersaNexusIX/proc-scan.git
cd proc-scan
ghc -O2 r.hs -o proc-scan
./proc-scan
```

---

## Security Considerations

- False positives may occur due to rapid process termination.
- Results should be validated with additional tooling (e.g., `top`, `htop`, `strace`, or forensic frameworks).
- Designed as a triage-level detector, not a full forensic suite.

---

## Design Principles

- Deterministic behavior
- No background services
- No external network calls
- Minimal dependency footprint
- Clear terminal output
- Single-file architecture

---

## Roadmap

Potential future enhancements:

- Direct syscall-based enumeration
- `/proc/<pid>/status` integrity verification
- Timing delta analysis
- Kernel timestamp comparison
- Anti-hook validation checks

---

## License

Apache-2.0 License

---

## Author

VersaNexusIX
