# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(libusb_android_library VERSION 1.0.0 LANGUAGES C)

set(LIBUSB_DIR ${CMAKE_SOURCE_DIR}/libusb)
set(LIBUSB_SOURCE_DIR ${LIBUSB_DIR}/libusb)

set(LIBUSB_SOURCES 
  ${LIBUSB_SOURCE_DIR}/core.c
  ${LIBUSB_SOURCE_DIR}/descriptor.c
  ${LIBUSB_SOURCE_DIR}/hotplug.c
  ${LIBUSB_SOURCE_DIR}/io.c
  ${LIBUSB_SOURCE_DIR}/strerror.c
  ${LIBUSB_SOURCE_DIR}/sync.c
  ${LIBUSB_SOURCE_DIR}/os/events_posix.c
  ${LIBUSB_SOURCE_DIR}/os/linux_netlink.c
  ${LIBUSB_SOURCE_DIR}/os/linux_usbfs.c
  ${LIBUSB_SOURCE_DIR}/os/threads_posix.c
)

include_directories(
  ${LIBUSB_SOURCE_DIR}
  ${LIBUSB_DIR}/android
  ${LIBUSB_SOURCE_DIR}/os
)

add_library(libusb_android SHARED ${LIBUSB_SOURCES})

find_library(log-lib log)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

set_target_properties(libusb_android PROPERTIES
  PUBLIC_HEADER ${LIBUSB_SOURCE_DIR}/libusb.h
  OUTPUT_NAME "libusb_android"
)

target_compile_definitions(libusb_android PUBLIC DART_SHARED_LIB)
target_link_libraries(libusb_android ${log-lib} Threads::Threads)
