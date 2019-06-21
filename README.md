# MakePageTool
NSIS 3.0 打包工具，图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/exeFile.png)
使用aceui 支持异形界面的安装程序。

打包工具，图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/ex.png)

生成的安装程序，图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/setupUI.png)

目录结构说明，图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/DirectoryFileDescription.png)

**使用：**
  * 打包工具可以改目录下 InstallPackages.xml 文件可修改UI（UI中的空间参数可以参考：属性列表.xml文件），PackageTool.nsi文件可修改打包工具的功能，改成自己需要 样子。

* 打包工具的生成：
        ➣  打开D:\PackageTool\NSIS\makensisw.exe 
        ➣  用makensisw.exe程序打开PackageTool.nsi后会自动编译文件，编译完成后会生成 MakePackageTool.exe 
图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/MakeNsisw.png)

* 安装包测试程序
安装界面的UI 文件放在 source/InstallPackages.xml 
卸载界面的UI 文件放在 source/UninstallPackages.xml
安装面的弹窗提示UI放在 source/MessageBox.xml

**说明：**
安装包程序用的是 aceui，这是个付费的（打包工具程序不需付费），好像是 100 有一个程序码吧， 不然生成的安装包在安装时会自动打开 aceui的官网。
如图：
![image](https://github.com/Mr-hongji/PyQt5VideoPlayer/blob/master/images/zhucema.png)



    
    
