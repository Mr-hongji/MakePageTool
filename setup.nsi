;---------------------------------------------------------------------------��װ�� ��ѹ�հ�---------------------------------------------------------------------
!system '>blank set/p=MSCF<nul'
!packhdr temp.dat 'cmd /c Copy /b temp.dat /b +blank&&del blank'

;--------------------------------------------------------------------------------�������-----------------------------------------------------------------------
Var Dialog
Var MessageBoxHandle
Var InstallPath
Var FreeSpaceSize
var DefaultInstallDir
Var InstalledDirectory ;�Ѱ�װĿ¼
Var InstalledVersion ;�Ѱ�װ�汾
Var NeedSpace
Var SpaceNotEnough

;-------------------------------------------------------------------------------��ʼ���峣��---------------------------------------------------------------------

!define UNINSTALL_DIR "$TEMP\nsis\setup"
!define SHCNE_ASSOCCHANGED 0x08000000 ;ˢ�¹���ͼ��
!define SHCNF_IDLIST 0
!define MUI_FINISHPAGE_NOREBOOTSUPPORTs ; ��װ����Ҫ����

;--------------------------------------------------------------------------------ע�����-----------------------------------------------------------------------
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetOverwrite on ;�����ļ����Ǳ��
SetCompress auto ;����ѹ��ѡ��
SetCompressor /SOLID lzma ;ѡ��ѹ����ʽ
SetCompressorDictSize 32
SetDatablockOptimize on ;�������ݿ��Ż�
SetDateSave on ;������������д���ļ�ʱ��
AllowRootDirInstall false ; �Ƿ�����װ�ڸ�Ŀ¼��
RequestExecutionLevel admin ;Request application privileges for Windows Vista

Unicode false ;����Unicode ���� 3.0���ϰ汾֧��

LicenseName "115�����"
LicenseKey "8749afbd7acf4a170be5614d512d9522"

;------------------------------------------------------------------------------------------�����ͷ�ļ�-------------------------------------------------------------------------------------
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "WordFunc.nsh"
!include "ParameterInfo.nsi"
!insertmacro MUI_LANGUAGE "SimpChinese" ;Languages

;-------------------------------------------------------------------------------------------��װ��ж��ҳ��-----------------------------------------------------------------------------------
Page         custom     InstallPage
Page         instfiles  "" InstallShow
UninstPage   custom     un.UninstallPage
UninstPage   instfiles	""	un.UninstallNow

Function .onInit
	SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
;--------------------------------------------------------------------------------------------��ʼ��������UI----------------------------------------------------------------------------------
	nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "InstallPackages.xml" "WizardTab" "false" "115�����" "8749afbd7acf4a170be5614d512d9522" "source\app.ico" "false"
	Pop $Dialog
;----------------------------------------------------------------------------------------------��ʼ��MessageBoxUI----------------------------------------------------------------------------
	nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
	Pop $MessageBoxHandle

;���������ֹ�ظ�����
	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "xiaonengInstall") i .r1 ?e'
	Pop $R0
	StrCmp $R0 0 +3
	nsSkinEngine::NSISMessageBox "" "��һ�� ${PRODUCT_NAME} ��װ���Ѿ����У�"
	Abort

;ǿ�ƽ�������
	KillProcDLL::KillProc "${MAIN_APP_NAME}.exe"

  StrCpy $NeedSpace "150MB"
  StrCpy $SpaceNotEnough "1" ;���̿ռ䲻���ʶ

	Call ReadRegFunc
FunctionEnd

Function InstallPage
;--------------------------------------------------------------------------------------------��ҳ��ť�¼���----------------------------------------------------------------------------------
;�رհ�ť�󶨺���
	nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have InstallTab_sysCloseBtn"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn" $0
	${EndIf}

;������װ
	nsSkinEngine::NSISFindControl "InstallBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 InstallPageFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallBtn"  $0
	${EndIf}

;�Զ��尲װ
	nsSkinEngine::NSISFindControl "custom_Installation_Text"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPageFunc
		nsSkinEngine::NSISOnControlBindNSISScript "custom_Installation_Text"  $0
	${EndIf}

	nsSkinEngine::NSISSetControlData "autoSetupCheckBox"  "true" "Checked" ;Ĭ�Ϲ�ѡ���г���
