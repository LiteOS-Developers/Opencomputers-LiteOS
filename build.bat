@echo off

pushd %~dp0
if not exist "build" mkdir build
cd build
if not exist "Users" mkdir Users
if not exist "Mount" mkdir Mount
cd ..
echo Coping files and directories
robocopy src\Bin\ build\Bin > NUL
robocopy src\System\ build\System > NUL

robocopy src\System\Kernel build\System\Kernel >NUL
robocopy src\System\Kernel\modules build\System\Kernel\modules
robocopy src\System\keyboards build\System\keyboards >NUL
robocopy src\System\Lib build\System\Lib >NUL
robocopy src\System\Services build\System\Services >NUL

robocopy src\Lib\ build\Lib > NUL
robocopy src\Config\ build\Config > NUL
copy src\init.lua build\init.lua > NUL
copy README.md build\README.md > NUL
copy LICENSE build\LICENSE > NUL
echo DONE
popd
pause