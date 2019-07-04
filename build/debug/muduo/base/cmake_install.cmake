# Install script for directory: /home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base

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
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/home/mingyu/MyMuduo/MyMuduo/build/debug/lib/libmuduo_base.a")
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/muduo/base" TYPE FILE FILES
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/BlockingQueue.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/ThreadPool.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Atomic.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Condition.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Mutex.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Exception.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/ThreadLocal.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Singleton.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/CurrentThread.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Timestamp.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Thread.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/copyable.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/BoundedBlockingQueue.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/Types.h"
    "/home/mingyu/MyMuduo/MyMuduo/mymuduo/muduo/base/CountDownLatch.h"
    )
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/muduo/base/tests/cmake_install.cmake")

endif()

