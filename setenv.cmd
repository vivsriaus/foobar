@echo off

rem override any pre-set variables
set JAVA_HOME=
set CLASSPATH=
set JAVA_OPTS=
set ANT_OPTS=
set ANT_HOME=
set CATALINA_OPTS=
set TOMCAT_HOME=
set TOOLS_HOME=
set SONAR_RUNNER_HOME=
set FORTIFY_HOME=

set tools.path.test=..\expdevtools
set /a max.times.to.try=4

:search_tools
if not defined TOOLS_HOME (  
  if exist %tools.path.test% (
    set TOOLS_HOME=%tools.path.test%
  ) else (
    if %max.times.to.try% GTR 0 (
	  set /a max.times.to.try=%max.times.to.try% - 1
	  set tools.path.test=..\%tools.path.test%
      goto :search_tools
	)
  )
)
set TOOLS_HOME=%~dp0%TOOLS_HOME%

rem Override environment variables (other than TOOLS_HOME) for your local sandbox in this file.
if exist setenv.local.cmd call setenv.local.cmd

rem Added some ruby initialization stuff for Windows users
if not defined RUBY_VERSION set RUBY_VERSION=1.9.3

if exist %TOOLS_HOME%\ruby\select-ruby.cmd (
  call %TOOLS_HOME%\ruby\select-ruby.cmd %RUBY_VERSION%
  
  rem This will clean up those who have initialized ruby using the old script. This should
  rem be removed from this script by the end of January 2012
  if exist setrubyenv.local.cmd del setrubyenv.local.cmd
) else (
  echo You do not have %TOOLS_HOME%\ruby\select-ruby.cmd, or your expdevtools is out of date
  echo so I cannot set up your Ruby environment. For Ruby support, please sync %TOOLS_HOME%\ruby (i.e., expdevtools^)
  echo.
)

if not defined PERL_HOME set PERL_HOME=%TOOLS_HOME%\perl\MSWin32\5.8.8

if not defined TAR_HOME set TAR_HOME=%TOOLS_HOME%\tar

if not defined FORTIFY_HOME set FORTIFY_HOME=%TOOLS_HOME%\fortify

rem JAVA settings
set JDK_64BIT_LOC=%TOOLS_HOME%\jdk\1.6.0_29\MSWin64
if not defined JAVA_HOME (  
  if not exist %JDK_64BIT_LOC%\. (
    echo ERROR: You do not have 64-bit Java synced to %JDK_64BIT_LOC%
	echo ERROR: You should sync if from Perforce or set JAVA_HOME manually in setenv.local.cmd
	goto :end	
  ) else (
    set JAVA_HOME=%JDK_64BIT_LOC%
  )
)

rem TOMCAT settings
if not defined TOMCAT_HOME set TOMCAT_HOME=%TOOLS_HOME%\tomcat\6.0.35\Win64
set CATALINA_HOME=%TOMCAT_HOME%

rem SONAR_RUNNER_HOME. Only needed for running Sonar code analysis
if not defined SONAR_RUNNER_HOME set SONAR_RUNNER_HOME=%TOOLS_HOME%\sonar\sonar-runner-1.0

rem Perforce command-line configuration
if not defined P4CONFIG set P4CONFIG=p4.ini

rem Ant memory settings
if not defined ANT_OPTS set ANT_OPTS=-Xmx2048M -XX:MaxPermSize=256M -Dfile.encoding=utf8 -Djavax.net.ssl.trustStore=%CD%/buildtools/jenkinscerts

rem ANT_HOME.  Not actually needed, but used to make the ant path more intuitively overridable
if not defined ANT_HOME set ANT_HOME=buildtools\apache-ant-1.8.2

rem ANT_ARGS. Off for now, but will submit build results to the RAIN server
set "ANT_ARGS=-lib %FORTIFY_HOME%/Core/lib/sourceanalyzer.jar -lib ./buildtools/lib/com.expedia.www.expweb.tasks.jar -lib ./buildtools/lib/xmlbeans-2.5.0/xbean.jar -lib ./buildtools/lib/commons-io-1.2.jar -listener com.expedia.ant.BuildTelemeter -Dbuildstats.server=http://chelwbarain01.karmalab.net"

