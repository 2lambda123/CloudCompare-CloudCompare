cmake_minimum_required(VERSION 3.0)

project( CloudCompare VERSION 2.8.1 )

include_directories( ${CC_FBO_LIB_SOURCE_DIR}/include )
include_directories( ${CC_CORE_LIB_SOURCE_DIR}/include )
include_directories( ${QCC_DB_LIB_SOURCE_DIR} )
if( MSVC )
   include_directories( ${QCC_DB_LIB_SOURCE_DIR}/msvc )
endif()
include_directories( ${QCC_IO_LIB_SOURCE_DIR} )
include_directories( ${QCC_GL_LIB_SOURCE_DIR} )
include_directories( ${CloudComparePlugins_SOURCE_DIR} )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/db_tree )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/ui_templates )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/../libs/qxt )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/../libs/qcustomplot )
include_directories( ${CMAKE_CURRENT_BINARY_DIR} )

file( GLOB header_list *.h db_tree/*.h ${QXT_HEADERS} )
file( GLOB source_list *.cpp db_tree/*.cpp ${QXT_SOURCES} )

# 3DX support (3dConnexion devices)
if ( ${OPTION_SUPPORT_3DCONNEXION_DEVICES} )
	file( GLOB 3DX_header_list devices/3dConnexion/*.h )
	file( GLOB 3DX_source_list devices/3dConnexion/*.cpp )
	list( APPEND header_list ${3DX_header_list} )
	list( APPEND source_list ${3DX_source_list} )
endif()	

# Gamepad support (requires Qt 5.7+)
if ( ${OPTION_SUPPORT_GAMEPADS} )
	file( GLOB gamepad_header_list devices/gamepad/*.h )
	file( GLOB gamepad_source_list devices/gamepad/*.cpp )
	list( APPEND header_list ${gamepad_header_list} )
	list( APPEND source_list ${gamepad_source_list} )
endif()	

file( GLOB ui_list ui_templates/*.ui )
file( GLOB qrc_list *.qrc )

file( GLOB txt_list TODO.txt ${CloudCompareProjects_SOURCE_DIR}/CHANGELOG.md )

qt5_wrap_ui( generated_ui_list ${ui_list} )
qt5_add_resources( generated_qrc_list ${qrc_list} )

if( MSVC )
	# App icon with MSVC
	set( rc_list images/icon/cc_icon.rc )

	#to get rid of the (system) console
	add_executable( ${PROJECT_NAME} WIN32 ${header_list} ${source_list} ${generated_ui_list} ${generated_qrc_list} ${rc_list} ${txt_list} )
elseif( APPLE )
	add_executable( ${PROJECT_NAME} MACOSX_BUNDLE ${header_list} ${source_list} ${generated_ui_list} ${generated_qrc_list} ${txt_list} )
else()
	add_executable( ${PROJECT_NAME} ${header_list} ${source_list} ${generated_ui_list} ${generated_qrc_list} ${rc_list} ${txt_list} )
endif()

target_link_libraries( ${PROJECT_NAME} CC_FBO_LIB )
target_link_libraries( ${PROJECT_NAME} CC_CORE_LIB )
target_link_libraries( ${PROJECT_NAME} QCC_DB_LIB )
target_link_libraries( ${PROJECT_NAME} QCC_IO_LIB )
target_link_libraries( ${PROJECT_NAME} QCC_GL_LIB )
target_link_libraries( ${PROJECT_NAME} qcustomplot )

# Qt
qt5_use_modules(${PROJECT_NAME} Core Gui Widgets OpenGL PrintSupport)
if (WIN32)
	target_link_libraries( ${PROJECT_NAME} Qt5::WinMain )
endif()

# contrib. libraries support
if( APPLE )
	target_link_contrib( ${PROJECT_NAME} ${CLOUDCOMPARE_MAC_FRAMEWORK_DIR} )
elseif( UNIX )
  target_link_contrib( ${PROJECT_NAME} lib/cloudcompare )
else()
  target_link_contrib( ${PROJECT_NAME} ${CLOUDCOMPARE_DEST_FOLDER} )
endif()

# 3dConnexion devices support
if ( ${OPTION_SUPPORT_3DCONNEXION_DEVICES} )
	target_link_3DXWARE( ${PROJECT_NAME} )
endif()
# Gamepad support (requires Qt 5.7+)
if ( ${OPTION_SUPPORT_GAMEPADS} )
	target_link_GAMEPADS( ${PROJECT_NAME} )
endif()

# Add custom preprocessor definitions
if (OPTION_GL_QUAD_BUFFER_SUPPORT)
	set_property( TARGET ${PROJECT_NAME} APPEND PROPERTY COMPILE_DEFINITIONS CC_GL_WINDOW_USE_QWINDOW )
endif()
if( WIN32 )
	set_property( TARGET ${PROJECT_NAME} APPEND PROPERTY COMPILE_DEFINITIONS CC_USE_AS_DLL QCC_DB_USE_AS_DLL QCC_IO_USE_AS_DLL )
	if (MSVC)
		SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES LINK_FLAGS " /MANIFEST:NO")
	endif()
endif()

# App icon with Code::Blocks/MinGW
if( WIN32 )
	if( MINGW )
		if (NOT CMAKE_RC_COMPILER)
			set( CMAKE_RC_COMPILER windres )
		endif()
		add_custom_command( TARGET ${PROJECT_NAME} PRE_BUILD COMMAND ${CMAKE_RC_COMPILER} -i ${CMAKE_CURRENT_SOURCE_DIR}/images/icon/cc_icon.rc --input-format=rc -o ${CMAKE_CURRENT_BINARY_DIR}/cc_icon.res -O coff )
	endif()
endif()

# install program
install_ext( TARGETS ${PROJECT_NAME} ${CLOUDCOMPARE_DEST_FOLDER} )

# Auxiliary files
set( auxFiles  ${CloudCompareProjects_SOURCE_DIR}/CHANGELOG.md bin_other/license.txt bin_other/global_shift_list_template.txt )

if( WIN32 )
	# Export Qt dlls
	install_Qt_Dlls( ${CLOUDCOMPARE_DEST_FOLDER} ${OPTION_SUPPORT_GAMEPADS} )
	install_Qt_ImageFormats( ${CLOUDCOMPARE_DEST_FOLDER} )
	install_Qt5_plugins( ${CLOUDCOMPARE_DEST_FOLDER} )

	# Additional auxiliary file(s)
	file( GLOB batch_list bin_other/*.bat )
	list( APPEND auxFiles ${batch_list} )
endif()

# Install auxiliary files
if( WIN32 OR APPLE )
  foreach( filename ${auxFiles} )
	  install_ext( FILES ${filename} ${CLOUDCOMPARE_DEST_FOLDER} )
  endforeach()
else( UNIX )
  foreach( filename ${auxFiles} )
    install_ext( FILES ${filename} share/cloudcompare )
  endforeach()
endif()

# in order to ensure that everything else is installed first, put the Mac bundling in its own subdirectory
if( APPLE )
    set_target_properties( ${PROJECT_NAME} PROPERTIES
        INSTALL_RPATH "@executable_path/../Frameworks"
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Mac/CloudCompare.plist )

    set( MACOSX_BUNDLE_ICON_FILE cc_icon.icns ) 
    set( MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}" )
    set( MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}" )
    set( MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}" )
    
    add_subdirectory( Mac )
endif()

# Export common shader files to all install destinations
if( APPLE )
   install( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.frag DESTINATION ${CLOUDCOMPARE_MAC_BASE_DIR}/Contents/Shaders/Bilateral )
   install( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.vert DESTINATION ${CLOUDCOMPARE_MAC_BASE_DIR}/Contents/Shaders/Bilateral )
   install( FILES ${CMAKE_CURRENT_SOURCE_DIR}/shaders/ColorRamp/color_ramp.frag DESTINATION ${CLOUDCOMPARE_MAC_BASE_DIR}/Contents/Shaders/ColorRamp )
 elseif( UNIX )
  install( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.frag DESTINATION share/cloudcompare/shaders/Bilateral )
  install( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.vert DESTINATION share/cloudcompare/shaders/Bilateral )
  install( FILES ${CMAKE_CURRENT_SOURCE_DIR}/shaders/ColorRamp/color_ramp.frag DESTINATION share/cloudcompare/shaders/ColorRamp )
else()
   install_ext( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.frag ${CLOUDCOMPARE_DEST_FOLDER} /shaders/Bilateral )
   install_ext( FILES ${CC_FBO_LIB_SOURCE_DIR}/shaders/Bilateral/bilateral.vert ${CLOUDCOMPARE_DEST_FOLDER} /shaders/Bilateral )
   install_ext( FILES ${CMAKE_CURRENT_SOURCE_DIR}/shaders/ColorRamp/color_ramp.frag ${CLOUDCOMPARE_DEST_FOLDER} /shaders/ColorRamp )
endif()
