;--------------------------------------------------------------------------------定义变量-----------------------------------------------------------------------
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

;-------------------------------------------------------------------------------初始定义常量---------------------------------------------------------------------
!define UNINSTALL_DIR "$TEMP\nsis\paceage"
!define MUI_ICON "source\package.ico"


SetOverwrite on ;设置文件覆盖标记
SetCompress auto ;设置压缩选项
SetCompressor /SOLID lzma ;选择压缩方式
SetCompressorDictSize 32
SetDatablockOptimize on ;设置数据块优化
SetDateSave on ;设置在数据中写入文件时间
AllowRootDirInstall false ; 是否允许安装在根目录下
RequestExecutionLevel admin ;Request application privileges for Windows Vista
Name "MakePackageTool"
OutFile "MakePackageTool.exe"
;{3EDDD96A-952C-4945-988D-E93399ECFF32}

Unicode false ;设置Unicode 编码 3.0以上版本支持
LicenseName "115浏览器"
LicenseKey "8749afbd7acf4a170be5614d512d9522"

;------------------------------------------------------------------------------------------引入的头文件-------------------------------------------------------------------------------------
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "WordFunc.nsh"
!insertmacro MUI_LANGUAGE "SimpChinese" ;Languages

;-------------------------------------------------------------------------------------------安装和卸载页面-----------------------------------------------------------------------------------
Page custom packagePage

Function .onInit

;MessageBox MB_OK '$EXEDIR'

	SetOutPath "${UNINSTALL_DIR}"
	File /r ".\source\*.*"
;--------------------------------------------------------------------------------------------初始化主窗体UI----------------------------------------------------------------------------------
	nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "MakePackages.xml" "WizardTab" "false" "115浏览器" "8749afbd7acf4a170be5614d512d9522" "source\image\app.ico" "false"
	Pop $Dialog
FunctionEnd

Function packagePage
;--------------------------------------------------------------------------------------------首页按钮事件绑定----------------------------------------------------------------------------------
;关闭按钮绑定函数
	nsSkinEngine::NSISFindControl "closeBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have closeBtn"
	${Else}
		GetFunctionAddress $0 OnInstallCancelFunc
		nsSkinEngine::NSISOnControlBindNSISScript "closeBtn" $0
	${EndIf}
	
;一键打包按钮绑定函数
	nsSkinEngine::NSISFindControl "makePackageBtn"
	Pop $0
	${If} $0 == "-1"
		nsSkinEngine::NSISMessageBox ""  "Do not have makePackageBtn"
	${Else}
		GetFunctionAddress $0 OnmakePackageBtnFunc
		nsSkinEngine::NSISOnControlBindNSISScript "makePackageBtn" $0
	${EndIf}
	
;预打包路径浏览
	nsSkinEngine::NSISFindControl "selectPrePackagedFilePathBtn"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have selectPrePackagedFilePathBtn button"
  ${Else}
    GetFunctionAddress $0 OnPrePackagedFilePathBrownBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "selectPrePackagedFilePathBtn"  $0
  ${EndIf}
  
;安装包生成路径选择
	nsSkinEngine::NSISFindControl "selectOutFilePathBtn"
  Pop $0

  ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have selectOutFilePathBtn button"
  ${Else}
    GetFunctionAddress $0 OnSelectOutFilePathBrownBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "selectOutFilePathBtn"  $0
  ${EndIf}
  
;资源目录路径选择
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
;--------------------------------------------------------------------------------------------窗体显示--------------------------------------------------------------------------------
	nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

;关闭
Function OnInstallCancelFunc
	nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

;预打包路径选择按钮事件
Function OnPrePackagedFilePathBrownBtnFunc
nsDialogs::SelectFolderDialog "请选择 $R0 安装的文件夹:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    nsSkinEngine::NSISSetControlData "pre_packaged_file_path_Edit"  $0  "text"
  ${EndIf}
FunctionEnd

;安装包生成路径选择按钮事件
Function OnSelectOutFilePathBrownBtnFunc
	nsDialogs::SelectFolderDialog "请选择安装包生成的目录:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
   nsSkinEngine::NSISSetControlData "out_file_path_Edit"  "$0\InstallSteup.exe"  "text"
  ${EndIf}
