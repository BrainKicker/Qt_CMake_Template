if (NOT DEFINED PRINT_EXECUTABLE_SIZE)
	set(PRINT_EXECUTABLE_SIZE FALSE)
endif()
if (NOT DEFINED EXECUTABLE_SIZE_OUTPUT_LENGTH)
	set(EXECUTABLE_SIZE_OUTPUT_LENGTH 10) # Used in 'printf' command
endif()


function(set_up_compilation EXECUTABLE_NAME EXECUTABLE_PATH)
	cmake_parse_arguments(SET_UP "" "" "DEFINITIONS;OPTIONS" ${ARGN})
	target_compile_definitions(${EXECUTABLE_NAME} PRIVATE ${SET_UP_DEFINITIONS})
	target_compile_options(${EXECUTABLE_NAME} PRIVATE ${SET_UP_OPTIONS})
	if(PRINT_EXECUTABLE_SIZE)
		add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD VERBATIM COMMAND echo) # New line before output
		add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD VERBATIM
				COMMAND bash -c "size=$(stat -c%s ${EXECUTABLE_PATH}); printf 'Size of the executable:   %${EXECUTABLE_SIZE_OUTPUT_LENGTH}d bytes\\n' $size")
	endif()
endfunction()


function(add_strip_command EXECUTABLE_NAME EXECUTABLE_PATH)
	cmake_parse_arguments(STRIP "" "" "OPTIONS" ${ARGN})
	add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD
			COMMAND strip ${STRIP_OPTIONS} ${EXECUTABLE_PATH}
			COMMENT "Stripping executable: ${EXECUTABLE_NAME}")
	if(PRINT_EXECUTABLE_SIZE)
		add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD VERBATIM
				COMMAND bash -c "size=$(stat -c%s ${EXECUTABLE_PATH}); printf 'Size after 'strip' command: %${EXECUTABLE_SIZE_OUTPUT_LENGTH}d bytes\\n' $size")
	endif()
endfunction()


function(add_upx_command EXECUTABLE_NAME EXECUTABLE_PATH)
	cmake_parse_arguments(UPX "" "" "OPTIONS" ${ARGN})
	add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD
			COMMAND upx ${UPX_OPTIONS} ${EXECUTABLE_PATH}
			COMMENT "Compressing executable: ${EXECUTABLE_NAME}")
#    # Remove 'UPX!' occurrences in the resulting file.
#    # Can be used for other strings too: 'PROT_EXEC|PROT_WRITE failed.\n', ...
#	add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD VERBATIM
#			COMMAND python -c "n='${EXECUTABLE_PATH}';r=b'UPX!';f=open(n,'r+b');d=f.read().replace(r,b'\\0'*len(r));f.seek(0);f.write(d)")
	if(PRINT_EXECUTABLE_SIZE)
		add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD VERBATIM
				COMMAND bash -c "size=$(stat -c%s ${EXECUTABLE_PATH}); printf 'Size after 'upx' command:   %${EXECUTABLE_SIZE_OUTPUT_LENGTH}d bytes\\n' $size")
	endif()
endfunction()