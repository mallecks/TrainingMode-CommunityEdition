@echo off
setlocal
setlocal enabledelayedexpansion

REM set directory to location of this file. Needed when drag n dropping across directories.
cd /d %~dp0

set ISO="%~1"

if %ISO%=="" (
    echo ERROR: iso path not passed
    echo USAGE: build_windows.bat vanilla_melee.iso
    goto end
) else (
    echo iso: %ISO%
)

if not exist %ISO% (
    echo ERROR: iso does not exist
    echo USAGE: build_windows.bat vanilla_melee.iso
    goto end
)

if not exist "C:/devkitPro/devkitPPC" (
    echo ERROR: devkitPro not found at "C:/devkitPro/devkitPPC"
    echo Please install devkitPro with the GameCube package
    goto cleanup
) else (
    echo found devkitPro
    set "PATH=%PATH%;C:\devkitPro\devkitPPC\bin"
)

if not exist "TM-CE.iso" (
    copy %ISO% "TM-CE.iso"
)

echo BUILD C FILES --------------------------------------------------------

mkdir build

REM Dynamically generate header inclusion for events
> build/generated_include_meta.h (
    echo // Auto-generated include list
    for /D %%D in (src\events\*) do (
        echo #include "../src/events/%%~nxD/%%~nxD_meta.h"
    )
)

> build/generated_include_meta.c (
    echo // Auto-generated include list
    for /D %%D in (src\events\*) do (
        echo #include "../src/events/%%~nxD/%%~nxD_meta.c"
    )
)
echo build event menu
copy "dats\eventMenu.dat" "build\eventMenu.dat"
"MexTK/MexTK.exe" -ff -i "src/events.c" "src/event_data.c" "build/generated_include_meta.c" -b "build" -s tmFunction -dat "build/eventMenu.dat" -t "MexTK/tmFunction.txt" -q -ow -l "MexTK/melee.link" -op 2 || ( echo ERROR: Failed to compile 'events.c' & goto cleanup )
"MexTK/MexTK.exe" -trim "build/eventMenu.dat" || ( echo ERROR: Dat file trimming failed & goto cleanup )

echo build lab css
copy "src\events\lab\labCSS.dat" "build\labCSS.dat"
"MexTK/MexTK.exe" -ff -i "src/events/lab/lab_css.c" -b "build" -s cssFunction -dat "build/labCSS.dat" -t "MexTK/cssFunction.txt" -q -ow -l "MexTK/melee.link" -op 2 || ( echo ERROR: Failed to compile 'lab_css.c' & goto cleanup)
"MexTK/MexTK.exe" -trim "build/labCSS.dat" || ( echo ERROR: Dat file trimming failed & goto cleanup )

REM Loop for compiling the events written in c
for /D %%D in (src\events\*) do (
    REM Build event if it has a c file
    if exist "src/events/%%~nxD/%%~nxD.c" (
       echo build %%~nxD event

       REM Copy dat file if it exists
       if exist "src/events/%%~nxD/%%~nxD.dat" (
         copy "src\events\%%~nxD\%%~nxD.dat" "build\%%~nxD.dat"
       )

      "MexTK/MexTK.exe" -ff -i "src/events/%%~nxD/%%~nxD.c" -b "build" -s evFunction -dat "build/%%~nxD.dat" -t "MexTK/evFunction.txt" -q -ow -l "MexTK/melee.link" -op 2 || ( echo ERROR: Failed to compile '%%~nxD.c' & goto cleanup)
      "MexTK/MexTK.exe" -trim "build/%%~nxD.dat" || ( echo ERROR: Dat file trimming failed & goto cleanup )
    )
)
echo BUILD ASM FILES --------------------------------------------------------

REM Dynamically generate asm inclusion for events
> build/generated_include_events.asm (
    echo #Auto-generated include list
    for /R src\events %%F in (*.asm) do (
        for %%D in (%%~dpF.) do (
            echo .include "../src/events/%%~nxD/%%~nxD.asm"
        )
    )
)
del "Additional ISO Files\codes.gct"
cd "Build TM Codeset"
echo gecko.exe build

REM gecko always returns success, so we check that the file exists after building as a replacement
gecko.exe build
cd ..
if not exist "Additional ISO Files\codes.gct" (
    echo ERROR: gecko.exe build failed
    goto cleanup
)

copy "Additional ISO Files\codes.gct" "build\"
copy "Additional ISO Files\opening.bnr" "build\"


echo BUILD START.DOL --------------------------------------------------------

for /f "delims=" %%A in ('gc_fst get-header %ISO%') do set "GAME_ID=%%A"
if "%GAME_ID%" == "GALJ01" (
	set "PATCH_FILENAME=patch_jp.xdelta"
) else (
	set "PATCH_FILENAME=patch.xdelta"
)

gc_fst read %ISO% "Start.dol" "Start.dol"
"Build TM Start.dol\xdelta.exe" -d -f -s "Start.dol" "Build TM Start.dol\%PATCH_FILENAME%" "build\Start.dol" || ( echo ERROR: Failed to patch Start.dol & goto cleanup )
del Start.dol

echo BUILD ISO --------------------------------------------------------

REM It is assumed that dats in build directory are events and that those specific
REM files do not have an insert order. This method was used to preserve the order
REM of the other commands. If a dat file needs to be loaded before/after other
REM dat files, the loop needs updated to included it at the correct spot

set GC_FST_CMD=delete MvHowto.mth delete MvOmake15.mth delete MvOpen.mth

    for %%F in (build\*.dat) do (
            set GC_FST_CMD=!GC_FST_CMD! insert TM\%%~nxF build\%%~nxF
    )

set GC_FST_CMD=!GC_FST_CMD! insert codes.gct build\codes.gct insert Start.dol build\Start.dol insert opening.bnr build\opening.bnr

gc_fst fs TM-CE.iso !GC_FST_CMD!

gc_fst set-header TM-CE.iso "GTME01" "Training Mode Community Edition"

echo ############ TM-CE.iso has been created ######################

:cleanup

echo CLEANUP -----------------------------------------------------------------

if exist "build" (
    echo deleting build dir...
    rmdir /s /q build\
)

:end

REM pause if not run from command line
echo %CMDCMDLINE% | findstr /C:"/c">nul && pause