FunctionEnd

;资源目录路径选择按钮事件
Function OnSelectSourceImageFilePathBrownBtnFunc
	nsDialogs::SelectFolderDialog "请选择安装包所使用皮肤资源目录:" "$R0"
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
   nsSkinEngine::NSISSetControlData "source_image_file_path_Edit"  $0  "text"
  ${EndIf}
FunctionEnd

;一键打包
Function OnmakePackageBtnFunc
  Call getEditValue
	Call checkParmValue
	Call WriteParameterToFile
	
	;数字签名
	;Call DigitalSingaTure

	Call StartPacking
	
	StrCpy $SignFile $OutFileV

  ;数字签名
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
	  MessageBox MB_OK "ID不能为空"
	  Abort
	${ElseIf} $ProductNameV == ""
	 MessageBox MB_OK "名称不能为空"
	  Abort
	${ElseIf} $MainAppNameV == ""
	 MessageBox MB_OK "程序名称不能为空"
	  Abort
	${ElseIf} $ProductVersionV == ""
	 MessageBox MB_OK "版本号不能为空"
	  Abort
	${ElseIf} $PackingDirPathV == ""
	 MessageBox MB_OK "请选择要打包的文件目录"
	  Abort
	  ${ElseIf} $OutFileV == ""
	 MessageBox MB_OK "请选择要安装包输出目录"
	  Abort
	   ${ElseIf} $SourcePathV == ""
	 MessageBox MB_OK "请选择要资源文件目录"
	  Abort
	${EndIf}
FunctionEnd

Function WriteParameterToFile


	ClearErrors
	FileOpen $0 '$EXEDIR\ParameterInfo.nsi' w
	IfErrors done
	
	FileWrite $0 '!define PRODUCT_ID "$ProductIdV"' ;Id
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_NAME "$ProductNameV"' ;桌面快捷方式显示的名称
	FileWrite $0 $\n
	
	FileWrite $0 '!define MAIN_APP_NAME "$MainAppNameV"' ;主程序名称（exe名称）
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_VERSION "$ProductVersionV"' ;版本号
	FileWrite $0 $\n
	
	FileWrite $0 '!define PACKING_DIR_PATH "$PackingDirPathV"' ;预打包文件路径
	FileWrite $0 $\n
	
	FileWrite $0 '!define SOURCE_PATH "$SourcePathV"' ;图片文件等资源路径
	FileWrite $0 $\n
	
	FileWrite $0 '!define MUI_ICON "source\$MainAppNameV.ico"' ;安装程序图标
	FileWrite $0 $\n
	
	FileWrite $0 '!define MUI_UNICON "$SourcePathV\ustall.ico"' ;卸载程序图标
	FileWrite $0 $\n

	FileWrite $0 'InstallDir "C:\Program Files (x86)\$MainAppNameV"' ;默认安装路径
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_WEB_SITE "www.ceshi.cn"' ;发布者的网站
	FileWrite $0 $\n
	
	FileWrite $0 '!define PRODUCT_PUBLISHER "ceshi"' ;发布者的名称
	FileWrite $0 $\n

	FileWrite $0 'OutFile "$OutFileV"' ;安装包生成路径
	FileWrite $0 $\n

	FileWrite $0 'Name "$ProductNameV"'
	FileWrite $0 $\n

	FileClose $0
	done:

	;${FileJoin} "E:\NSIS\util\XiaonengNSIS\ParameterInfo.nsi" "E:\NSIS\util\XiaonengNSIS\Xiaoneng2.nsi" "E:\NSIS\util\XiaonengNSIS\Xiaoneng2.nsi"

FunctionEnd

;数字签名
Function DigitalSingaTure
	ClearErrors
	FileOpen $0 Sign.bat w
	IfErrors done
	FileWrite $0 'f:'
	FileWrite $0 $\r$\n
	FileWrite $0 'cd \SignGUI'
	FileWrite $0 $\r$\n
	FileWrite $0 'signtool sign /f nengtong.pfx /p 123456 /t http://timestamp.verisign.com/scripts/timstamp.dll /d "小能" /du http://www.xiaoneng.cn $SignFile'
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
