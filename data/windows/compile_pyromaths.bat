REM @echo off
REM Crée l'installateur Windows
set builddir=C:\Users\%username%\BUILD-pyromaths\
C:
cd "C:\Users\%username%\"
python -m venv %builddir%

%builddir%\Scripts\python -m pip install --upgrade pip
%builddir%\Scripts\python -m pip install --upgrade lxml 
%builddir%\Scripts\python -m pip install --upgrade PyQt5 
%builddir%\Scripts\python -m pip install --upgrade PyQt5-sip
%builddir%\Scripts\python -m pip install --upgrade jinja2
%builddir%\Scripts\python -m pip install --upgrade markupsafe
%builddir%\Scripts\python -m pip install --upgrade pyromaths
%builddir%\Scripts\python -m pip install --upgrade pynsist

cd "%builddir%"
copy \\VBOXSVR\pyromaths-qt\dist\pyromaths-qt-21.8.zip . /y /B
"c:\Program Files\7-Zip\7z.exe" x pyromaths-qt-21.8.zip
del pyromaths-qt-21.8.zip
cd pyromaths-qt-21.8
cd data\windows\
mkdir extra_wheel
robocopy \\VBOXSVR\pyromaths-qt\extra_wheel extra_wheel 
%builddir%\Scripts\pynsist.exe installer.cfg

copy build\nsis\Pyromaths-QT_21.8.2.exe \\VBOXSVR\pyromaths-qt\dist /Y
copy build\nsis\Pyromaths-QT_21.8.2.exe "C:\Users\%username%\Desktop" /Y

cd "%builddir%"
REM rmdir /Q /S pyromaths-qt-21.8
