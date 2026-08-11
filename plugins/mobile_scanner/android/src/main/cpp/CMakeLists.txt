cmake_minimum_required(VERSION 3.22.1)
project(dmtx_jni)

set(CMAKE_C_STANDARD 99)

set(DMTX_SRC "${CMAKE_CURRENT_SOURCE_DIR}/libdmtx/dmtx.c")

add_library(dmtx STATIC ${DMTX_SRC})
target_include_directories(dmtx PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/libdmtx)
target_compile_definitions(dmtx PRIVATE HAVE_SYS_TIME_H HAVE_GETTIMEOFDAY)

add_library(dmtx_jni SHARED dmtx_jni.cpp)
target_include_directories(dmtx_jni PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/libdmtx)

target_link_libraries(dmtx_jni dmtx log)
