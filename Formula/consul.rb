class Consul < Formula
  desc "Tool for service discovery, monitoring and configuration"
  homepage "https://www.consul.io"
  url "https://github.com/hashicorp/consul.git",
      :tag      => "v1.6.1",
      :revision => "9be6dfc310ddd54627d698537a98827245185290"
  head "https://github.com/hashicorp/consul.git",
       :shallow => false

  bottle do
    cellar :any_skip_relocation
    sha256 "68b0d5d33d3121017ec1007b3aa6a59ca9ae1e0e3239ec798b0866f4a8f75e7b" => :catalina
    sha256 "bc99db5d92d406b6f1f94af1360ca8f9a1d04cbf68e195490f7e5bc8a1833c13" => :mojave
    sha256 "ef5a6a6ff48cc04b35d5b7e7ebb43a5cf0cb5abad7fb3d9d3eef1582ea1c0e49" => :high_sierra
    sha256 "0aba9ab485ca5777c07b678c93a5fffe76020fe5b7dfb45bd11b83794443f9af" => :sierra
    sha256 "c5b4f4e887b3fbc8aadf058b05396c7f6fb09a8f1fd3688d10374e133d46ea89" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on "gox" => :build
  depends_on "zip" => :build unless OS.mac?

  def install
    inreplace *(OS.mac? ? "scripts/build.sh" : "build-support/functions/20-build.sh"), "-tags=\"${GOTAGS}\" \\", "-tags=\"${GOTAGS}\" -parallel=4 \\"

    # Avoid running `go get`
    inreplace "GNUmakefile", "go get -u -v $(GOTOOLS)", ""

    ENV["XC_OS"] = OS.mac? ? "darwin" : "linux"
    ENV["XC_ARCH"] = "amd64"
    ENV["GOPATH"] = buildpath
    contents = Dir["{*,.git,.gitignore}"]
    (buildpath/"src/github.com/hashicorp/consul").install contents

    (buildpath/"bin").mkpath

    cd "src/github.com/hashicorp/consul" do
      system "make"
      bin.install "bin/consul"
      prefix.install_metafiles
    end
  end

  plist_options :manual => "consul agent -dev -advertise 127.0.0.1"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/consul</string>
          <string>agent</string>
          <string>-dev</string>
          <string>-advertise</string>
          <string>127.0.0.1</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/consul.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/consul.log</string>
      </dict>
    </plist>
  EOS
  end

  test do
    # Workaround for Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
    return if ENV["CIRCLECI"] || ENV["TRAVIS"]

    fork do
      exec "#{bin}/consul", "agent", *("-bind" unless OS.mac?), *("127.0.0.1" unless OS.mac?), "-data-dir", "."
    end
    sleep 3
    system "#{bin}/consul", "leave"
  end
end
