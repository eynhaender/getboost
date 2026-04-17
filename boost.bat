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
call :build %1 %2 %3 %4 32
call :build %1 %2 %3 %4 64
goto :eof

:build
echo build {
echo toolset=%1
echo link=%2
echo runtime-link=%3
echo threading=%4
echo address-model=%5
echo }
b2 architecture=x86 link=%2 runtime-link=%3 threading=%4 address-model=%5 stage --stagedir=lib%5-msvc-%1 --toolset=msvc-%1 --without-python --without-mpi
goto :eof
