;---------------------------------------------------------------------------安装包 解压空白---------------------------------------------------------------------
!system '>blank set/p=MSCF<nul'
!packhdr temp.dat 'cmd /c Copy /b temp.dat /b +blank&&del blank'

;--------------------------------------------------------------------------------定义变量-----------------------------------------------------------------------
Var Dialog
Var MessageBoxHandle
Var InstallPath
Var FreeSpaceSize
var DefaultInstallDir
Var InstalledDirectory ;已安装目录
Var InstalledVersion ;已安装版本
Var NeedSpace
Var SpaceNotEnough

;-------------------------------------------------------------------------------初始定义常量---------------------------------------------------------------------

!define UNINSTALL_DIR "$TEMP\nsis\setup"
!define SHCNE_ASSOCCHANGED 0x08000000 ;刷新关联图标
!define SHCNF_IDLIST 0
!define MUI_FINISHPAGE_NOREBOOTSUPPORTs ; 安装不需要重启

;--------------------------------------------------------------------------------注册表常量-----------------------------------------------------------------------
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetOverwrite on ;设置文件覆盖标记
SetCompress auto ;设置压缩选项
SetCompressor /SOLID lzma ;选择压缩方式
SetCompressorDictSize 32
SetDatablockOptimize on ;设置数据块优化
SetDateSave on ;设置在数据中写入文件时间
AllowRootDirInstall false ; 是否允许安装在根目录下
RequestExecutionLevel admin ;Request application privileges for Windows Vista

Unicode false ;设置Unicode 编码 3.0以上版本支持

LicenseName "115浏览器"
LicenseKey "8749afbd7acf4a170be5614d512d9522"

;------------------------------------------------------------------------------------------引入的头文件-------------------------------------------------------------------------------------
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "WordFunc.nsh"
!include "ParameterInfo.nsi"
!insertmacro MUI_LANGUAGE "SimpChinese" ;Languages

;-------------------------------------------------------------------------------------------安装和卸载页面-----------------------------------------------------------------------------------
Page         custom     InstallPage
Page         instfiles  "" InstallShow
UninstPage   custom     un.UninstallPage
UninstPage   instfiles	""	un.UninstallNow

Function .onInit
	SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
;--------------------------------------------------------------------------------------------初始化主窗体UI----------------------------------------------------------------------------------
	nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "InstallPackages.xml" "WizardTab" "false" "115浏览器" "8749afbd7acf4a170be5614d512d9522" "source\app.ico" "false"
	Pop $Dialog
;----------------------------------------------------------------------------------------------初始化MessageBoxUI----------------------------------------------------------------------------
	nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
	Pop $MessageBoxHandle

;创建互斥防止重复运行
	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "xiaonengInstall") i .r1 ?e'
	Pop $R0
	StrCmp $R0 0 +3
	nsSkinEngine::NSISMessageBox "" "有一个 ${PRODUCT_NAME} 安装向导已经运行！"
	Abort

;强制结束进程
	KillProcDLL::KillProc "${MAIN_APP_NAME}.exe"

  StrCpy $NeedSpace "150MB"
  StrCpy $SpaceNotEnough "1" ;磁盘空间不足标识

	Call ReadRegFunc
FunctionEnd

Function InstallPage
;--------------------------------------------------------------------------------------------首页按钮事件绑定----------------------------------------------------------------------------------
;关闭按钮绑定函数
	nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have InstallTab_sysCloseBtn"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn" $0
	${EndIf}

;立即安装
	nsSkinEngine::NSISFindControl "InstallBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 InstallPageFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallBtn"  $0
	${EndIf}

;自定义安装
	nsSkinEngine::NSISFindControl "custom_Installation_Text"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPageFunc
		nsSkinEngine::NSISOnControlBindNSISScript "custom_Installation_Text"  $0
	${EndIf}

	nsSkinEngine::NSISSetControlData "autoSetupCheckBox"  "true" "Checked" ;默认勾选运行程序
