cmake_minimum_required(VERSION 3.21)
project(SongPowder VERSION 1.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Multimedia Sql Concurrent Network)
find_package(Qt6 6.5 REQUIRED COMPONENTS ShaderTools)
find_package(Qt6 6.5 QUIET OPTIONAL_COMPONENTS Test)
qt_policy(SET QTP0001 NEW)

# Link-time optimisation for Release builds (when the toolchain supports it)
include(CheckIPOSupported)
check_ipo_supported(RESULT SP_IPO_OK OUTPUT SP_IPO_MSG)
if(SP_IPO_OK)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
endif()

# ---- core library (no QML dependency, unit-testable) ----
add_library(songpowder_core STATIC
    src/Core/Types.h src/Core/Types.cpp
    src/Core/Logger.h src/Core/Logger.cpp
    src/Settings/SettingsManager.h src/Settings/SettingsManager.cpp
    src/Customization/CustomizationManager.h src/Customization/CustomizationManager.cpp
    src/Database/Database.h src/Database/Database.cpp
    src/LyricsManager/LyricsManager.h src/LyricsManager/LyricsManager.cpp
    src/Ui/EqualizerRing.h src/Ui/EqualizerRing.cpp
    src/MediaLibrary/TrackModel.h src/MediaLibrary/TrackModel.cpp
    src/MediaLibrary/MetadataExtractor.h src/MediaLibrary/MetadataExtractor.cpp
    src/MediaLibrary/LibraryManager.h src/MediaLibrary/LibraryManager.cpp
    src/AudioEngine/PlayerController.h src/AudioEngine/PlayerController.cpp
    src/AudioEngine/SpectrumAnalyzer.h src/AudioEngine/SpectrumAnalyzer.cpp
)
# CustomizationManager.h is moc-processed on its own; skip scanning the .cpp (guards against a stray Q_OBJECT there)
set_source_files_properties(src/Customization/CustomizationManager.cpp PROPERTIES SKIP_AUTOMOC ON)
target_include_directories(songpowder_core PUBLIC src)
target_link_libraries(songpowder_core PUBLIC Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
    Qt6::Multimedia Qt6::Sql Qt6::Concurrent)
if(MSVC)
    target_compile_options(songpowder_core PUBLIC /W4 /utf-8 /permissive-)
else()
    target_compile_options(songpowder_core PUBLIC -Wall -Wextra)
endif()

# ---- application ----
set(SP_QML_FILES
    qml/Main.qml
    qml/Themes/Theme.qml
    qml/Themes/Strings.qml
    qml/Pages/MyAudiosPage.qml
    qml/Pages/RecentPlaysPage.qml
    qml/Pages/PlaylistsPage.qml
    qml/Pages/SettingsPage.qml
    qml/Pages/NowPlayingPage.qml
    qml/Components/Background.qml
    qml/Components/GlassPanel.qml
    qml/Components/IconButton.qml
    qml/Components/AppToolTip.qml
    qml/Components/VolumeButton.qml
    qml/Components/PillButton.qml
    qml/Components/PlayingCover.qml
    qml/Components/CoverImage.qml
    qml/Components/EmptyState.qml
    qml/Components/AppSearchField.qml
    qml/Components/SortButton.qml
    qml/Pages/CustomizationPage.qml
    qml/Pages/CzAppearance.qml
    qml/Pages/CzThemes.qml
    qml/Pages/CzLayout.qml
    qml/Pages/CzPlayer.qml
    qml/Pages/CzBackground.qml
    qml/Pages/CzGlass.qml
    qml/Pages/CzMotion.qml
    qml/Pages/CzTypography.qml
    qml/Pages/CzControls.qml
    qml/Pages/CzVisualizer.qml
    qml/Pages/CzProfiles.qml
    qml/Components/CzSwitch.qml
    qml/Components/CzSlider.qml
    qml/Components/CzChoice.qml
    qml/Components/CzColor.qml
    qml/Components/CzFont.qml
    qml/Components/CzFile.qml
    qml/Components/CzNamePopup.qml
    qml/Components/CzConfirm.qml
    qml/Components/CzCollection.qml
    qml/Components/NavItem.qml
    qml/Components/Sidebar.qml
    qml/Components/TrackList.qml
    qml/Components/Timeline.qml
    qml/Components/TransportControls.qml
    qml/Components/MiniPlayer.qml
    qml/Components/SettingsCard.qml
    qml/Components/SettingsRow.qml
    qml/Components/TitleBar.qml
)
foreach(f ${SP_QML_FILES})
    get_filename_component(n ${f} NAME)
    set_source_files_properties(${f} PROPERTIES QT_RESOURCE_ALIAS ${n})
