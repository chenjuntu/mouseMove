:loop
mouseActions.exe rightClick
timeout /t 5
mouseActions.exe moveby 10x10
timeout /t 5
mouseActions.exe leftClick
timeout /t 5
mouseActions.exe moveby -10x-10
timeout /t 50
goto loop