;--------------------------------------------------------------------------------------------自定义页面按钮事件绑定------------------------------------------------------------------------------
;浏览
	nsSkinEngine::NSISFindControl "InstallTab_SelectFilePathBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_SelectFilePathBtn button"
	${Else}
		GetFunctionAddress $0 OnInstallPathBrownBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_SelectFilePathBtn"  $0
	${EndIf}

;取消
	nsSkinEngine::NSISFindControl "InstallTab_CancleBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPage_CancleBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_CancleBtn"  $0
	${EndIf}

;立即安装
	nsSkinEngine::NSISFindControl "InstallTab_InstallNowBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPage_InstallNowBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallNowBtn"  $0
	${EndIf}
;--------------------------------------------------------------------------------------------------------安装进度页面按钮事件绑定-----------------------------------------------------------------------
;关闭按钮绑定函数
	nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn1"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have InstallTab_sysCloseBtn1"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn1" $0
	${EndIf}

;设置进度条
	nsSkinEngine::NSISFindControl "InstallProgressBar"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallProgressBar"
	${Else}
		;隐藏progressBar
		nsSkinEngine::NSISSetControlData "InstallProgressBar"  "false"  "visible"
	${EndIf}
;--------------------------------------------------------------------------------------------------------完成页面按钮事件绑定------------------------------------------------------------------------------------
;立即使用
	nsSkinEngine::NSISFindControl "InstallTab_UseNowBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_UseNowBtn button"
	${Else}
		GetFunctionAddress $0 CompletePage_UseNowBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_UseNowBtn"  $0
	${EndIf}
;--------------------------------------------------------------------------------------------窗体显示--------------------------------------------------------------------------------
	nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

;关闭按钮事件
Function OnInstallCancelFunc
	nsSkinEngine::NSISMessageBox "" " 确定要退出 ${PRODUCT_NAME} 的安装？"
	Pop $0
	${If} $0 == "1"
		nsSkinEngine::NSISExitSkinEngine "false"
	${EndIf}
FunctionEnd

;首页 ——> 立即安装
Function InstallPageFunc
	nsSkinEngine::NSISNextTab "WizardTab"

;设置进度条
	nsSkinEngine::NSISFindControl "InstallProgressBar"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallProgressBar"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallProgressBar"  "0"  "ProgressInt"
		nsSkinEngine::NSISSetControlData "InstallProgressText"  "0%"  "text"
		nsSkinEngine::NSISStartInstall "false"
	${EndIf}
FunctionEnd

Function InstallShow
	nsSkinEngine::NSISFindControl "gifImage"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have gifImage"
	${Else}
		nsSkinEngine::NSISSetControlData "gifImage" "true" "visible"
	${EndIf}
	
	;nsSkinEngine::NSISFindControl "circleImageControl"
	;Pop $0
	;${If} $0 == "-1"
	;	nsSkinEngine::NSISMessageBox "" "Do not have circleImageControl"
	;${Else}
	;	nsSkinEngine::NSISSetControlData "circleImageControl" "true" "visible"
	;${EndIf}
	
	
	;GetFunctionAddress $0 goAheadCallback
  ;GetFunctionAddress $1 retreatCallback
  ;nsSkinEngine::NSISInitAnimationBkControl "circleImageControl" "${UNINSTALL_DIR}\progressImage" "100" "0" "1" "1" "0" $0 $1
  ;nsSkinEngine::NSISStartAnimationBkControl "circleImageControl" "0" "30"
  ;nsSkinEngine::NSISSetControlData "welcomeText"  "false"  "visible"
  ;nsSkinEngine::NSISRunSkinEngine "true"
	

	nsSkinEngine::NSISFindControl "InstallProgressBar"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallProgressBar"
	${Else}
		nsSkinEngine::NSISBindingProgress "InstallProgressBar" "InstallProgressText"
	${EndIf}
FunctionEnd

Function goAheadCallback
   
FunctionEnd

Function retreatCallback
    
FunctionEnd

