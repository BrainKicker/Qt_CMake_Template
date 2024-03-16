cmake_minimum_required(VERSION 3.22)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_VERBOSE_MAKEFILE ON)

project(<Your project name>)


include(Functions.cmake)


# ======
# For Qt
# ======
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


# Setting for Qt resources
set(EMBED_RESOURCES TRUE) # Embed resources
# set(EMBED_RESOURCES FALSE) # Do not embed resources
if(EMBED_RESOURCES)
	add_compile_definitions(EMBED_RESOURCES=1)
else()
	add_compile_definitions(EMBED_RESOURCES=0)
endif()


# =============
# Settings dirs
# =============
# Dir names
set(SOURCES_DIR_NAME src)
set(HEADERS_DIR_NAME src)
set(INCLUDE_DIR_NAME include)
set(UI_DIR_NAME ui)
set(RESOURCES_DIR_NAME res)
add_compile_definitions(RESOURCES_DIR_NAME="${RESOURCES_DIR_NAME}")
# Resources
set(TRANSLATIONS_DIR_NAME i18n)
set(QML_DIR_NAME qml)
set(QSS_DIR_NAME qss)
set(IMAGES_DIR_NAME images)
set(FONTS_DIR_NAME fonts)
add_compile_definitions(
		TRANSLATIONS_DIR_NAME="${TRANSLATIONS_DIR_NAME}"
		STYLES_DIR_NAME="${STYLES_DIR_NAME}"
		IMAGES_DIR_NAME="${IMAGES_DIR_NAME}"
		FONTS_DIR_NAME="${FONTS_DIR_NAME}"
)
# Executable
set(BUILD_DIR_NAME build)

# Project dirs
set(SOURCES_DIR ${PROJECT_SOURCE_DIR}/${SOURCES_DIR_NAME})
set(HEADERS_DIR ${PROJECT_SOURCE_DIR}/${HEADERS_DIR_NAME})
set(INCLUDE_DIR ${PROJECT_SOURCE_DIR}/${INCLUDE_DIR_NAME})
set(UI_DIR ${PROJECT_SOURCE_DIR}/${UI_DIR_NAME})
set(RESOURCES_DIR ${PROJECT_SOURCE_DIR}/${RESOURCES_DIR_NAME})
# Resource dirs
set(TRANSLATIONS_DIR ${RESOURCES_DIR}/${TRANSLATIONS_DIR_NAME})
set(QML_DIR ${RESOURCES_DIR}/${QML_DIR_NAME})
set(QSS_DIR ${RESOURCES_DIR}/${QSS_DIR_NAME})
set(IMAGES_DIR ${RESOURCES_DIR}/${IMAGES_DIR_NAME})
set(FONTS_DIR ${RESOURCES_DIR}/${FONTS_DIR_NAME})

# Executable dirs
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${BUILD_DIR_NAME})


