class Srb2 < Formula
  desc     "DOOM based 3D Sonic clone"
  homepage "https://www.srb2.org/"
  url      "https://github.com/STJr/SRB2/archive/refs/tags/SRB2_release_2.2.9.tar.gz"
  sha256   "5f7eeb08e90323e28cdcb02ad25c904eef25ce75316720609b995a1e4ffd154a"
  license  "GPL-2.0"

  option "with-debug", "Set the target build type to Debug"

  keg_only "builds a .app, rather than a command line application"
  depends_on "cmake" => :build
  depends_on "curl"
  depends_on "sdl2"
  depends_on "sdl2_mixer"
  depends_on "libpng"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "libopenmpt"
  depends_on :macos
  depends_on "game-music-emu"
  depends_on :xcode => "9.3"
  depends_on "zlib"

  resource "srb2_assets" do
    url "https://github.com/STJr/SRB2/releases/download/SRB2_release_2.2.9/SRB2-v229-Full.zip"
    sha256 "48e644604bed81b5ce6b12ef23a2f4042d0118d0ba70f18c534dfe86ebe6f37d"
  end

  # This prevents MacOS from loading external frameworks prior to libraries
  # installed by Homebrew. This (in particular) addresses issues with libpng
  # most often.
  #
  # REMOVAL:
  #   This patch can be safely removed when Issue #696 is fixed and merged
  #   into the most recent release here: https://github.com/STJr/SRB2/releases
  #
  # Issue: https://git.do.srb2.org/STJr/SRB2/-/issues/696
  patch :p1, :DATA

  def install
    build_type = "Release" unless build.with? "with-debug"
    build_type = "Debug" if build.with? "with-debug"
    
    ENV.append "LIBRARY_PATH", "#{HOMEBREW_PREFIX}"
    ENV.append "MACOS_DEPLOYMENT_TARGET", "10.9"
    
    args = [
      "-DCMAKE_PREFIX_PATH=#{HOMEBREW_PREFIX}",
      "-DCMAKE_INSTALL_PREFIX:PATH=#{prefix}",
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.9",
      "-DCMAKE_BUILD_TYPE=#{build_type}",

      # We need to manually specify this, as these libs cannot be found
      # by CMake otherwise
      "-DOPENMPT_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/libopenmpt",
      "-DGME_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/gme",
    ]

    # Place our downloaded assets into assets/installer. This step occurs
    # prior and satisfies assets/CMakeLists.txt. Leave only the files that
    # the game requires to run, and it's licenses. Otherwise the application
    # will be bundled with miscellanea that we don't require for packaging.
    mkdir_p "#{buildpath}/assets/installer"
    resource('srb2_assets').unpack "#{buildpath}/assets/installer"

    mkdir_p "#{buildpath}/build"
    chdir "#{buildpath}/build" do
      system 'cmake', '..', *args
      system 'make'

      chdir "#{buildpath}/assets/installer" do
        assets = %w[
          srb2.pk3 zones.pk3 player.dta models models.dat music.dta
          patch.pk3 patch_music.pk3 LICENSE.txt LICENSE-3RD-PARTY.txt
        ]

        Dir.foreach(".") do |f|
          next unless assets.include? f
          
          cp_r f.to_s, "#{buildpath}/build/bin/SRB2SDL2.app/Contents/Resources/"
        end
      end

      cp_r "#{buildpath}/build/bin/SRB2SDL2.app", "#{prefix}/SRB2.app"
    end
  end

  def caveats
    <<~EOS
      This formula creates a .app at #{prefix}/SRB2.app

      You can run "open #{prefix}/SRB2.app", or symlink this application to
      your ~/Applications directory:
        ln -s '#{prefix}/SRB2.app' ~/Applications/SRB2.app
    EOS
  end
end
__END__
diff --git a/CMakeLists.txt b/CMakeLists.txt.issue696
index 5d2d4a7..24c2f5b 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt.issue696
@@ -108,6 +108,7 @@ endif()
 
 if(${CMAKE_SYSTEM} MATCHES "Darwin")
 	add_definitions(-DMACOSX)
+	set(CMAKE_FIND_FRAMEWORK LAST)
 endif()
 
 set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")