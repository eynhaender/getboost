NuGet Packages for [Boost](http://boost.org). Maintained by [libbitcoin](https://github.com/libbitcoin) as part of the Bitcoin Development Toolkit infrastructure.

Published under the `libbitcoin-boost` package family on [NuGet](https://www.nuget.org/packages/libbitcoin-boost).

- [![NuGet package](https://img.shields.io/nuget/v/libbitcoin-boost.svg?label=libbitcoin-boost)](https://nuget.org/packages/libbitcoin-boost)
- [![NuGet package](https://img.shields.io/nuget/v/libbitcoin-boost-vc145.svg?label=libbitcoin-boost-vc145)](https://nuget.org/packages/libbitcoin-boost-vc145)
- [![NuGet package](https://img.shields.io/nuget/v/libbitcoin-boost-vc143.svg?label=libbitcoin-boost-vc143)](https://nuget.org/packages/libbitcoin-boost-vc143)
- [![NuGet package](https://img.shields.io/nuget/v/libbitcoin-boost-vc142.svg?label=libbitcoin-boost-vc142)](https://nuget.org/packages/libbitcoin-boost-vc142)
- [![NuGet package](https://img.shields.io/nuget/v/libbitcoin-boost-vc141.svg?label=libbitcoin-boost-vc141)](https://nuget.org/packages/libbitcoin-boost-vc141)

# Releases

- [1.91](releases/1.91.md)
- [1.90](releases/1.90.md)
- [1.87](releases/1.87.md)
- [1.86](releases/1.86.md)
- [1.85](releases/1.85.md)
- [1.84](releases/1.84.md)
- [1.83](releases/1.83.md)
- [1.82](releases/1.82.md)
- [1.81](releases/1.81.md)
- [1.80](releases/1.80.md)
- [1.79](releases/1.79.md)
- [1.78](releases/1.78.md)
- [1.77](releases/1.77.md)
- [1.76](releases/1.76.md)
- [1.75](releases/1.75.md)
- [1.74](releases/1.74.md)
- [1.73](releases/1.73.md)
- [1.72](releases/1.72.md)
- [1.71](releases/1.71.md)
- [1.70](releases/1.70.md)
- [1.69](releases/1.69.md)
- [1.68](releases/1.68.md)
- [1.67](releases/1.67.md)
- [1.66](releases/1.66.md)
- [1.65.1](releases/1.65.1.md)
- [1.65](releases/1.65.md)
- [1.64](releases/1.64.md)
- [1.63](releases/1.63.md)
- [1.62](releases/1.62.md)
- [1.61](releases/1.61.md)

# For Developers

## Building Boost

1. Download Boost from [boost.org](http://boost.org/) and unpack it in the parent folder of getboost.
2. Rename the unpacked folder to `boost` (so the path is `../boost` relative to getboost).
3. Run [boost.bat](boost.bat) from the `getboost` directory. This invokes `b2` for all
   enabled toolsets and may take several hours.
   - Currently enabled: **vc145** (Visual Studio 2026, MSVC 14.5)
   - Compiled files land in `boost\lib32-msvc-14.5\lib\` and `boost\lib64-msvc-14.5\lib\`.

## Building NuGet Packages

1. Build the builder project (once per code change):
   ```cmd
   msbuild builder\builder\builder.csproj /p:Configuration=Debug
   ```
   Or open [builder\builder.sln](builder/builder.sln) in Visual Studio and build there.
2. Run the builder to generate and publish packages:
   ```cmd
   cd builder\builder\bin\Debug
   builder.exe
   ```
   To generate locally without pushing to NuGet:
   ```cmd
   builder.exe --local
   ```
3. Packages appear in `builder\builder\bin\Debug\` as `*.nupkg` files.
4. Publishing requires `builder\builder\ApiKey.cs` with a valid NuGet API key
   (gitignored — create it manually, never commit it).

## Compiler Toolset History

| NuGet suffix | MSVC toolset | Visual Studio | Boost versions |
|---|---|---|---|
| `vc145`  | 14.5  | 2026 (v145) | 1.91+ |
| `vc1450` | 14.50 | 2026 (v145, pre-release patch) | 1.90 only |
| `vc143`  | 14.3x | 2022 | 1.78–1.90 |
| `vc142`  | 14.2x | 2019 | 1.70–1.90 |
| `vc141`  | 14.1x | 2017 | 1.65–1.90 |
