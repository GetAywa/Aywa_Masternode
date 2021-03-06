@echo off
rem *****************************************************************
rem ***************USER VALUES***************************************
rem *****************************************************************
set REMOTE_IP=000.000.000.000
set EXTERNAL_IP=000.000.000.000
set AYWA_DATADIR=%HOMEDRIVE%%HOMEPATH%\AppData\Roaming\AywaCore
set TEMP_PATH=%HOMEDRIVE%%HOMEPATH%\tmp
set SSH_PATH=%HOMEDRIVE%%HOMEPATH%\tmp\ssh
set SSH_USER=*******
set SSH_PASS=********
set AYWACORE_CLI_PATH=%PROGRAMFILES%\AywaCore\daemon
set /a REMOTE_PORT_START=20771
set /a REMOTE_RPCPORT_START=30771
set MN_COUNT=5
set MN_NAME_PREFIX=MN1__
set MN_USER=aywa
set MN_USER_PASS=********
rem *****************************************************************
rem *****************************************************************
rem *****************************************************************

cd %TEMP_PATH%
curl -L -O https://the.earth.li/~sgtatham/putty/latest/w32/plink.exe
plink.exe %REMOTE_IP% -l %SSH_USER% -pw %SSH_PASS% "cd ~ && mkdir -p tmp && cd tmp && rm -f * && wget https://raw.githubusercontent.com/GetAywa/Aywa_Masternode/master/mn_prepare.sh && chmod 777 mn_prepare.sh && sudo -S ./mn_prepare.sh %MN_COUNT% %MN_USER% %MN_USER_PASS%&& rm -f mn_prepare.sh"
curl -L -O https://the.earth.li/~sgtatham/putty/latest/w32/pscp.exe
copy pscp.exe %SSH_PATH%
curl -L -O https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.2.0p1-Beta/OpenSSH-Win32.zip
powershell Expand-Archive -Path OpenSSH-Win32.zip -DestinationPath %TEMP_PATH%
mkdir %SSH_PATH%
copy %TEMP_PATH%\OpenSSH-Win32\ssh.exe %SSH_PATH% 
copy %TEMP_PATH%\OpenSSH-Win32\libcrypto.dll %SSH_PATH% 
del %TEMP_PATH%\OpenSSH-Win32\ /Q
rmdir %TEMP_PATH%\OpenSSH-Win32\
del OpenSSH-Win32.zip

rem curl -L -O http://downloads.sourceforge.net/gnuwin32/openssl-0.9.8h-1-bin.zip
rem mkdir %TEMP_PATH%\OpenSSL
rem powershell Expand-Archive -Path openssl-0.9.8h-1-bin.zip -DestinationPath %TEMP_PATH%\OpenSSL
rem copy %TEMP_PATH%\OpenSSL\openssl.exe %SSH_PATH% 
rem del %TEMP_PATH%\OpenSSL\ /Q
rem rmdir %TEMP_PATH%\OpenSSL\
rem del openssl-0.9.8h-1-bin.zip

rem "%SSH_PATH%\ssh.exe" %SSH_USER%@%REMOTE_IP% "cd ~ && mkdir -p tmp && cd tmp && rm -f * && wget https://raw.githubusercontent.com/GetAywa/Aywa_Masternode/master/mn_prepare.sh && chmod 777 mn_prepare.sh && sudo -S ./mn_prepare.sh %MN_COUNT% %MN_USER% %MN_USER_PASS%&& rm -f mn_prepare.sh"
@echo off
rem echo "Wait for server reboot then press a key."
pause 120

