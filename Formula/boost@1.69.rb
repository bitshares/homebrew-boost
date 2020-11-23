class BoostAT169 < Formula
  desc "Collection of portable C++ source libraries"
  homepage "https://www.boost.org/"
  url "https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.bz2"
  sha256 "8f32d4617390d1c2d16f26a27ab60d97807b35440d45891fa340fc2648b04406"
  revision 3
  head "https://github.com/boostorg/boost.git"

  keg_only :versioned_formula

  depends_on "icu4c"

  # Fix compiler version check on macOS
  # https://github.com/boostorg/build/pull/560
  # patch derived from https://github.com/boostorg/build/commit/40960b23338da0a359d6aa83585ace09ad8804d2
  patch :DATA

  def install
    # Force boost to compile with the desired compiler
    open("user-config.jam", "a") do |file|
      file.write "using darwin : : #{ENV.cxx} ;\n"
    end

    # libdir should be set by --prefix but isn't
    icu4c_prefix = Formula["icu4c"].opt_prefix
    bootstrap_args = %W[
      --prefix=#{prefix}
      --libdir=#{lib}
      --with-icu=#{icu4c_prefix}
    ]

    # Handle libraries that will not be built.
    without_libraries = ["python", "mpi"]

    # Boost.Log cannot be built using Apple GCC at the moment. Disabled
    # on such systems.
    without_libraries << "log" if ENV.compiler == :gcc

    bootstrap_args << "--without-libraries=#{without_libraries.join(",")}"

    # layout should be synchronized with boost-python and boost-mpi
    args = %W[
      --prefix=#{prefix}
      --libdir=#{lib}
      -d2
      -j#{ENV.make_jobs}
      --layout=tagged-1.66
      --user-config=user-config.jam
      -sNO_LZMA=1
      -sNO_ZSTD=1
      install
      threading=multi,single
      link=shared,static
    ]

    # Boost is using "clang++ -x c" to select C compiler which breaks C++14
    # handling using ENV.cxx14. Using "cxxflags" and "linkflags" still works.
    args << "cxxflags=-std=c++14"
    args << "cxxflags=-stdlib=libc++" << "linkflags=-stdlib=libc++" if ENV.compiler == :clang

    system "./bootstrap.sh", *bootstrap_args
    system "./b2", "headers"
    system "./b2", *args
  end

  def caveats
    s = ""
    # ENV.compiler doesn't exist in caveats. Check library availability
    # instead.
    if Dir["#{lib}/libboost_log*"].empty?
      s += <<~EOS
        Building of Boost.Log is disabled because it requires newer GCC or Clang.
      EOS
    end

    s
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <boost/algorithm/string.hpp>
      #include <string>
      #include <vector>
      #include <assert.h>
      using namespace boost::algorithm;
      using namespace std;

      int main()
      {
        string str("a,b");
        vector<string> strVec;
        split(strVec, str, is_any_of(","));
        assert(strVec.size()==2);
        assert(strVec[0]=="a");
        assert(strVec[1]=="b");
        return 0;
      }
    EOS
    system ENV.cxx, "-I#{include}", "test.cpp", "-std=c++1y", "-L#{lib}",
           "-lboost_system", "-o", "test"
    system "./test"
  end
end

__END__
diff --git a/tools/build/src/tools/darwin.jam b/tools/build/src/tools/darwin.jam
index 8d477410b0..97e7ecb851 100644
--- a/tools/build/src/tools/darwin.jam
+++ a/tools/build/src/tools/darwin.jam
@@ -137,13 +137,14 @@ rule init ( version ? : command * : options * : requirement * )
     # - Set the toolset generic common options.
     common.handle-options darwin : $(condition) : $(command) : $(options) ;
     
+    real-version = [ regex.split $(real-version) \\. ] ;
     # - GCC 4.0 and higher in Darwin does not have -fcoalesce-templates.
-    if $(real-version) < "4.0.0"
+    if [ version.version-less $(real-version) : 4 0 ]
     {
         flags darwin.compile.c++ OPTIONS $(condition) : -fcoalesce-templates ;
     }
     # - GCC 4.2 and higher in Darwin does not have -Wno-long-double.
-    if $(real-version) < "4.2.0"
+    if [ version.version-less $(real-version) : 4 2 ]
     {
         flags darwin.compile OPTIONS $(condition) : -Wno-long-double ;
     }
