class Terragrunt < Formula
  desc "Thin wrapper for Terraform e.g. for locking state"
  homepage "https://github.com/gruntwork-io/terragrunt"
  url "https://github.com/gruntwork-io/terragrunt.git",
    :tag      => "v0.20.2",
    :revision => "a602f2535b12c2ff559839d2901dd8bb197ca2c2"

  bottle do
    cellar :any_skip_relocation
    sha256 "41c39882e7c23aa07e09a467b4b3808a8a650aac260957eaaa7ff3fea113386c" => :catalina
    sha256 "45c139ac721106ddeecb8da50497acb9d86ce40ab7fa7ed29b4aaae6c54ef94d" => :mojave
    sha256 "3cb5d0d0ef6a9cb798a4a4aec76af802ee9942d2cd7b097d27f61a14ef505168" => :high_sierra
    sha256 "9e3badd954d9930c1de152d482d9360f1291e48dcf99443fcfcd0afff4efaa41" => :x86_64_linux
  end

  depends_on "dep" => :build
  depends_on "go" => :build
  depends_on "terraform"

  def install
    ENV["GOPATH"] = buildpath
    (buildpath/"src/github.com/gruntwork-io/terragrunt").install buildpath.children
    cd "src/github.com/gruntwork-io/terragrunt" do
      system "dep", "ensure", "-vendor-only"
      system "go", "build", "-o", bin/"terragrunt", "-ldflags", "-X main.VERSION=v#{version}"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/terragrunt --version")
  end
end
