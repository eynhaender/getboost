echo on
cd ..\boost\

call bootstrap.bat

b2 headers

rem Supported toolsets: vc141 (VS2017), vc142 (VS2019), vc143 (VS2022), vc145 (VS2026)
rem Boost 1.91+ uses toolset version 14.5 (auto_link generates "vc145").
rem Boost 1.90 used 14.50 (non-standard patch) -- kept below for reference.
rem Add 'call :link XX.X' for additional compiler versions as needed.

call :link 14.5
rem call :link 14.3
rem call :link 14.2
rem call :link 14.1
rem call :link 14.50  (Boost 1.90 only, non-standard)

goto :eof

:link
echo link {
echo toolset=%1
echo }
call :threading %1 shared shared
call :threading %1 static shared
call :threading %1 static static
goto :eof

:threading
echo threading {
echo toolset=%1
echo link=%2
echo runtime-link=%3
echo }
call :address_model %1 %2 %3 single
call :address_model %1 %2 %3 multi
goto :eof

:address_model
echo address_model {
echo toolset=%1
echo link=%2
echo runtime-link=%3
echo threading=%4
echo }
call :build %1 %2 %3 %4 x86 32 lib32
call :build %1 %2 %3 %4 x86 64 lib64
rem ARM64 requires the VS component "MSVC Build Tools for ARM64/ARM64EC (Latest)".
rem abi=aapcs selects Boost.Context's armasm64 fcontext sources; this also needs the
rem winfib override in boost\libs\context\build\Jamfile.v2 removed (see MAINTAINING.md).
rem The stacktrace backends are forced because b2 can't run its ARM64 detection
rem checks on an x64 host; this matches what x64 builds (windbg + windbg_cached).
rem Quoted because cmd splits unquoted arguments at "=".
call :build %1 %2 %3 %4 arm 64 libarm64 "abi=aapcs boost.stacktrace.windbg=on boost.stacktrace.windbg_cached=on boost.stacktrace.basic=off"
goto :eof

:build
echo build {
echo toolset=%1
echo link=%2
echo runtime-link=%3
echo threading=%4
echo architecture=%5
echo address-model=%6
echo }
b2 architecture=%5 link=%2 runtime-link=%3 threading=%4 address-model=%6 %~8 stage --stagedir=%7-msvc-%1 --toolset=msvc-%1 --without-python --without-mpi
goto :eof
