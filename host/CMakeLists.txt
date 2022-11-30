cmake_minimum_required(VERSION 3.15)
set (CMAKE_CXX_STANDARD 14)

project(NODUS_HOST VERSION 0.0.1)

add_subdirectory(juce)
add_subdirectory(plugin)
add_subdirectory(standalone)