;首页 ——> 自定义按钮事件函数
Function CustomInstallPageFunc
	nsSkinEngine::NSISNextTab "WizardTab"
	nsSkinEngine::NSISNextTab "WizardTab"

	StrCpy	$DefaultInstallDir $INSTDIR

;安装路径编辑框设定数据
	nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_InstallFilePath"
	${Else}
		GetFunctionAddress $0 OnTextChangeFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallFilePath" $0
		nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath" $INSTDIR "text"
		Call OnTextChangeFunc
	${EndIf}
FunctionEnd

;自定义页面 ——> 浏览按钮选择安装路径
Function OnInstallPathBrownBtnFunc
	nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text"
	Pop $InstallPath
	nsSkinEngine::NSISSelectFolderDialog "请选择文件夹" $InstallPath
	Pop $InstallPath

	StrCpy $0 $InstallPath
	${If} $0 == "-1"
	${Else}
		StrCpy $INSTDIR "$installPath\${MAIN_APP_NAME}"
		;设置安装路径编辑框文本
		nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
		Pop $0
		${If} $0 == "-1"
			nsSkinEngine::NSISMessageBox "" "Do not have Wizard_InstallPathBtn4Page2 button"
		${Else}
			;nsSkinEngine::SetText2Control "InstallTab_InstallFilePath"  $installPath
			nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath"  $INSTDIR  "text"
		${EndIf}
	${EndIf}
	Call UpdateFreeSpace
	Call FreshInstallDataStatusFunc
FunctionEnd

;自定义页面 ——> 取消按钮事件函数
Function CustomInstallPage_CancleBtnFunc
	nsSkinEngine::NSISBackTab "WizardTab"
	nsSkinEngine::NSISBackTab "WizardTab"
	Call restoreInstallParamValue
FunctionEnd

;自定义页面 ——> 立即安装按钮事件函数
Function CustomInstallPage_InstallNowBtnFunc
	nsSkinEngine::NSISBackTab "WizardTab"
	nsSkinEngine::NSISBackTab "WizardTab"
	Call InstallPageFunc
FunctionEnd

;完成页面 ——> 立即使用按钮事件函数
Function CompletePage_UseNowBtnFunc
	Exec "$INSTDIR\${MAIN_APP_NAME}.exe"
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

Function OnTextChangeFunc
; 改变可用磁盘空间大小
	nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text"
	Pop $0
	;nsSkinEngine::NSISMessageBox "" $0
	StrCpy $INSTDIR $0

;重新获取磁盘空间
	Call UpdateFreeSpace
	Call FreshInstallDataStatusFunc
FunctionEnd

Function UpdateFreeSpace
	${GetRoot} $INSTDIR $0
  StrCpy $1 "Bytes"

  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
  ${If} $0 > 1024
  ${OrIf} $0 < 0
    System::Int64Op $0 / 1024
    Pop $0
    StrCpy $1 "KB"
    ${If} $0 > 1024
    ${OrIf} $0 < 0
    	System::Int64Op $0 / 1024
    	Pop $0
    	StrCpy $1 "MB"
    	${If} $0 > 1024
    	${OrIf} $0 < 0
      	System::Int64Op $0 / 1024
      	Pop $0
      	StrCpy $1 "GB"
    	${EndIf}
  	${EndIf}
  ${EndIf}

  IntFmt $0 "%d" "$0"
  IntFmt $2 "%d" "$NeedSpace"
  IntOp $2 $2 + 2

  StrCpy $SpaceNotEnough "1"

  ${If} $1 == "KB"
		Call SpaceIsNotEnough

  ${EndIf}
  ${If} $1 == "Bytes"
    Call SpaceIsNotEnough

  ${EndIf}
  ${If} $1 == "MB"

    ${If} $2 >= $0
			Call SpaceIsNotEnough
		${EndIf}

  ${EndIf}

  ${If} $SpaceNotEnough == "1"
    nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace" "#FF333333" "textcolor"
    nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "true" "enable"
		nsSkinEngine::NSISSetControlData "InstallBtn" "ture" "enable"
  ${EndIf}

  StrCpy $FreeSpaceSize  "所需空间：$NeedSpace       可用空间：$0$1"
