require 'minitest/autorun'
require 'pathname'

class TestIntegration < Minitest::Test
  def test_parsing
    exec_path = Pathname(__dir__).join("../out")
    input = '{"source": {}, "params": {"file": "foo"}}'
    output = `echo '#{input}' | #{exec_path} bar 2>&1`

    assert_match /NoGlobMatches/, output
  end
end