rem ****************generate utxo***********************
echo "Will be created %MN_COUNT% transaction(s) for masternodes. Press Ctrl+C to break or any key to continue"
del %TEMP_PATH%\conf /Q 
rmdir %TEMP_PATH%\conf
mkdir %TEMP_PATH%\conf
%HOMEDRIVE% && cd %TEMP_PATH%\conf
for /f "tokens=*" %%a in ('"%AYWACORE_CLI_PATH%\aywa-cli.exe" getbalance') do set CURRENT_BALANCE=%%a
echo Your current balance is: %CURRENT_BALANCE%
for /f "tokens=*" %%a in ('"%AYWACORE_CLI_PATH%\aywa-cli.exe" masternode cost') do set MASTERNODE_COST=%%a
echo Current Masternode cost: %MASTERNODE_COST%
@echo off
set /a REMOTE_PORT=%REMOTE_PORT_START%
set /a REMOTE_RPC_PORT=%REMOTE_RPCPORT_START%
set /a MN_COUNT=%MN_COUNT%
FOR /L %%G IN (1,1,%MN_COUNT%) DO (
rem echo Creating MN UTXO %%G
SET COUNTER=%%G
@echo off
call:create_tx
)

rem set REMOTE_COMMAND= 
echo wil be copied conf files to remote server
pause 0
FOR /L %%G IN (1,1,%MN_COUNT%) DO (
echo Copy aywa.conf file %%G
"%SSH_PATH%\pscp.exe" -pw %MN_USER_PASS% %TEMP_PATH%\conf\%MN_NAME_PREFIX%%%Gaywa.conf %MN_USER%@%REMOTE_IP%:/home/%MN_USER%/.masternodes/node%%G/aywa.conf
rem "%SSH_PATH%\putty.exe" %SSH_USER%@%REMOTE_IP%
rem set REMOTE_COMMAND=(%REMOTE_COMMAND%)""(crontab -l; echo "@reboot echo "rebooted%%G"";) | crontab - &&""
)

echo %REMOTE_COMMAND%


rem ********************************************************
echo Now start 1 (only one - first) wallet ann allow it to sync to the last block
echo (You can copy blocks from any of your server: rsvnc -avz ~/.aywacore/blocks ~/.aywacore/chainstate user@192.168.1.68:~/.masternodes/node1)
echo establish ssh connection with you server 


plink.exe %REMOTE_IP% -l %SSH_USER% -pw %SSH_PASS% "/home/%MN_USER%/aywacore/bin/aywad -datadir=/home/%MN_USER%/.masternodes/node1 && watch /home/%MN_USER%/aywacore/bin/aywacli -datadir=/home/%MN_USER%/.masternodes/node1 getinfo"

echo Command to start: /home/user/aywacore/bin/aywad -datadir=/home/user/.masternodes/node1
pause 0

echo After sync stop wallet and copy ~/.masternodes/node1/chainstate ~/.masternodes/node1/blocks to ~/.masternodes/node$COUNTER

rem here is command

echo Wait full sync. Ctrl+C to continue and copy blockchain data

watch /home/user/aywacore/bin/aywa-cli -datadir=/home/user/.masternodes/node1 getinfo

pause 0
for i in {2..%MN_COUNT%}; do echo "Node $i"  && cp -vr /home/user/.masternodes/node1/chainstate /home/user/.masternodes/node1/blocks /home/user/.masternodes/node$i; done

rem if node doesnt have public IP
set /a REMOTE_PORT_END=%REMOTE_PORT_START%+%MN_COUNT%
#sudo iptables -t nat -I OUTPUT -d %EXTERNAL_IP% -p tcp  -j REDIRECT --to-ports %REMOTE_PORT_START%-%REMOTE_PORT_END%
rem sudo crontab -e
rem example: sudo iptables -t nat -I OUTPUT -d %EXTERNAL_IP% -p tcp  -j REDIRECT --to-ports 20771-20870

rem start 10 wallets
#for i in {1..50}; do echo "Node $i starting"  && /home/user/aywacore/bin/aywad -datadir=/home/user/.masternodes/node$i; done; 

rem check status
#for i in {1..10}; do echo "Node $i info:"  && /home/user/aywacore/bin/aywa-cli -datadir=/home/user/.masternodes/node$i getinfo; done;