endforeach()
set_source_files_properties(
    qml/Themes/Theme.qml
    qml/Themes/Strings.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_executable(SongPowder WIN32 app/main.cpp app/app.rc)
qt_add_qml_module(SongPowder
    URI SongPowder
    VERSION 1.0
    QML_FILES ${SP_QML_FILES}
    RESOURCES
        resources/logo/songpowder.png
        resources/logo/songpowder-dark.png
        resources/logo/songpowder-light.png
        resources/logo/songpowder-mono.png
        resources/logo/songpowder.svg
)
# GPU shader for the animated liquid background (compiled to .qsb at build time)
qt_add_shaders(SongPowder "songpowder_shaders"
    PRECOMPILE
    OPTIMIZED
    PREFIX "/shaders"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/qml/shaders"
    FILES qml/shaders/liquid.frag
)

target_compile_definitions(SongPowder PRIVATE SONGPOWDER_VERSION="${PROJECT_VERSION}")
target_link_libraries(SongPowder PRIVATE songpowder_core Qt6::QuickControls2 Qt6::Network)
set_target_properties(SongPowder PROPERTIES OUTPUT_NAME "SongPowder")
if(WIN32)
    target_link_libraries(SongPowder PRIVATE user32)   # MessageBoxW for startup errors
endif()

# Copy the Qt runtime (DLLs, platform/sqldrivers/multimedia/qml plugins) next to the exe after every build, so the
# exe starts when double-clicked and not only from inside Qt Creator. Disable with -DSP_AUTO_DEPLOY=OFF.
option(SP_AUTO_DEPLOY "Run windeployqt after build (Windows)" ON)
if(WIN32 AND SP_AUTO_DEPLOY)
    set(_sp_qtbin "")
    if(TARGET Qt6::qmake)
        get_target_property(_sp_qmake Qt6::qmake IMPORTED_LOCATION)
        get_filename_component(_sp_qtbin "${_sp_qmake}" DIRECTORY)
    endif()
    find_program(SP_WINDEPLOYQT windeployqt HINTS "${_sp_qtbin}")
    if(SP_WINDEPLOYQT)
        add_custom_command(TARGET SongPowder POST_BUILD
            COMMAND "${SP_WINDEPLOYQT}"
                $<IF:$<CONFIG:Debug>,--debug,--release>
                --qmldir "${CMAKE_CURRENT_SOURCE_DIR}/qml"
                --no-translations --no-system-d3d-compiler
                "$<TARGET_FILE:SongPowder>"
            COMMENT "windeployqt: deploying Qt runtime next to SongPowder.exe")
    else()
        message(WARNING "windeployqt not found: SongPowder.exe will not start outside Qt Creator")
    endif()
endif()

install(TARGETS SongPowder RUNTIME DESTINATION .)

# ---- tests ----
if(Qt6Test_FOUND)
    enable_testing()
    foreach(t tst_lyrics tst_database tst_player tst_customization)
        add_executable(${t} tests/${t}.cpp)
        target_link_libraries(${t} PRIVATE songpowder_core Qt6::Test)
        add_test(NAME ${t} COMMAND ${t})
    endforeach()
endif()