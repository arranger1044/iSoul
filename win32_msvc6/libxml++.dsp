# Microsoft Developer Studio Project File - Name="libxml++" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=libxml++ - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "libxml++.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "libxml++.mak" CFG="libxml++ - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "libxml++ - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "libxml++ - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "libxml++ - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "../lib"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /O2 /I ".." /I "../../libxml2\include" /I "../../iconv\include" /D "NDEBUG" /D "WIN32" /D "_MBCS" /D "_LIB" /D "_REENTRANT" /YX /FD /TP /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ELSEIF  "$(CFG)" == "libxml++ - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "../lib"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /MDd /W3 /Gm /GR /GX /ZI /Od /I ".." /I "../../libxml2\include" /I "../../iconv\include" /D "_DEBUG" /D "WIN32" /D "_MBCS" /D "_LIB" /D "_REENTRANT" /YX /FD /GZ /TP /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"../lib\libxml++d.lib"

!ENDIF 

# Begin Target

# Name "libxml++ - Win32 Release"
# Name "libxml++ - Win32 Debug"
# Begin Group "libxml++"

# PROP Default_Filter ""
# Begin Group "exceptions"

# PROP Default_Filter ""
# Begin Source File

SOURCE="..\libxml++\exceptions\exception.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\exception.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\internal_error.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\internal_error.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\parse_error.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\parse_error.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\validity_error.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\exceptions\validity_error.h"
# End Source File
# End Group
# Begin Group "nodes"

# PROP Default_Filter ""
# Begin Source File

SOURCE="..\libxml++\attribute.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\attribute.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\cdatanode.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\cdatanode.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\commentnode.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\commentnode.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\contentnode.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\contentnode.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\element.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\element.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\entityreference.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\entityreference.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\node.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\node.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\processinginstructionnode.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\processinginstructionnode.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\textnode.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\nodes\textnode.h"
# End Source File
# End Group
# Begin Group "parsers"

# PROP Default_Filter ""
# Begin Source File

SOURCE="..\libxml++\parsers\domparser.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\parsers\domparser.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\parsers\parser.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\parsers\parser.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\parsers\saxparser.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\parsers\saxparser.h"
# End Source File
# End Group
# Begin Group "io"

# PROP Default_Filter ""
# Begin Source File

SOURCE="..\libxml++\io\ostreamoutputbuffer.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\io\ostreamoutputbuffer.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\io\outputbuffer.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\io\outputbuffer.h"
# End Source File
# End Group
# Begin Source File

SOURCE="..\libxml++\document.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\document.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\dtd.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\dtd.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\keepblanks.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\keepblanks.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\libxml++.h"
# End Source File
# Begin Source File

SOURCE="..\libxml++\noncopyable.cc"
# End Source File
# Begin Source File

SOURCE="..\libxml++\noncopyable.h"
# End Source File
# End Group
# Begin Source File

SOURCE=.\README.win32
# End Source File
# End Target
# End Project
