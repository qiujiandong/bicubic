cmake_minimum_required(VERSION 3.16)
project(bicubic)

set(CMAKE_C_STANDARD 99)

add_executable(bicubic inout.c main.c upsampling.c)
target_link_libraries(bicubic m pthread)
