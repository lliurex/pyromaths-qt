@echo off
REM Crée l'installateur Windows
C:
REM A effectuer la 1re fois, après avoir installé Python-3.6.5
REM cd "C:\Users\%username%\"
REM C:\Python36-32\python -m venv C:\Users\%username%\BUILD-pyromaths

C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade pip
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade lxml 
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade PyQt5 
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade jinja2
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade markupsafe
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade sip
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade pyromaths
C:\Users\%username%\BUILD-pyromaths\Scripts\python -m pip install --upgrade pynsist

cd "C:\Users\%username%\BUILD-pyromaths"
copy e:\dist\pyromaths-qt-*.zip . /y /B
"c:\Program Files\7-Zip\7z.exe" x pyromaths-qt-*.zip
del pyromaths-qt-*.zip
cd pyromaths-qt-*
for %%I in (.) do set version=%%~nxI
set version=%version:~13%
echo %version%
REM copy data\windows\installer.cfg .
cd data\windows\
mkdir extra_wheel
copy e:\dist\pyromaths_qt-%version%-py3-none-any.whl extra_wheel /y /B
C:\Users\%username%\BUILD-pyromaths\Scripts\pynsist.exe installer.cfg

copy build\nsis\Pyromaths-QT_%version%.exe e:\dist /Y
copy build\nsis\Pyromaths-QT_%version%.exe "C:\Users\%username%\Desktop" /Y

cd "C:\Users\%username%\BUILD-pyromaths"
REM rmdir /Q /S pyromaths-qt-%version%