rem Set up path

rem PERL_HOME. Needed if you want to use eclipse-setup on a machine where perl is not installed
if not defined PERL_HOME set PERL_HOME=%TOOLS_HOME%\perl\MSWin32\5.8.8

rem Set up path
set PATH=%JAVA_HOME%\bin;%ANT_HOME%\bin;%SONAR_RUNNER_HOME%\bin;%FORTIFY_HOME%\bin;%PERL_HOME%\bin;%TAR_HOME%\win32;buildtools\junction;%PATH%

rem Prefer to use symlink for windows in copy-ivy.
set PREFER_SYMLINK=true

:echo
rem Mandatory environment variables
echo TOOLS_HOME: %TOOLS_HOME%
echo JAVA_HOME: %JAVA_HOME%
echo TOMCAT_HOME: %TOMCAT_HOME%
echo ANT_HOME: %ANT_HOME%
echo SONAR_RUNNER_HOME: %SONAR_RUNNER_HOME%
echo PATH: %PATH%
echo.

rem Optional overrides
if defined OUTPUT_ROOT echo OUTPUT_ROOT: %OUTPUT_ROOT%
if defined OUTPUT_LIB echo OUTPUT_LIB: %OUTPUT_LIB%
if defined COPY_IVY echo COPY_IVY set.  Copy Ivy mode is ON!
if defined JUNCTION_IVY_LIB echo JUNCTION_IVY_LIB set.  Junction Ivy mode is ON!
if defined DEPENDENCY_OUTPUT_ROOT echo DEPENDENCY_OUTPUT_ROOT: %DEPENDENCY_OUTPUT_ROOT%
if defined EXPWEB_DEBUG echo EXPWEB_DEBUG set.  Debug mode is ON!
if defined CREATE_CATALINA_BASE echo CREATE_CATALINA_BASE set.  Create local CATALINA_BASE mode is ON!
if defined EXPWEB_PORT_HTTP set warn_about_ports=true && echo EXPWEB_PORT_HTTP: %EXPWEB_PORT_HTTP%
if defined EXPWEB_PORT_HTTPS set warn_about_ports=true && echo EXPWEB_PORT_HTTPS: %EXPWEB_PORT_HTTPS%
if defined EXPWEB_PORT_SHUTDOWN echo EXPWEB_PORT_SHUTDOWN: %EXPWEB_PORT_SHUTDOWN%
if defined TOMCAT_PROXY_PORT echo TOMCAT_PROXY_PORT: %TOMCAT_PROXY_PORT%
if defined PROXY_ONLY echo PROXY_ONLY set.  Proxy-connector only mode is ON!
if defined AJP_ONLY echo AJP_ONLY set.  AJP-connector only mode is ON!
if defined warn_about_ports if not defined CREATE_CATALINA_BASE (
  echo     You've overridden the Expweb ports.  Be sure you're using -Dcreate.catalina.base or you've updated your TOMCAT_HOME\conf\server.xml or there may be trouble!
)
if defined USE_64BITJDK echo USE_64BITJDK set.

:end

echo
echo ########################################################################
echo #                       Deprecation notice!                            #
echo #                                                                      #
echo #  The Ant build is deprecated.  Running setenv.cmd is not part of the #
echo #  Gradle build, and this file will be deleted at the same time as the #
echo #  Ant build.  Developers should be using the Gradle build and         #
echo #  reporting any issues and missing usecases to HipChat in the room    #
echo #  'ExpWeb Forum'.                                                     #
echo #                                                                      #
echo #  Read up on how to run the Gradle build here:                        #
echo #  https://confluence/display/POS/Expweb+Developer+Sandbox+-+Gradle    #
echo #                                                                      #
echo ########################################################################

cmd /k @echo on


