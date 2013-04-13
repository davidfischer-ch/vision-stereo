###########################################################################
#
#	How to compile a dll
#
###########################################################################

Fisrt you need to add this at the top of your dllfile.h :

#undef UNICODE
#ifdef BUILD_DLL
// the dll exports
#define EXPORT __declspec(dllexport)
#else
// the exe imports
#define EXPORT __declspec(dllimport)
#endif

this is a macro to define that element which got an EXPORT argument
before them can export out of the dll and access into the dll.

Second time you need to open the Qt 4.1.4 Command Prompt

Third time you go into your project directory and type :

	qmake -project

this will create an *.pro file which you can open with Bloc-notes and
which got the name of the folder where he's located. This file contain
all the information to compile the project but you need to add some 
informations. Add this line after the TEMPLATE line :

	CONFIG += dll

After that rewind to the command prompt and type :

	qmake

This will create the Makefile for your project. File type

	make

if the compilation worked you will find the dll result in the release
folder of your project.