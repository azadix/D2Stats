cmake_minimum_required(VERSION 3.16)
if(POLICY CMP0169)
	cmake_policy(SET CMP0169 OLD)
endif()
project(d2stats_ui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")

set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/imgui")
if(NOT EXISTS "${IMGUI_DIR}/imgui.cpp")
	include(FetchContent)
	FetchContent_Declare(
		imgui
		URL https://github.com/ocornut/imgui/archive/refs/tags/v1.91.9b.zip
		DOWNLOAD_EXTRACT_TIMESTAMP TRUE
	)
	FetchContent_GetProperties(imgui)
	if(NOT imgui_POPULATED)
		FetchContent_Populate(imgui)
	endif()
	set(IMGUI_DIR ${imgui_SOURCE_DIR})
endif()

add_library(d2stats_ui SHARED
	src/d2stats_ui.cpp
	d2stats_ui.def
	${IMGUI_DIR}/imgui.cpp
	${IMGUI_DIR}/imgui_draw.cpp
	${IMGUI_DIR}/imgui_tables.cpp
	${IMGUI_DIR}/imgui_widgets.cpp
	${IMGUI_DIR}/backends/imgui_impl_win32.cpp
	${IMGUI_DIR}/backends/imgui_impl_dx11.cpp
)

target_include_directories(d2stats_ui PRIVATE
	include
	${IMGUI_DIR}
	${IMGUI_DIR}/backends
)

target_compile_definitions(d2stats_ui PRIVATE
	D2STATS_UI_EXPORTS
	UNICODE
	_UNICODE
	WIN32_LEAN_AND_MEAN
	NOMINMAX
)

if(MSVC)
	target_compile_options(d2stats_ui PRIVATE /utf-8 /W3)
endif()

target_link_libraries(d2stats_ui PRIVATE
	d3d11
	dxgi
	d3dcompiler
	gdi32
	user32
	shell32
	ole32
)

set(D2STATS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set_target_properties(d2stats_ui PROPERTIES
	OUTPUT_NAME "d2stats_ui"
	RUNTIME_OUTPUT_DIRECTORY "${D2STATS_ROOT}"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${D2STATS_ROOT}"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${D2STATS_ROOT}"
	LIBRARY_OUTPUT_DIRECTORY "${D2STATS_ROOT}"
	LIBRARY_OUTPUT_DIRECTORY_DEBUG "${D2STATS_ROOT}"
	LIBRARY_OUTPUT_DIRECTORY_RELEASE "${D2STATS_ROOT}"
	ARCHIVE_OUTPUT_DIRECTORY "${D2STATS_ROOT}"
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${D2STATS_ROOT}"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${D2STATS_ROOT}"
	PREFIX ""
)
