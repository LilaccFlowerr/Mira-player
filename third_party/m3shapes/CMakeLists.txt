# Adapted build integration; upstream C++ and shader sources are unchanged.
file(GLOB_RECURSE shape_sources CONFIGURE_DEPENDS include/*.hpp src/*.cpp)
qt_add_qml_module(m3shapes STATIC URI M3Shapes VERSION 1.0 SOURCES ${shape_sources})
target_include_directories(m3shapes PUBLIC include PRIVATE include/m3shapes/qml)
target_link_libraries(m3shapes PUBLIC Qt6::Quick Qt6::Qml)
qt_add_shaders(m3shapes m3shapes_shaders PREFIX /m3shapes BASE src FILES src/shaders/smoothshape.vert src/shaders/smoothshape.frag)