# ===================
# Setting file groups
# ===================
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS
		${SOURCES_DIR}/*.cpp ${SOURCES_DIR}/*.c ${SOURCES_DIR}/*.cxx ${SOURCES_DIR}/*.cc
		${SOURCES_DIR}/*.CPP ${SOURCES_DIR}/*.C ${SOURCES_DIR}/*.c++ ${SOURCES_DIR}/*.cp)
file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS
		${HEADERS_DIR}/*.hpp ${HEADERS_DIR}/*.h ${HEADERS_DIR}/*.hxx ${HEADERS_DIR}/*.hh
		${HEADERS_DIR}/*.HPP ${HEADERS_DIR}/*.H ${HEADERS_DIR}/*.h++ ${HEADERS_DIR}/*.hp)
file(GLOB_RECURSE UI_FILES CONFIGURE_DEPENDS ${UI_DIR}/*.ui)
file(GLOB_RECURSE RESOURCES CONFIGURE_DEPENDS ${RESOURCES_DIR}/*)
# Resources
file(GLOB_RECURSE TS_FILES CONFIGURE_DEPENDS ${TRANSLATIONS_DIR}/*.ts)
file(GLOB_RECURSE QML_FILES CONFIGURE_DEPENDS ${QML_DIR}/*.qml)
file(GLOB_RECURSE QSS_FILES CONFIGURE_DEPENDS ${QSS_DIR}/*.qss)
file(GLOB_RECURSE IMAGES CONFIGURE_DEPENDS ${IMAGES_DIR}/*)
file(GLOB_RECURSE FONTS CONFIGURE_DEPENDS ${FONTS_DIR}/*)


# =================
# Adding executable
# =================
set(EXECUTABLE_NAME ${PROJECT_NAME})
set(EXECUTABLE_PATH ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${EXECUTABLE_NAME})
add_executable(${EXECUTABLE_NAME} ${SOURCES} ${HEADERS} ${UI_FILES})


# =============================
# Including project directories
# =============================
target_include_directories(${EXECUTABLE_NAME} PRIVATE ${PROJECT_SOURCE_DIR})
target_include_directories(${EXECUTABLE_NAME} PRIVATE ${SOURCES_DIR})
target_include_directories(${EXECUTABLE_NAME} PRIVATE ${INCLUDE_DIR})


# ===================
# Setting up profiles
# ===================
set(EXECUTABLE_SIZE_OUTPUT_LENGTH 8) # Used in 'printf' command
set(PRINT_EXECUTABLE_SIZE TRUE)
if (CMAKE_BUILD_TYPE STREQUAL "Debug")

	set_up_compilation(${EXECUTABLE_NAME} ${EXECUTABLE_PATH}
			DEFINITIONS
			DEBUG _DEBUG DEBUG_MODE
			OPTIONS
			-Wall -O0 -g3)

elseif (CMAKE_BUILD_TYPE STREQUAL "Release")

	set_up_compilation(${EXECUTABLE_NAME} ${EXECUTABLE_PATH}
			DEFINITIONS
			RELEASE _RELEASE RELEASE_MODE NDEBUG NO_DEBUG
			OPTIONS
			-O3 -flto -s -Wl,-s -Wl,--gc-sections)
	add_strip_command(${EXECUTABLE_NAME} ${EXECUTABLE_PATH} OPTIONS -s)
	add_upx_command(${EXECUTABLE_NAME} ${EXECUTABLE_PATH} OPTIONS -qqq --best)

elseif (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")

	set_up_compilation(${EXECUTABLE_NAME} ${EXECUTABLE_PATH}
			DEFINITIONS
			RELEASE _RELEASE RELEASE_MODE NDEBUG NO_DEBUG RELWITHDEBINFO
			OPTIONS
			-O2 -flto -g3)

elseif (CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")

	set_up_compilation(${EXECUTABLE_NAME} ${EXECUTABLE_PATH}
			DEFINITIONS
			RELEASE _RELEASE RELEASE_MODE NDEBUG NO_DEBUG MINSIZEREL
			OPTIONS
			-Os -flto -s -Wl,-s -Wl,--gc-sections)
	add_strip_command(${EXECUTABLE_NAME} ${EXECUTABLE_PATH} OPTIONS -s)
	add_upx_command(${EXECUTABLE_NAME} ${EXECUTABLE_PATH} OPTIONS -qqq --best --ultra-brute --overlay=strip)

elseif (CMAKE_BUILD_TYPE STREQUAL "Default" OR CMAKE_BUILD_TYPE STREQUAL "")
	set_up_compilation(${EXECUTABLE_NAME} ${EXECUTABLE_PATH}) # Only for size printing
else()
	message(FATAL_ERROR "Incorrect value for CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
endif()


# ==================
# Linking Qt library
# ==================
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Qml Quick)
target_link_libraries(${EXECUTABLE_NAME} Qt::Core Qt::Gui Qt::Widgets Qt::Qml Qt::Quick)


# =======================
# Generating translations
# =======================
find_package(Qt6 REQUIRED LinguistTools)

if (EMBED_RESOURCES)
	set(TS_FILES_OUTPUT_LOCATION ${CMAKE_BINARY_DIR}/.lrelease)
else ()
	set(TS_FILES_OUTPUT_LOCATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RESOURCES_DIR_NAME}/${TRANSLATIONS_DIR_NAME})
endif ()

set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION ${TS_FILES_OUTPUT_LOCATION})

qt_add_lupdate(${EXECUTABLE_NAME}
		TS_FILES ${TS_FILES}
		SOURCES ${SOURCES} ${HEADERS} ${UI_FILES}
		OPTIONS -no-obsolete -silent)
qt_add_lrelease(${EXECUTABLE_NAME}
		TS_FILES ${TS_FILES}
		QM_FILES_OUTPUT_VARIABLE QM_FILES
		OPTIONS -compress -nounfinished -removeidentical -silent)

if (EMBED_RESOURCES)
	qt_add_resources(${EXECUTABLE_NAME} "${TRANSLATIONS_DIR_NAME}"
			PREFIX "${TRANSLATIONS_DIR_NAME}"
			BASE ${TS_FILES_OUTPUT_LOCATION}
			FILES ${QM_FILES})
endif ()

add_dependencies(${EXECUTABLE_NAME} ${EXECUTABLE_NAME}_lupdate)
add_dependencies(${EXECUTABLE_NAME} ${EXECUTABLE_NAME}_lrelease)


# ===============
# Other resources
# ===============
if (EMBED_RESOURCES)
	qt_add_resources(${EXECUTABLE_NAME} "${QML_DIR_NAME}"
			PREFIX "${QML_DIR_NAME}"
			BASE ${QML_DIR}
			FILES ${QML_FILES})
	qt_add_resources(${EXECUTABLE_NAME} "${QSS_DIR_NAME}"
			PREFIX "${QSS_DIR_NAME}"
			BASE ${QSS_DIR}
			FILES ${QSS_FILES})
	qt_add_resources(${EXECUTABLE_NAME} "${IMAGES_DIR_NAME}"
			PREFIX "${IMAGES_DIR_NAME}"
			BASE ${IMAGES_DIR}
			FILES ${IMAGES})
	qt_add_resources(${EXECUTABLE_NAME} "${FONTS_DIR_NAME}"
			PREFIX "${FONTS_DIR_NAME}"
			BASE ${FONTS_DIR}
			FILES ${FONTS})
else ()
	add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD
			COMMAND cp -r ${QML_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RESOURCES_DIR_NAME}
			COMMAND cp -r ${STYLES_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RESOURCES_DIR_NAME}
			COMMAND cp -r ${IMAGES_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RESOURCES_DIR_NAME}
			COMMAND cp -r ${FONTS_DIR} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RESOURCES_DIR_NAME}
	)
endif ()