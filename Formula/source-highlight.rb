class SourceHighlight < Formula
  desc "Source-code syntax highlighter"
  homepage "https://www.gnu.org/software/src-highlite/"
  url "https://ftp.gnu.org/gnu/src-highlite/source-highlight-3.1.8.tar.gz"
  mirror "https://ftpmirror.gnu.org/src-highlite/source-highlight-3.1.8.tar.gz"
  mirror "https://fossies.org/linux/www/source-highlight-3.1.8.tar.gz"
  sha256 "01336a7ea1d1ccc374201f7b81ffa94d0aecb33afc7d6903ebf9fbf33a55ada3"
  revision 13

  bottle do
    sha256 "3f543911ca3cd1b2327299415578cb8906e0da69297196672647434d949c4177" => :catalina
    sha256 "3fb0d7d6af8c83428f9ec59583f272ac5937c72fd193d44498b0aa37b5d2d6d6" => :mojave
    sha256 "b74d7d2073739465a5a634a41fb16d9c98bd73d03066450b853997bc15465da5" => :high_sierra
    sha256 "8238f507791ed199b72ebbe0e473de1c7945bb88e8943754c3474a5bdad7d563" => :sierra
    sha256 "239847a37fe91a665b169329ea1072b9189ecba1ac4c3320d1d8c003f999dc9b" => :x86_64_linux
  end

  depends_on "boost"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-boost=#{Formula["boost"].opt_prefix}"
    system "make", "install"

    bash_completion.install "completion/source-highlight"
  end

  test do
    assert_match /GNU Source-highlight #{version}/, shell_output("#{bin}/source-highlight -V")
  end
end
