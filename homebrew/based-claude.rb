class BasedClaude < Formula
  desc "A repo-owned, agent-native memory layer for Claude Code"
  homepage "https://github.com/aldinsmoresalient/based-claude"
  url "https://github.com/aldinsmoresalient/based-claude/archive/refs/tags/v1.0.0.tar.gz"
  # sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_CREATING_RELEASE"
  license "Apache-2.0"
  version "1.0.0"

  def install
    # Install the CLI and supporting files
    bin.install "bin/claude-sdk" => "based-claude"

    # Install supporting directories
    libexec.install "cli", "scripts", "skills", "subagents", "templates"

    # Create wrapper script that sets SDK_ROOT
    (bin/"based-claude").write <<~EOS
      #!/usr/bin/env bash
      export SDK_ROOT="#{libexec}"
      exec "#{libexec}/cli/../bin/claude-sdk" "$@"
    EOS
  end

  test do
    system "#{bin}/based-claude", "--version"
  end
end