rem wait until wallets sync ang has at least 5 connections

rem start 10 MNs
rem add logs folder 
mkdir /home/user/.masternodes/logs

rem add crontab -e
rem ***************
rem * * * * * cd /home/user/.masternodes/node1/sentinel && SENTINEL_DEBUG=1 /home/user/Aywa_Masternode/sentinel/.venv/bin/python bin/sentinel.py > /home/user/.masternodes/logs/sentinel1.log
rem @reboot /home/user/aywacore/bin/aywad -datadir=/home/user/.masternodes/node1> /home/user/.masternodes/logs/start_aywad1.log
rem *****************************************

rem start MNs from local wallet
rem if ENABLE status for 1-10 Mns

rem start next ones
rem copy data
#for i in {11..100}; do echo "Node $i"  && cp -vr /home/user/.masternodes/node1/chainstate /home/user/.masternodes/node1/blocks /home/user/.masternodes/node$i; done
rem start it
for i in {11..100}; do echo "Node $i starting"  && /home/user/aywacore/bin/aywad -datadir=/home/user/.masternodes/node$i; done;


EXIT /B %ERRORLEVEL%

:create_tx
@echo off
for /f "tokens=*" %%a in ('"%AYWACORE_CLI_PATH%\aywa-cli.exe" getnewaddress %MN_NAME_PREFIX%%COUNTER%') do set NEW_ADDRESS=%%a
echo Created new address: %NEW_ADDRESS%
for /f "tokens=*" %%b in ('"%AYWACORE_CLI_PATH%\aywa-cli.exe" sendtoaddress %NEW_ADDRESS% %MASTERNODE_COST%') do set MN_UTXO=%%b
echo Created MN UTXO id (collateral_output_txid):%MN_UTXO%
for /f "tokens=*" %%c in ('"%AYWACORE_CLI_PATH%\aywa-cli.exe" masternode genkey') do set MN_GENKEY=%%c
echo Generated MN key (masternodeprivkey):%MN_GENKEY%
							  
rem for /f "tokens=*" %%d in ('""%AYWACORE_CLI_PATH%\aywa-cli.exe" lockunspent false"[{\"txid\":\"%MN_UTXO%\" ","\"vout\":%MASTERNODE_COST%}]""') do set MN_UTXO_LOCKRESULT=%%d

for /f "tokens=*" %%d in ('""%AYWACORE_CLI_PATH%\aywa-cli.exe" lockunspent false "[{\"txid\":\"%MN_UTXO%\" ","\"vout\":1}]""') do set MN_UTXO_LOCKRESULT=%%d

echo UTXO %MN_UTXO% lock result: %MN_UTXO_LOCKRESULT%
rem pause 0
echo Adding line to %AYWA_DATADIR%\masternode.conf: %MN_NAME_PREFIX%%COUNTER% %REMOTE_IP%:%REMOTE_PORT% %MN_GENKEY% %MN_UTXO% 1

echo %MN_NAME_PREFIX%%COUNTER% %EXTERNAL_IP%:%REMOTE_PORT% %MN_GENKEY% %MN_UTXO% 1 >>%AYWA_DATADIR%\masternode.conf
(
echo rpcuser=aywauser%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%
echo rpcpassword=rpcpass%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%
echo rpcallowip=127.0.0.1
echo listen=1
echo server=1
echo daemon=1
echo smsgdisable=1
echo port=%REMOTE_PORT%
echo rpcport=%REMOTE_RPC_PORT%
echo masternode=1
echo masternodeprivkey=%MN_GENKEY%
echo masternodeaddr=%EXTERNAL_IP%:%REMOTE_PORT%
echo externalip=%EXTERNAL_IP%
)>%MN_NAME_PREFIX%%COUNTER%aywa.conf


set /a REMOTE_PORT=%REMOTE_PORT%+1
set /a REMOTE_RPC_PORT=%REMOTE_RPC_PORT%+1
