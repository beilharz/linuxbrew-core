# This formula tracks 1.0.2 branch of OpenSSL, not the 1.1.0 branch. Due to
# significant breaking API changes in 1.1.0 other formulae will be migrated
# across slowly, so core will ship `openssl` & `openssl@1.1` for foreseeable.
class Openssl < Formula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.0.2q.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl--1.0.2q.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.0.2q.tar.gz"
  mirror "http://artfiles.org/openssl.org/source/openssl-1.0.2q.tar.gz"
  sha256 "5744cfcbcec2b1b48629f7354203bc1e5e9b5466998bbccc5b5fcde3b18eb684"
  revision 2 unless OS.mac?

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    sha256 "011686250576397948e08ccc4c77db2edd3ba2c2e2ddfc24dfaca15dd1744d08" => :x86_64_linux
  end

  keg_only :provided_by_macos,
    "Apple has deprecated use of OpenSSL in favor of its own TLS and crypto libraries"

  unless OS.mac?
    resource "cacert" do
      # homepage "http://curl.haxx.se/docs/caextract.html"
      url "https://curl.haxx.se/ca/cacert-2019-01-23.pem"
      mirror "http://linuxbrew.bintray.com/bottles/cacert-2019-01-23.pem"
      sha256 "c1fd9b235896b1094ee97bfb7e042f93530b5e300781f59b45edf84ee8c75000"
    end
  end

  def install
    # openssl does not in fact require an executable stack.
    ENV.append_to_cflags "-Wa,--noexecstack" unless OS.mac?

    # OpenSSL will prefer the PERL environment variable if set over $PATH
    # which can cause some odd edge cases & isn't intended. Unset for safety,
    # along with perl modules in PERL5LIB.
    ENV.delete("PERL")
    ENV.delete("PERL5LIB")

    ENV.deparallelize
    args = %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      no-ssl3
      no-zlib
      shared
      enable-cms
      #{[ENV.cppflags, ENV.cflags, ENV.ldflags].join(" ").strip unless OS.mac?}
    ]
    if OS.mac?
      args << "darwin64-x86_64-cc"
      args << "enable-ec_nistp_64_gcc_128"
    else
      args << "linux-x86_64"
      args << "enable-md2"
    end
    system "perl", "./Configure", *args
    system "make", "depend"
    system "make"
    if which "cmp"
      system "make", "test"
    else
      opoo "Skipping `make check` due to unavailable `cmp`"
    end
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
  end

  def openssldir
    etc/"openssl"
  end

  def post_install
    unless OS.mac?
      # Download and install cacert.pem from curl.haxx.se
      cacert = resource("cacert")
      rm_f openssldir/"cert.pem"
      filename = Pathname.new(cacert.url).basename
      openssldir.install cacert.files(filename => "cert.pem")
      return
    end

    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(
      /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m,
    )

    valid_certs = certs.select do |cert|
      IO.popen("#{bin}/openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    openssldir.mkpath
    (openssldir/"cert.pem").atomic_write(valid_certs.join("\n") << "\n")
  end

  def caveats; <<~EOS
    A CA file has been bootstrapped using certificates from the SystemRoots
    keychain. To add additional certificates (e.g. the certificates added in
    the System keychain), place .pem files in
      #{openssldir}/certs

    and run
      #{opt_bin}/c_rehash
  EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_predicate HOMEBREW_PREFIX/"etc/openssl/openssl.cnf", :exist?,
            "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system "#{bin}/openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
