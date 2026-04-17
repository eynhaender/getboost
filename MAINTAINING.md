# Maintaining getboost

NuGet packages for Boost, maintained by [libbitcoin](https://github.com/libbitcoin).
Published under the `libbitcoin-boost` prefix on [nuget.org](https://nuget.org).

## Release Checklist

### 1. Download new Boost source

**Stable release:** Download from [boost.org](https://www.boost.org/users/download/) and unpack to:

```
C:\Users\<you>\source\repos\boost\
```

**Pre-release / HEAD build:** Clone from GitHub with all submodules:

```cmd
cd C:\Users\<you>\source\repos
git clone --recursive --depth=1 https://github.com/boostorg/boost.git boost
```

The directory must be named exactly `boost` and sit next to the `getboost` repo.

### 2. Update version in Config.cs

Open [builder/builder/Config.cs](builder/builder/Config.cs) and update the version number.

Stable release:
```csharp
public static readonly Version Version = new StableVersion(1, 91, 0);
```

Pre-release / HEAD build (appends `-head` suffix to all NuGet package versions,
distinguishing them from the eventual stable release):
```csharp
public static readonly Version Version = new UnstableVersion(1, 91, 0, "head");
```

### 3. Bootstrap b2

Run once after downloading a new Boost source tree:

```cmd
cd C:\Users\<you>\source\repos\boost
bootstrap.bat
```

If bootstrap fails with "Failed to build Boost.Build engine" (happens when `vswhere.exe`
is not in PATH), build b2 manually from a VS Developer Command Prompt:

```cmd
cd tools\build\src\engine
build.bat vc145
copy b2.exe ..\..\..\..
```

Then add the VS2026 compiler to `project-config.jam` (created by bootstrap):

```jam
using msvc : 14.5 : "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\cl.exe" ;
```

Note: Boost 1.91+ uses toolset version `14.5` (not `14.50`). The msvc.jam in Boost 1.91
natively recognises VS2026 — no patching required.

### 4. Build Boost binaries

Run from the `getboost` directory:

```cmd
cd C:\Users\<you>\source\repos\getboost
boost.bat
```

This calls Boost's own `b2` build system and stages compiled `.lib` files into:

```
repos\boost\lib32-msvc-14.5\lib\    (x86, vc145)
repos\boost\lib64-msvc-14.5\lib\    (x64, vc145)
```

Build time: 2–6 hours per compiler version. Only toolsets listed in `boost.bat` are built.

### 5. Build and publish NuGet packages

Open [builder/builder.sln](builder/builder.sln) in Visual Studio, build the solution, then run:

```cmd
cd C:\Users\<you>\source\repos\getboost\builder\builder\bin\Debug
builder.exe
```

The builder scans all `lib*-msvc-*` directories automatically, generates `.nuspec` files,
packs them, and pushes to nuget.org. To test locally without publishing:

```cmd
builder.exe --local
```

### 6. Add release notes

Create `releases\1.91.md` by copying the previous release file and updating the version
and package list. Then add the new entry to [readme.md](readme.md).

### 7. Commit and push

```cmd
git add builder/builder/Config.cs releases/1.91.md readme.md
git commit -m "Boost 1.91.0"
git push
```

---

## Compiler Version Reference

| VS Version | MSVC Toolset | `_MSC_VER` | b2 toolset | NuGet suffix | auto_link.hpp |
|---|---|---|---|---|---|
| VS2017 | 14.1x | 1910–1919 | `msvc-14.1` | `vc141` | `"vc141"` |
| VS2019 | 14.2x | 1920–1929 | `msvc-14.2` | `vc142` | `"vc142"` |
| VS2022 | 14.3x | 1930–1949 | `msvc-14.3` | `vc143` | `"vc143"` |
| VS2026 | 14.50 | 1950+ | `msvc-14.5` | `vc145` | `"vc145"` (Boost 1.91+) |

**Important:** Boost 1.90's `auto_link.hpp` does not know VS2026 — all MSVC >= 1930
falls into the `"vc143"` catch-all. For VS2026 support, Boost 1.91 or later is required.

**Note on `vc1450`:** The Boost 1.90 packages for VS2026 are named `vc1450` because
Boost 1.90's b2 toolset was registered as `14.50` (patched manually). These packages
are not reachable via auto-linking and should not be used. Boost 1.91+ standardises
on `vc145` throughout.

---

## Adding a New Compiler Version

When a new Visual Studio is released:

**1. Find the MSVC toolset version:**

```cmd
dir "C:\Program Files\Microsoft Visual Studio\<VS_VERSION>\Community\VC\Tools\MSVC\"
```

**2. Check Boost's `auto_link.hpp`** (in the new Boost source) to find the toolset
string Boost will use for the new compiler. This determines the NuGet package suffix.

**3. Register the compiler in `project-config.jam`:**

```jam
using msvc : <version> : "<path to cl.exe>" ;
```

**4. Enable the toolset in [boost.bat](boost.bat):**

```bat
call :link <version>
```

**5. Add the compiler to [builder/builder/Config.cs](builder/builder/Config.cs):**

```csharp
{ "vc145", new CompilerInfo("Visual Studio 2026 18.0") },
```

Then follow the standard release checklist above.

---

## Directory Layout

```
repos\
  boost\                 Boost source + compiled binaries (not in git)
  getboost\
    boost.bat            Builds Boost binaries via b2
    builder\
      builder\
        Config.cs        Version number, compiler map, package prefix, BoostDir path
        Nuspec.cs        NuGet metadata (licenseUrl, projectUrl)
        Program.cs       Main entry point, scans lib dirs, generates packages
        ApiKey.cs        NuGet API key (gitignored, create manually)
```

## NuGet API Key

The file `builder/builder/ApiKey.cs` is gitignored and must be created manually:

```csharp
namespace builder
{
    static class ApiKey
    {
        public static readonly string Value = "YOUR-NUGET-API-KEY";
    }
}
```

Generate a key at [nuget.org](https://www.nuget.org) → Account → API Keys.
Use glob pattern `libbitcoin-boost*` and permission `Push new packages and package versions`.

---

## Package Naming

| Package | Description |
|---|---|
| `libbitcoin-boost` | Header-only (all Boost headers) |
| `libbitcoin-boost-vc143` | Metapackage: depends on all compiled libraries for vc143 |
| `libbitcoin-boost_filesystem-vc143` | Individual compiled library |

To switch to the original `boost` naming (e.g. after taking over the original NuGet IDs),
set `PackagePrefix = ""` in [Config.cs](builder/builder/Config.cs).
