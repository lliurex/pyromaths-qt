@echo off
REM Crée l'installateur Windows
C:
REM A effectuer la 1re fois, après avoir installé Python-3.6.5
REM cd "C:\Users\%username%\"
REM C:\Python36-32\python -m venv C:\Users\%username%\BUILD-pyromaths-py3

C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade pip
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade lxml 
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade PyQt5 
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade jinja2
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade markupsafe
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade sip
REM C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade pypiwin32
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\python -m pip install --upgrade pynsist

cd "C:\Users\%username%\BUILD-pyromaths-py3"
copy e:\dist\pyromaths-*.zip . /y /B
"c:\Program Files\7-Zip\7z.exe" x pyromaths-*.zip
del pyromaths-*.zip
cd pyromaths-*
for %%I in (.) do set version=%%~nxI
set version=%version:~10%
copy data\windows\installer.cfg .
C:\Users\%username%\BUILD-pyromaths-py3\Scripts\pynsist.exe installer.cfg

copy build\nsis\pyromaths_%version%.exe e:\dist /Y

cd "C:\Users\%username%\BUILD-pyromaths-py3"
rmdir /Q /S pyromaths-%version%