;--------------------------------------------------------------------------------------------�Զ���ҳ�水ť�¼���------------------------------------------------------------------------------
;���
	nsSkinEngine::NSISFindControl "InstallTab_SelectFilePathBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_SelectFilePathBtn button"
	${Else}
		GetFunctionAddress $0 OnInstallPathBrownBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_SelectFilePathBtn"  $0
	${EndIf}

;ȡ��
	nsSkinEngine::NSISFindControl "InstallTab_CancleBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPage_CancleBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_CancleBtn"  $0
	${EndIf}

;������װ
	nsSkinEngine::NSISFindControl "InstallTab_InstallNowBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallBtn button"
	${Else}
		GetFunctionAddress $0 CustomInstallPage_InstallNowBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallNowBtn"  $0
	${EndIf}
;--------------------------------------------------------------------------------------------------------��װ����ҳ�水ť�¼���-----------------------------------------------------------------------
;�رհ�ť�󶨺���
	nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn1"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have InstallTab_sysCloseBtn1"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn1" $0
	${EndIf}

;���ý�����
	nsSkinEngine::NSISFindControl "InstallProgressBar"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallProgressBar"
	${Else}
		;����progressBar
		nsSkinEngine::NSISSetControlData "InstallProgressBar"  "false"  "visible"
	${EndIf}
;--------------------------------------------------------------------------------------------------------���ҳ�水ť�¼���------------------------------------------------------------------------------------
;����ʹ��
	nsSkinEngine::NSISFindControl "InstallTab_UseNowBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_UseNowBtn button"
	${Else}
		GetFunctionAddress $0 CompletePage_UseNowBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_UseNowBtn"  $0
	${EndIf}
;--------------------------------------------------------------------------------------------������ʾ--------------------------------------------------------------------------------
	nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

;�رհ�ť�¼�
Function OnInstallCancelFunc
	nsSkinEngine::NSISMessageBox "" " ȷ��Ҫ�˳� ${PRODUCT_NAME} �İ�װ��"
	Pop $0
	${If} $0 == "1"
		nsSkinEngine::NSISExitSkinEngine "false"
	${EndIf}
FunctionEnd

;��ҳ ����> ������װ
Function InstallPageFunc
	nsSkinEngine::NSISNextTab "WizardTab"

;���ý�����
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

;��ҳ ����> �Զ��尴ť�¼�����
Function CustomInstallPageFunc
	nsSkinEngine::NSISNextTab "WizardTab"
	nsSkinEngine::NSISNextTab "WizardTab"

	StrCpy	$DefaultInstallDir $INSTDIR

;��װ·���༭���趨����
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

;�Զ���ҳ�� ����> �����ťѡ��װ·��
Function OnInstallPathBrownBtnFunc
	nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text"
	Pop $InstallPath
	nsSkinEngine::NSISSelectFolderDialog "��ѡ���ļ���" $InstallPath
	Pop $InstallPath

	StrCpy $0 $InstallPath
	${If} $0 == "-1"
	${Else}
		StrCpy $INSTDIR "$installPath\${MAIN_APP_NAME}"
		;���ð�װ·���༭���ı�
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

;�Զ���ҳ�� ����> ȡ����ť�¼�����
Function CustomInstallPage_CancleBtnFunc
	nsSkinEngine::NSISBackTab "WizardTab"
	nsSkinEngine::NSISBackTab "WizardTab"
	Call restoreInstallParamValue
FunctionEnd

;�Զ���ҳ�� ����> ������װ��ť�¼�����
Function CustomInstallPage_InstallNowBtnFunc
	nsSkinEngine::NSISBackTab "WizardTab"
	nsSkinEngine::NSISBackTab "WizardTab"
	Call InstallPageFunc
FunctionEnd

;���ҳ�� ����> ����ʹ�ð�ť�¼�����
Function CompletePage_UseNowBtnFunc
	Exec "$INSTDIR\${MAIN_APP_NAME}.exe"
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

Function OnTextChangeFunc
; �ı���ô��̿ռ��С
	nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text"
	Pop $0
	;nsSkinEngine::NSISMessageBox "" $0
	StrCpy $INSTDIR $0

;���»�ȡ���̿ռ�
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

  StrCpy $FreeSpaceSize  "����ռ䣺$NeedSpace       ���ÿռ䣺$0$1"
