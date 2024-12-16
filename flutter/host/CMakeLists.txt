cmake_minimum_required(VERSION 3.15)
set (CMAKE_CXX_STANDARD 14)

project(NODUS_HOST VERSION 0.0.1)

file(REAL_PATH "${FRAMEWORK_PATH}/Headers" HEADER_PATH)
file(REAL_PATH "${FRAMEWORK_PATH}/FlutterMacOS" LIBRARY_PATH)

if(EXISTS "${HEADER_PATH}")
    include_directories("${HEADER_PATH}")
else()
    message(FATAL_ERROR "Framework not found at ${HEADER_PATH}")
endif()

if(EXISTS "${JUCE_PATH}/CMakeLists.txt")
    add_subdirectory("${JUCE_PATH}" "${CMAKE_BINARY_DIR}/juce")
else()
    message(FATAL_ERROR "JUCE not found at ${JUCE_PATH}")
endif()

if(WIN32)
    add_subdirectory(windows)
elseif(APPLE)
    add_subdirectory(macos)
elseif(UNIX)
    add_subdirectory(linux)
endif()

target_link_libraries(NodusStandalone
    PRIVATE
    "${LIBRARY_PATH}"
)
