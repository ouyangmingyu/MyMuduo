# Install script for directory: /home/mingyu/MyMuduo/MyMuduo/mymuduo/examples

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

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/asio/chat/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/asio/tutorial/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/fastcgi/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/filetransfer/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/hub/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/idleconnection/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/maxconnection/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/multiplexer/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/netty/discard/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/netty/echo/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/netty/uptime/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/pingpong/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/roundtrip/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/shorturl/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/simple/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/socks4a/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/sudoku/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/twisted/finger/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/wordcount/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/zeromq/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/cdns/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/curl/cmake_install.cmake")
  include("/home/mingyu/MyMuduo/MyMuduo/build/debug/examples/protobuf/cmake_install.cmake")

endif()

