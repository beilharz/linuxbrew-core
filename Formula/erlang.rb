class Erlang < Formula
  desc "Programming language for highly scalable real-time systems"
  homepage "https://www.erlang.org/"
  # Download tarball from GitHub; it is served faster than the official tarball.
  url "https://github.com/erlang/otp/archive/OTP-22.1.2.tar.gz"
  sha256 "e8ba2c0613f8d505431b86411dd950b91f83f3c4777ce9f03bacb4f76133db4b"
  head "https://github.com/erlang/otp.git"
  revision 1 unless OS.mac?

  bottle do
    cellar :any
    sha256 "73a601d70910ca6c1cc064c11ef4519984c31294d39178a5311066e00a7e33bb" => :catalina
    sha256 "4d63f315543296f42f99d9f28f58c5b6f950785e5f17f94f4b5feda749fcb07f" => :mojave
    sha256 "57a30dcf9841e7dc79356b24c48d772e4111878ae392e1b2e0c414e774a779dc" => :high_sierra
    sha256 "ef643e7bb86533d14315d95bff39a02926ec4c59ad0c0bd24fcda9371fed0f4a" => :x86_64_linux
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  if OS.mac?
    depends_on "openssl@1.1"
  else
    # Since Homebrew/homebrew-core#41037, erlang uses openssl@1.1.
    # We can not have a mix of openssl and openssl@1.1 in the dependency tree on Linux.
    depends_on "openssl"
  end
  depends_on "wxmac" # for GUI apps like observer

  depends_on "m4" => :build unless OS.mac?

  resource "man" do
    url "https://www.erlang.org/download/otp_doc_man_22.1.tar.gz"
    mirror "https://fossies.org/linux/misc/otp_doc_man_22.1.tar.gz"
    sha256 "64f45909ed8332619055d424c32f8cc8987290a1ac4079269572fba6ef9c74d9"
  end

  resource "html" do
    url "https://www.erlang.org/download/otp_doc_html_22.1.tar.gz"
    mirror "https://fossies.org/linux/misc/otp_doc_html_22.1.tar.gz"
    sha256 "3864ac1aa30084738d783d12c241c0a4943cf22a6d1d0f6c7bb9ba0a45ecb9eb"
  end

  def install
    # Work around Xcode 11 clang bug
    # https://bitbucket.org/multicoreware/x265/issues/514/wrong-code-generated-on-macos-1015
    ENV.append_to_cflags "-fno-stack-check" if DevelopmentTools.clang_build_version >= 1010

    # Unset these so that building wx, kernel, compiler and
    # other modules doesn't fail with an unintelligable error.
    %w[LIBS FLAGS AFLAGS ZFLAGS].each { |k| ENV.delete("ERL_#{k}") }

    # Do this if building from a checkout to generate configure
    system "./otp_build", "autoconf" if File.exist? "otp_build"

    args = %W[
      --disable-debug
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-dynamic-ssl-lib
      --enable-hipe
      --enable-sctp
      --enable-shared-zlib
      --enable-smp-support
      --enable-threads
      --enable-wx
      --with-ssl=#{OS.mac? ? Formula["openssl@1.1"].opt_prefix : Formula["openssl"].opt_prefix}
      --without-javac
    ]

    if OS.mac?
      args << "--enable-darwin-64bit"
      args << "--enable-kernel-poll" if MacOS.version > :el_capitan
      args << "--with-dynamic-trace=dtrace" if MacOS::CLT.installed?
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    (lib/"erlang").install resource("man").files("man")
    doc.install resource("html")
  end

  def caveats; <<~EOS
    Man pages can be found in:
      #{opt_lib}/erlang/man

    Access them with `erl -man`, or add this directory to MANPATH.
  EOS
  end

  test do
    system "#{bin}/erl", "-noshell", "-eval", "crypto:start().", "-s", "init", "stop"
  end
end
