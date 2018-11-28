;--------------------------------------------------------------------------------�������-----------------------------------------------------------------------
Var Dialog
Var MessageBoxHandle
Var ProductIdV
Var ProductNameV
Var MainAppNameV
Var ProductVersionV
Var PackingDirPathV
Var OutFileV
Var SourcePathV
Var SignFile

;-------------------------------------------------------------------------------��ʼ���峣��---------------------------------------------------------------------
!define UNINSTALL_DIR "$TEMP\nsis\paceage"
!define MUI_ICON "source\package.ico"


SetOverwrite on ;�����ļ����Ǳ��
SetCompress auto ;����ѹ��ѡ��
SetCompressor /SOLID lzma ;ѡ��ѹ����ʽ
SetCompressorDictSize 32
SetDatablockOptimize on ;�������ݿ��Ż�
SetDateSave on ;������������д���ļ�ʱ��
AllowRootDirInstall false ; �Ƿ�����װ�ڸ�Ŀ¼��
RequestExecutionLevel admin ;Request application privileges for Windows Vista
Name "MakePackageTool"
OutFile "MakePackageTool.exe"
;{3EDDD96A-952C-4945-988D-E93399ECFF32}

Unicode false ;����Unicode ���� 3.0���ϰ汾֧��
LicenseName "115�����"
LicenseKey "8749afbd7acf4a170be5614d512d9522"

;------------------------------------------------------------------------------------------�����ͷ�ļ�-------------------------------------------------------------------------------------
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "WordFunc.nsh"
!insertmacro MUI_LANGUAGE "SimpChinese" ;Languages

;-------------------------------------------------------------------------------------------��װ��ж��ҳ��-----------------------------------------------------------------------------------
Page custom packagePage

Function .onInit

;MessageBox MB_OK '$EXEDIR'

	SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
;--------------------------------------------------------------------------------------------��ʼ��������UI----------------------------------------------------------------------------------
	nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "MakePackages.xml" "WizardTab" "false" "115�����" "8749afbd7acf4a170be5614d512d9522" "source\image\app.ico" "false"
	Pop $Dialog
FunctionEnd

Function packagePage
;--------------------------------------------------------------------------------------------��ҳ��ť�¼���----------------------------------------------------------------------------------
;�رհ�ť�󶨺���
	nsSkinEngine::NSISFindControl "closeBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have closeBtn"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "closeBtn" $0
	${EndIf}
	
;һ�������ť�󶨺���
	nsSkinEngine::NSISFindControl "makePackageBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have makePackageBtn"
	${Else}
		GetFunctionAddress $0 OnmakePackageBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "makePackageBtn" $0
	${EndIf}
	
;Ԥ���·�����
	nsSkinEngine::NSISFindControl "selectPrePackagedFilePathBtn"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have selectPrePackagedFilePathBtn button"
  ${Else}
    GetFunctionAddress $0 OnPrePackagedFilePathBrownBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "selectPrePackagedFilePathBtn"  $0
  ${EndIf}
  
;��װ������·��ѡ��
	nsSkinEngine::NSISFindControl "selectOutFilePathBtn"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have selectOutFilePathBtn button"
  ${Else}
    GetFunctionAddress $0 OnSelectOutFilePathBrownBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "selectOutFilePathBtn"  $0
  ${EndIf}
  
;��ԴĿ¼·��ѡ��
	nsSkinEngine::NSISFindControl "selectSourceImageFilePathBtn"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have selectSourceImageFilePathBtn button"
  ${Else}
    GetFunctionAddress $0 OnSelectSourceImageFilePathBrownBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "selectSourceImageFilePathBtn"  $0
  ${EndIf}


;Id
	nsSkinEngine::NSISFindControl "id_Edit"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have id_Edit button"
  ${Else}
    ;nsSkinEngine::NSISSetControlData "id_Edit"  ""  "text"
  ${EndIf}
;--------------------------------------------------------------------------------------------������ʾ--------------------------------------------------------------------------------
	nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

;�ر�
Function OnInstallCancelFunc
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

;Ԥ���·��ѡ��ť�¼�
Function OnPrePackagedFilePathBrownBtnFunc
nsDialogs::SelectFolderDialog "��ѡ�� $R0 ��װ���ļ���:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    nsSkinEngine::NSISSetControlData "pre_packaged_file_path_Edit"  $0  "text"
  ${EndIf}
FunctionEnd

;��װ������·��ѡ��ť�¼�
Function OnSelectOutFilePathBrownBtnFunc
	nsDialogs::SelectFolderDialog "��ѡ��װ�����ɵ�Ŀ¼:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
   nsSkinEngine::NSISSetControlData "out_file_path_Edit"  "$0\InstallSteup.exe"  "text"
  ${EndIf}
FunctionEnd

;��ԴĿ¼·��ѡ��ť�¼�
Function OnSelectSourceImageFilePathBrownBtnFunc
	nsDialogs::SelectFolderDialog "��ѡ��װ����ʹ��Ƥ����ԴĿ¼:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
   nsSkinEngine::NSISSetControlData "source_image_file_path_Edit"  $0  "text"
  ${EndIf}
FunctionEnd

;һ�����
Function OnmakePackageBtnFunc
  Call getEditValue
	Call checkParmValue
	Call WriteParameterToFile
	
	;����ǩ��
	;Call DigitalSingaTure

	Call StartPacking
	
	StrCpy $SignFile $OutFileV

  ;����ǩ��
	;Call DigitalSingaTure
