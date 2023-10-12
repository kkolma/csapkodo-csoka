z80asm.exe csoka.asm -b
@ECHO OFF
IF %ERRORLEVEL% NEQ 0 (
   echo "Ez bizony hibas. Megpedig ezert itt fent, ni!"
   EXIT /B
)
h2CreateHtp -t csoka.txt -b csoka.bin -L 18432 -o csoka.htp -B csoka.bas
htp2h2wav -i csoka.htp -o csoka.wav

C:\Users\kolma\Documents\homelab\emu-grosz\HomelabX64.exe
