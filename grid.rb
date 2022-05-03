cask "grid" do
  version "0.2"
  sha256 "d3b85049a06134b2712668f5fbfbdce13bc4ed907a5bda6e127dc952193e1196"

  url "https://github.com/yannpom/Grid/releases/download/v#{version}/Grid.app.zip"
  name "Grid"
  desc "Window managment app"
  homepage "https://github.com/yannpom/Grid"

  app "Grid.app"
end
