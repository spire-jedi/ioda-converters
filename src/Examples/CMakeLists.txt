# src/EXamples/CMakeLists.txt
#

list(APPEND scripts
  smap_sss2newioda.py
)

# Set up targets based on each file in the programs list
foreach( FILENAME ${scripts} )
  set( SOURCE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME} )
  set( DEST_FILE ${CMAKE_BINARY_DIR}/bin/${FILENAME} )
  list( APPEND example_scripts_deps ${DEST_FILE} )
  add_custom_command(
      OUTPUT ${DEST_FILE}
      DEPENDS ${SOURCE_FILE}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/bin
      COMMAND ${CMAKE_COMMAND} -E copy ${SOURCE_FILE} ${DEST_FILE}
      COMMAND chmod +x ${DEST_FILE} )
endforeach(FILENAME)
add_custom_target( bin_example_scripts ALL DEPENDS ${example_scripts_deps} )

install( PROGRAMS ${scripts} DESTINATION bin )

ecbuild_add_test( TARGET iodaconv_examples_coding_norms
                  TYPE
                  COMMAND ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}_lint.sh
                  ARGS ${CMAKE_CURRENT_SOURCE_DIR} ${IODACONV_PYLINT_CFG_DIR} )
