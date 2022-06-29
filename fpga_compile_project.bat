@echo off
rem 1. Выходная папка для Sof должна быть задана в проекте Quartus(\output_files)
rem 2. Выходная папка для Jic должна быть определена в файле sof2jic.cof(\output_files)
rem 3. Файлы bat, NAME_PRJ_QPF.qpf и sof2jic.cof должны находится в одном каталоге 

set pwd=%cd%
FOR %%i IN ("%pwd%\*.qpf") DO Set NAME_PRJ_QPF="%%i"
@echo Progect FPGA: %NAME_PRJ_QPF%
@echo Directory Project: %pwd%
@echo Directory Quartus Root: %QUARTUS_ROOTDIR%

@echo START FPGA COMPILE
rem cd %DIR_PRJ_QPF%
@echo Clean Project...
%QUARTUS_ROOTDIR%\bin64\quartus_sh --clean %NAME_PRJ_QPF% 
@echo Compile Project...
%QUARTUS_ROOTDIR%\bin64\quartus_sh --flow compile %NAME_PRJ_QPF% 
@echo Convert Sof2Jic...
%QUARTUS_ROOTDIR%\bin64\quartus_cpf -c sof2jic.cof 
@echo Sof and Jic files founded on %pwd%\output_files
@echo END FPGA COMPILE
