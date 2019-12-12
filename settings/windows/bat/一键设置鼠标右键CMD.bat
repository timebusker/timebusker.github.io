REG ADD "HKCR\*\shell\Cmd\command" /ve /t REG_EXPAND_SZ /d %ComSpec%  
REG ADD "HKCR\Directory\shell\Cmd\command" /ve /t REG_EXPAND_SZ /d "%ComSpec% /k cd %1"  
REG ADD "HKCR\Drive\shell\Cmd\command" /ve /t REG_EXPAND_SZ /d "%ComSpec% /k cd %1"  