FunctionEnd

Function SpaceIsNotEnough
  StrCpy $SpaceNotEnough "0"
  nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace" "#FFBC1717" "enable"
  nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "false" "enable"
	nsSkinEngine::NSISSetControlData "InstallBtn" "false" "enable"
FunctionEnd

Function FreshInstallDataStatusFunc
;���´��̿ռ��ı���ʾ
	nsSkinEngine::NSISFindControl "InstallTab_FreeSpace"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_FreeSpace"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace"  "$FreeSpaceSize"  "text"
	${EndIf}

;·���Ƿ�Ϸ����Ϸ���Ϊ0Bytes��
	${If} $FreeSpaceSize == "0Bytes"
		nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "false" "enable"
		nsSkinEngine::NSISSetControlData "InstallBtn" "false" "enable"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallTab_InstallNowBtn" "true" "enable"
		nsSkinEngine::NSISSetControlData "InstallBtn" "true" "enable"
	${EndIf}
FunctionEnd

;ˢ�¹���ͼ��
Function RefreshShellIcons
	System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
	(${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function restoreInstallParamValue
;��ԭ��װ·��
	StrCpy $INSTDIR $DefaultInstallDir

;��ԭ��װ����
	nsSkinEngine::NSISSetControlData "setupLanguage_Combo"  "0"  "CurrentIndex"

;��ԭ��������
	nsSkinEngine::NSISSetControlData "autoSetupCheckBox"  "true" "Checked"
FunctionEnd

Section InstallFiles
;��װǰж��
	Call SteupBefforeUninstall

	SetOutPath "$INSTDIR"
	SetOverwrite try
;	MessageBox MB_OK "${PACKING_DIR_PATH}\*.*"
	File /r "${PACKING_DIR_PATH}\*.*"

SectionEnd

Section RegistKeys
;��ȡϵͳ����λ
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

;����ϵͳ��ʼ�˵�Ŀ¼
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}.exe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe"

;�����ݷ�ʽ
	CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}.exe"

;��������
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
;���������ֹ�ظ�����
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "InstallSteup") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
  nsSkinEngine::NSISMessageBox "" "��һ�� ${PRODUCT_NAME} ж�����Ѿ����У�"
  Abort

;ǿ�ƽ�������
	KillProcDLL::KillProc "${MAIN_APP_NAME}.exe"

SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
	;----------------------------------------------------------------------------------------��ʼ��ж�س���������UI----------------------------------------------------------------------------------
  nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "UninstallPackages.xml" "UninstallWizardTab" "false" "115�����" "8749afbd7acf4a170be5614d512d9522" "source\ustall.ico" "false"
	Pop $Dialog
	;----------------------------------------------------------------------------------------------��ʼ��MessageBoxUI----------------------------------------------------------------------------
  nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
  Pop $MessageBoxHandle
FunctionEnd

function un.UninstallPage
;ȡ����ť�󶨺���
	nsSkinEngine::NSISFindControl "CancleUninstall"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox "" "Do not have CancleUninstall"
	${Else}
		GetFunctionAddress $0 un.OnUninstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "CancleUninstall" $0
	${EndIf}

;ж��
  nsSkinEngine::NSISFindControl "ConfirmUninstall"
  Pop $0
  ${If} $0 == "-1"
  	nsSkinEngine::NSISMessageBox "" "Do not have ConfirmUninstall"
  ${Else}
  	GetFunctionAddress $0 un.UninstallPageFunc
  	nsSkinEngine::NSISOnControlBindNSISScript "ConfirmUninstall" $0
  ${EndIf}

;ж�����
  nsSkinEngine::NSISFindControl "UninstallCompleteBtn"
  Pop $0
  ${If} $0 == "-1"
  	nsSkinEngine::NSISMessageBox "" "Do not have UninstallCompleteBtn"
  ${Else}
  	GetFunctionAddress $0 un.OnCompleteUninstallBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "UninstallCompleteBtn" $0
  ${EndIf}

;--------------------------------------������ʾ-----------------------------------
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
;����Ϊ��ǰ�û�
  SetShellVarContext current
;����Ϊ�����û�
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

;��װǰж��
Function SteupBefforeUninstall
;����Ϊ��ǰ�û�
  SetShellVarContext current

;����Ϊ�����û�
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
