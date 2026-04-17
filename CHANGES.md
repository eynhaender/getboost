# Maintenance Change Log

A developer log of non-obvious fixes made during maintenance. Each entry explains
what broke, why it broke, and what was changed to fix it.

---

## 2026-04-17 — Boost 1.90, vc143 + vc1450 (VS2022 + VS2026)

### Context

Took over maintenance from the original [eynhaender/getboost](https://github.com/eynhaender/getboost)
fork. First release under the `libbitcoin-boost` NuGet prefix. Two compiler versions were targeted:
- **vc143** — MSVC 14.3x (Visual Studio 2022 17.14)
- **vc1450** — MSVC 14.50 (Visual Studio 2026 18.0)

---

### 1. boost.bat: wrong `--stagedir` path

**Symptom:** Compiled `.lib` files landed in `boost\address-model-64\lib\` instead of
`boost\lib64-msvc-14.3\`.

**Cause:** The original `boost.bat` used `--stagedir=address-model-%5`, producing an
output directory named after the address model argument rather than the conventional
`lib<bits>-msvc-<version>` pattern that the builder scanner expects.

**Fix:** Changed `boost.bat` to:
```bat
b2 ... --stagedir=lib%5-msvc-%1
```
With `%5` = `32`/`64` and `%1` = `14.3`/`14.50`, b2 stages files to
`lib32-msvc-14.3\lib\`, `lib64-msvc-14.3\lib\`, etc.

For vc143, the already-compiled files were manually moved from `address-model-64\lib\`
into the correct `lib64-msvc-14.3\` directory directly (without the `lib\` subdirectory)
to match what the scanner then expected.

---

### 2. b2 always creates a `lib\` subdirectory inside stagedir

**Symptom:** After fixing the stagedir name, vc1450 files landed in
`lib64-msvc-14.50\lib\` — one level too deep. The builder scanner found zero packages
for vc1450.

**Cause:** `b2 stage --stagedir=<path>` unconditionally places compiled files in
`<path>\lib\`. This is b2's fixed behavior and cannot be changed. The manually moved
vc143 files had already been placed at the root of `lib64-msvc-14.3\`, so the scanner
had worked for vc143 without hitting this issue.

**Fix:** Updated `builder\builder\Program.cs` `ScanCompiledFileSet` to detect the `lib\`
subdirectory and scan it when present, falling back to the directory root otherwise:

```csharp
var libSubDir = Path.Combine(dir.FullName, "lib");
var hasLibSubDir = Directory.Exists(libSubDir);
var scanDir = hasLibSubDir ? new DirectoryInfo(libSubDir) : dir;
var fileDir = hasLibSubDir ? Path.Combine(dir.Name, "lib") : dir.Name;
```

Future builds using `boost.bat` will have files at `lib64-msvc-X.Y\lib\` and are handled
automatically. The vc143 files at the directory root continue to work as before.

---

### 3. msvc.jam did not recognise toolset 14.50

**Symptom:** Running `b2 --toolset=msvc-14.50` produced no compiled output — b2 silently
skipped the toolset.

**Cause:** `boost\tools\build\src\tools\msvc.jam` (part of the Boost source) only listed
known MSVC versions up to `14.3`. Version `14.50` was not in `.known-versions` and had no
version-specific path or environment variable entries. b2 therefore treated it as unknown
and produced no `.lib` files.

**Fix:** Patched `msvc.jam` at four locations:
- Added `14.50` to `.known-versions`
- Added a `14\.5[0-9]` branch in `generate-setup-cmd` to select the correct
  `vcvarsall.bat` path
- Added `MSVC\\14\.5[0-9]` pattern for auto-detection from the installed path
- Added `.version-14.50-path` and `.version-14.50-env = VS180COMNTOOLS`

The vswhere-based auto-detection block for `14.50` was intentionally **not** added because
b2 passes the vswhere result through a `SHELL` call that fails with an empty command string
when no vswhere query matches — this caused a visible error. Since the compiler path is
registered explicitly in `project-config.jam`, vswhere auto-detection is not needed.

Also registered the compiler explicitly in `boost\project-config.jam`:
```jam
using msvc : 14.50 : "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\cl.exe" ;
```

---

### 4. CompilerMap key mismatch: `vc150` vs `vc1450`

**Symptom:** After the b2 and scanner fixes, builder.exe crashed with:
```
KeyNotFoundException: The given key was not present in the dictionary.
   at builder.Program.CreateBinaryNuspec — Config.CompilerMap[compiler]
```

**Cause:** The compiler ID embedded in Boost filenames is derived from the toolset version
by removing the decimal point. For all previous toolsets this produced a three-digit
number:

| Toolset | Filename suffix | Digit count |
|---------|----------------|-------------|
| 14.0    | vc140          | 3           |
| 14.1    | vc141          | 3           |
| 14.2    | vc142          | 3           |
| 14.3    | vc143          | 3           |
| **14.50** | **vc1450**   | **4**       |

Because all prior versions had a single digit after the decimal, the pattern `vc1` + `X` +
`Y` happened to always yield three digits. With `14.50`, the minor version is `50` — two
digits — so removing the dot produces `1450`, a four-digit suffix: **`vc1450`**.

The original CompilerMap entry used the intuitive-but-wrong key `"vc150"` (following the
three-digit convention). The scanner extracted `vc1450` from the actual filenames, looked
up `"vc1450"` in the map, and found nothing.

**Fix:** Changed the CompilerMap key and therefore the NuGet package suffix from `vc150`
to `vc1450`:

```csharp
// builder/builder/Config.cs
{ "vc1450", new CompilerInfo("Visual Studio 2026 18.0") },
```

Published packages are named `libbitcoin-boost-vc1450`, `libbitcoin-boost_filesystem-vc1450`,
etc. This matches what Boost's own auto-linking mechanism generates at compile time, so
consuming projects link the correct libraries without any manual configuration.

---

### 5. Boost 1.90 breaking API changes (libbitcoin-system)

**Symptom:** libbitcoin-system failed to compile against the new Boost 1.90 headers.

**Cause:** Two `boost::asio::ip` functions were removed in Boost 1.90:
- `ip::address_v6::is_v4_compatible()` — removed without replacement
- `ip::address_v6::to_v4()` — replaced by `boost::asio::ip::make_address_v4(v4_mapped, ip6)`

**Fix:** Updated `libbitcoin-system/src/config/utilities.cpp`:
- Replaced `is_v4_compatible()` call with a check for `is_v4_mapped()`
- Replaced `ip6.to_v4()` with `boost::asio::ip::make_address_v4(boost::asio::ip::v4_mapped, ip6)`

Committed as a separate commit in libbitcoin-system.

---

### 6. "Failed to build Boost.Build engine" warning during b2 run

**Symptom:** The message `Failed to build Boost.Build engine` appeared in the boost.bat
output for the vc1450 build.

**Cause:** b2 attempts to recompile its own engine (`b2.exe`) from source as part of
initialisation. When the bootstrap environment differs from the compile environment (e.g.
VS2026 was newly installed), this recompilation can fail. b2 falls back to the existing
pre-built `b2.exe` automatically.

**Impact:** None. The build continued normally and all `.lib` files were produced. This is
a non-fatal warning that can be ignored as long as the existing `b2.exe` is functional.