FunctionEnd

Function getEditValue
  nsSkinEngine::NSISGetControlData "id_Edit" "text"
  Pop $ProductIdV
  
  nsSkinEngine::NSISGetControlData "name_Edit" "text"
  Pop $ProductNameV
  
  nsSkinEngine::NSISGetControlData "main_app_name_Edit" "text"
  Pop $MainAppNameV
  
  nsSkinEngine::NSISGetControlData "version_Edit" "text"
  Pop $ProductVersionV
  
  nsSkinEngine::NSISGetControlData "pre_packaged_file_path_Edit" "text"
  Pop $PackingDirPathV
  StrCpy $SignFile "$PackingDirPathV\$MainAppNameV"
  
  nsSkinEngine::NSISGetControlData "out_file_path_Edit" "text"
  Pop $OutFileV
  
  nsSkinEngine::NSISGetControlData "source_image_file_path_Edit" "text"
  Pop $SourcePathV
FunctionEnd

Function checkParmValue
	;${NSD_GetState} $PackageType $PackageTypeValue
	${If} $ProductIdV == ""
	  MessageBox MB_OK "ID����Ϊ��"
	  Abort
	${ElseIf} $ProductNameV == ""
	 MessageBox MB_OK "���Ʋ���Ϊ��"
	  Abort
	${ElseIf} $MainAppNameV == ""
	 MessageBox MB_OK "�������Ʋ���Ϊ��"
	  Abort
	${ElseIf} $ProductVersionV == ""
	 MessageBox MB_OK "�汾�Ų���Ϊ��"
	  Abort
	${ElseIf} $PackingDirPathV == ""
	 MessageBox MB_OK "��ѡ��Ҫ������ļ�Ŀ¼"
	  Abort
	  ${ElseIf} $OutFileV == ""
	 MessageBox MB_OK "��ѡ��Ҫ��װ�����Ŀ¼"
	  Abort
	   ${ElseIf} $SourcePathV == ""
	 MessageBox MB_OK "��ѡ��Ҫ��Դ�ļ�Ŀ¼"
	  Abort
	${EndIf}
FunctionEnd

Function WriteParameterToFile


	ClearErrors
	FileOpen $0 '$EXEDIR\ParameterInfo.nsi' w
	IfErrors done
	
	FileWrite $0 '!define PRODUCT_ID "$ProductIdV"' ;Id
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_NAME "$ProductNameV"' ;�����ݷ�ʽ��ʾ������
	FileWrite $0 $\n
	
	FileWrite $0 '!define MAIN_APP_NAME "$MainAppNameV"' ;���������ƣ�exe���ƣ�
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_VERSION "$ProductVersionV"' ;�汾��
	FileWrite $0 $\n
	
	FileWrite $0 '!define PACKING_DIR_PATH "$PackingDirPathV"' ;Ԥ����ļ�·��
	FileWrite $0 $\n
	
	FileWrite $0 '!define SOURCE_PATH "$SourcePathV"' ;ͼƬ�ļ�����Դ·��
	FileWrite $0 $\n
	
	FileWrite $0 '!define MUI_ICON "source\$MainAppNameV.ico"' ;��װ����ͼ��
	FileWrite $0 $\n
	
	FileWrite $0 '!define MUI_UNICON "$SourcePathV\ustall.ico"' ;ж�س���ͼ��
	FileWrite $0 $\n

	FileWrite $0 'InstallDir "C:\Program Files (x86)\$MainAppNameV"' ;Ĭ�ϰ�װ·��
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_WEB_SITE "www.ceshi.cn"' ;�����ߵ���վ
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_PUBLISHER "ceshi"' ;�����ߵ�����
	FileWrite $0 $\n

	FileWrite $0 'OutFile "$OutFileV"' ;��װ������·��
	FileWrite $0 $\n

	FileWrite $0 'Name "$ProductNameV"'
	FileWrite $0 $\n

	FileClose $0
	done:

	;${FileJoin} "E:\NSIS\util\XiaonengNSIS\ParameterInfo.nsi" "E:\NSIS\util\XiaonengNSIS\Xiaoneng2.nsi" "E:\NSIS\util\XiaonengNSIS\Xiaoneng2.nsi"

FunctionEnd

;����ǩ��
Function DigitalSingaTure
	ClearErrors
	FileOpen $0 Sign.bat w
	IfErrors done
	FileWrite $0 'f:'
	FileWrite $0 $\r$\n
	FileWrite $0 'cd \SignGUI'
	FileWrite $0 $\r$\n
	FileWrite $0 'signtool sign /f nengtong.pfx /p 123456 /t http://timestamp.verisign.com/scripts/timstamp.dll /d "С��" /du http://www.xiaoneng.cn $SignFile'
  FileWrite $0 $\r$\n
	FileWrite $0 'pause'
	FileWrite $0 $\r$\n
	FileWrite $0 'exit'
	FileClose $0
	done:
	
	ExecWait "Sign.bat" $R0
FunctionEnd

Function StartPacking
	nsExec::Exec '"$EXEDIR\NSIS\makensisw.exe" $EXEDIR\setup.nsi' $0
	;MessageBox MB_OK "$0"
FunctionEnd

Section "main"
SectionEnd

Function un.onInit
FunctionEnd
