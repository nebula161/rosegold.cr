require "../src/rosegold"
require "spectator"

test_count = 0
Spectator.configure do |config|
  config.before_each do |_| # Runs a block of code before each example.
    test_count += 1
    ENV["MC_NAME"] = "rosegoldtest#{(test_count % 9) + 1}"
  end
end
