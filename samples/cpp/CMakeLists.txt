cmake_minimum_required (VERSION 2.8)

include(CheckCXXCompilerFlag)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -DDEBUG")

######################################################################
# Find boost and include desired components
######################################################################
set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost 1.54.0 COMPONENTS program_options system thread
# custom <boost lib components>
# end <boost lib components>
)

## TO ENABLE LIB INIT LOGGING MOVE THIS TO custom
## set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DLIB_INIT_LOGGING")

# custom <misc section>
# end <misc section>


######################################################################
# Add additional link directories
######################################################################
link_directories(
# custom <link directories>
# end <link directories>

)

enable_testing()

######################################################################
# Add additional include directories
######################################################################
include_directories(
  ${CMAKE_CURRENT_LIST_DIR}
  ${Boost_INCLUDE_DIRS}
# custom <include directories>

  ~/dev/open_source/cpp_ebisu/cpp

# end <include directories>

)

######################################################################
# Lib sources
######################################################################


######################################################################
# Application build directives
######################################################################
add_executable(person_sample
  app/person_sample/person_sample.cpp
)

# custom <person_sample exe additions>
# end <person_sample exe additions>

target_link_libraries(person_sample
# custom <person_sample libs>
# end <person_sample libs>
  ${Boost_PROGRAM_OPTIONS_LIBRARY}
  ${Boost_SYSTEM_LIBRARY}
  ${Boost_THREAD_LIBRARY}
)


######################################################################
# Test directives
######################################################################


######################################################################
# Benchmark directives
######################################################################

