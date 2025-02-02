# Install script for directory: /home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/mingyu/MyMuduo/MyMuduo/build/debug-install")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/home/mingyu/MyMuduo/MyMuduo/build/debug/lib/libmuduo_net.a")
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/muduo/net" TYPE FILE FILES
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/Acceptor.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/Buffer.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/Channel.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/Endian.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/EventLoop.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/EventLoopThread.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/EventLoopThreadPool.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/InetAddress.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/TcpClient.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/TcpConnection.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/TcpServer.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/net/TimerId.h"
    )
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/muduo/net/http/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/muduo/net/inspect/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/muduo/net/tests/cmake_install.cmake")

endif()

