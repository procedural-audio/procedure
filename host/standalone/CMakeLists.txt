if(WIN32)
    #Windows specific code
    add_subdirectory(windows)
elseif(APPLE)
    add_subdirectory(macos)
endif()
