# 11 · Windows — platform commands

*This is the platform half of the rules — read it when a rule says "your platform file gives the command."*

All commands here are PowerShell, not bash — that's the shell to reach for on Windows, including in scripts and one-liners.

## 1. Is this port free?

| Need | Command |
|---|---|
| List all listening sockets | `Get-NetTCPConnection -State Listen` |
| Check one specific port | `Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue` |
| Fallback (any Windows, any PowerShell version) | `netstat -ano \| findstr :<PORT>` |

No result for that port = free. In the `netstat` form, a line whose state column reads `LISTENING` means it's taken; the last column is the owning PID.

## 2. Host capacity before a fan-out

| Measurement | Command | Reading it |
|---|---|---|
| Logical CPU count | `$env:NUMBER_OF_PROCESSORS` (fast) or `(Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors` | a plain integer |
| Current load | `(Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue` | Windows has no direct load-average equivalent to `/proc/loadavg` — this gives instantaneous CPU utilization as a percentage; average a few samples with `-SampleInterval 2 -MaxSamples 3` for something steadier before feeding it into SUBAGENTS.md's formula. |
| Free memory | `Get-CimInstance Win32_OperatingSystem \| Select-Object FreePhysicalMemory,TotalVisibleMemorySize` | both values are in KB — divide by 1024 for MB. |

## 3. Hash a file

- Digest: `Get-FileHash -Algorithm SHA256 <file>` — the `.Hash` property is the hex digest (`(Get-FileHash -Algorithm SHA256 <file>).Hash`).
- Size and modification time: `Get-Item <file> | Select-Object Length,LastWriteTime`

## 4. A private directory only I can read (the quarantine root)

Windows has no `chmod` — a POSIX mode number like `700` is not the mechanism here. Use an explicit ACL instead: strip inheritance and grant only your own account.

```powershell
icacls <dir> /inheritance:r /grant:r "$env:USERNAME:(OI)(CI)F"
```

Verify afterward: `icacls <dir>` should list only your account with full control (no `Everyone`, no `Users`, no `Authenticated Users`); or `Get-Acl <dir> | Format-List` to see the full ACL. The cmdlet equivalent, if you need it programmatically, is `Get-Acl`/`Set-Acl` against a `DirectorySecurity` object with inheritance disabled and `FullControl` granted only to `[System.Security.Principal.WindowsIdentity]::GetCurrent().Name`.

## 5. Process holding a port / still alive / stop it

Inspect before you terminate:

1. Who holds the port: `Get-NetTCPConnection -LocalPort <PORT> -State Listen | Select-Object OwningProcess`, then `Get-Process -Id <PID>` to see what it is. Or read the PID straight off `netstat -ano | findstr :<PORT>`.
2. Is it still alive: `Get-Process -Id <PID> -ErrorAction SilentlyContinue` — returns nothing if it's already gone.
3. Stop it: `Stop-Process -Id <PID>`; add `-Force` only if a plain request doesn't make it exit.

## 6. Conventional paths on this OS

| Purpose | Path |
|---|---|
| Per-user config directory | `%LOCALAPPDATA%` (`$env:LOCALAPPDATA`, typically `C:\Users\<you>\AppData\Local`) — the closest Windows equivalent to `~/.config` |
| Quarantine root | `$env:LOCALAPPDATA\quarantine` (or `%USERPROFILE%\.quarantine` to keep the same dotted name used on the other platforms) — apply the item-4 ACL treatment to it |

## 7. Atomic move

`Move-Item <src> <dst>` is atomic (a single `MoveFileEx` call) only when both paths are on the same volume. Across volumes — a different drive letter, a mapped network share — Windows can't rename across devices, so it falls back to copy-then-delete and is no longer atomic.

**Two more caveats specific to this OS:** a Windows path is not case-sensitive, so `C:\Foo` and `c:\foo` name the same file — don't rely on case to tell quarantine targets apart. And a file with an open handle (another process still has it open) can block or fail the move outright; check with `Get-Process` against the path's owning process before moving it, not after.