FunctionEnd

Function SpaceIsNotEnough
  StrCpy $SpaceNotEnough "0"
  nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace" "#FFBC1717" "enable"
  nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "false" "enable"
	nsSkinEngine::NSISSetControlData "InstallBtn" "false" "enable"
FunctionEnd

Function FreshInstallDataStatusFunc
;更新磁盘空间文本显示
	nsSkinEngine::NSISFindControl "InstallTab_FreeSpace"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_FreeSpace"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace"  "$FreeSpaceSize"  "text"
	${EndIf}

;路径是否合法（合法则不为0Bytes）
	${If} $FreeSpaceSize == "0Bytes"
		nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "false" "enable"
		nsSkinEngine::NSISSetControlData "InstallBtn" "false" "enable"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "true" "enable"
		nsSkinEngine::NSISSetControlData "InstallBtn" "true" "enable"
	${EndIf}
FunctionEnd

;刷新关联图标
Function RefreshShellIcons
	System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
	(${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function restoreInstallParamValue
;还原安装路径
	StrCpy $INSTDIR $DefaultInstallDir

;还原安装语言
	nsSkinEngine::NSISSetControlData "setupLanguage_Combo"  "0"  "CurrentIndex"

;还原开机启动
	nsSkinEngine::NSISSetControlData "autoSetupCheckBox"  "true" "Checked"
FunctionEnd

Section InstallFiles
;安装前卸载
	Call SteupBefforeUninstall

	SetOutPath "$INSTDIR"
	SetOverwrite try
;	MessageBox MB_OK "${PACKING_DIR_PATH}\*.*"
	File /r "${PACKING_DIR_PATH}\*.*"

SectionEnd

Section RegistKeys
;获取系统计算位
	ReadRegStr $1 HKLM "Hardware\Description\System\CentralProcessor\0" Identifier
	StrCpy $2 $1 3
	${If} $2 == 'x86'
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayName" "${PRODUCT_NAME}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "UninstallString" "$INSTDIR\uninst.exe"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayIcon" "$INSTDIR\${MAIN_APP_NAME}.ico"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayVersion" "${PRODUCT_VERSION}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "Publisher" "${PRODUCT_PUBLISHER}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "InstallLocation" "$INSTDIR"
	${Else}
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayName" "${PRODUCT_NAME}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "UninstallString" "$INSTDIR\uninst.exe"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayIcon" "$INSTDIR\${MAIN_APP_NAME}.ico"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayVersion" "${PRODUCT_VERSION}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "Publisher" "${PRODUCT_PUBLISHER}"
		WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "InstallLocation" "$INSTDIR"
	${EndIf}
SectionEnd

Section CreateShortCut
  SetShellVarContext all

;生成系统开始菜单目录
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}.exe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe"

;桌面快捷方式
	CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}.exe"

;开机自启
 	nsSkinEngine::NSISGetControlData "autoSetupCheckBox" "Checked" ;
  Pop $0
  ${If} $0 == "1"
   	CreateShortCut "$SMSTARTUP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}.exe"
  ${EndIf}

	WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"

	WriteUninstaller "$INSTDIR\uninst.exe"

	nsSkinEngine::NSISNextTab "WizardTab"

	nsSkinEngine::NSISSetControlData "gifImage" "false" "visible"
SectionEnd

Function un.onInit
;创建互斥防止重复运行
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "InstallSteup") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
  nsSkinEngine::NSISMessageBox "" "有一个 ${PRODUCT_NAME} 卸载向导已经运行！"
  Abort

;强制结束进程
	KillProcDLL::KillProc "${MAIN_APP_NAME}.exe"

SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
	;----------------------------------------------------------------------------------------初始化卸载程序主窗体UI----------------------------------------------------------------------------------
  nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "UninstallPackages.xml" "UninstallWizardTab" "false" "115浏览器" "8749afbd7acf4a170be5614d512d9522" "source\ustall.ico" "false"
	Pop $Dialog
	;----------------------------------------------------------------------------------------------初始化MessageBoxUI----------------------------------------------------------------------------
  nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
  Pop $MessageBoxHandle
FunctionEnd

function un.UninstallPage
;取消按钮绑定函数
	nsSkinEngine::NSISFindControl "CancleUninstall"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have CancleUninstall"
	${Else}
		GetFunctionAddress $0 un.OnUninstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "CancleUninstall" $0
	${EndIf}

;卸载
  nsSkinEngine::NSISFindControl "ConfirmUninstall"
  Pop $0
  ${If} $0 == "-1"
  	nsSkinEngine::NSISMessageBox "" "Do not have ConfirmUninstall"
  ${Else}
  	GetFunctionAddress $0 un.UninstallPageFunc
  	nsSkinEngine::NSISOnControlBindNSISScript "ConfirmUninstall" $0
  ${EndIf}

;卸载完成
  nsSkinEngine::NSISFindControl "UninstallCompleteBtn"
  Pop $0
  ${If} $0 == "-1"
  	nsSkinEngine::NSISMessageBox "" "Do not have UninstallCompleteBtn"
  ${Else}
  	GetFunctionAddress $0 un.OnCompleteUninstallBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "UninstallCompleteBtn" $0
  ${EndIf}

;--------------------------------------窗体显示-----------------------------------
  nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

Function un.OnUninstallCancelFunc
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

Function un.UninstallPageFunc
	nsSkinEngine::NSISStartUnInstall "true"
FunctionEnd

Function un.UninstallNow
	nsSkinEngine::NSISFindControl "UninstallProgressBar"
  Pop $0
  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have UninstallProgressBar"
  ${Else}
    nsSkinEngine::NSISBindingProgress "UninstallProgressBar" "UninstallProgressText"
	${EndIf}
FunctionEnd

Section "Uninstall"
;设置为当前用户
  SetShellVarContext current
;设置为所有用户
  SetShellVarContext all

	RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
  Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
  Delete "$SMSTARTUP\${PRODUCT_NAME}.lnk"

 	ReadRegStr $1 HKLM "Hardware\Description\System\CentralProcessor\0" Identifier
	StrCpy $2 $1 3
	${If} $2 == 'x86'
	 DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}"
	${Else}
		DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}"
	${EndIf}
SectionEnd

Function un.OnCompleteUninstallBtnFunc
	nsSkinEngine::NSISHideSkinEngine
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

Function .onInstSuccess
	nsSkinEngine::NSISNextTab "WizardTab"
	nsSkinEngine::NSISNextTab "WizardTab"
FunctionEnd


Function ReadRegFunc
	ReadRegStr $1 HKLM "Hardware\Description\System\CentralProcessor\0" Identifier

	StrCpy $2 $1 3
	${If} $2 == 'x86'
		ReadRegStr $InstalledDirectory ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "InstallLocation"
		ReadRegStr $InstalledVersion ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayVersion"
	${Else}
		ReadRegStr $InstalledDirectory ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "InstallLocation"
		ReadRegStr $InstalledVersion ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}" "DisplayVersion"
	${EndIf}
;MessageBox MB_OK "$InstalledDirectory"
	${If} $InstalledDirectory != ''
	  StrCpy $INSTDIR $InstalledDirectory
	${EndIf}
FunctionEnd

;安装前卸载
Function SteupBefforeUninstall
;设置为当前用户
  SetShellVarContext current

;设置为所有用户
  SetShellVarContext all

	RMDir /r "$InstalledDirectory"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
  Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
	Delete "$SMSTARTUP\${PRODUCT_NAME}.lnk"

 	ReadRegStr $1 HKLM "Hardware\Description\System\CentralProcessor\0" Identifier
	StrCpy $2 $1 3
	${If} $2 == 'x86'
		DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}"
	${Else}
		DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_ID}"
	${EndIf}
FunctionEnd
