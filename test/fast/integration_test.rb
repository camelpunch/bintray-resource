require 'minitest/autorun'
require 'pathname'
require 'json'

class TestFastIntegration < Minitest::Test
  def test_parsing
    exec_path = Pathname(__dir__).join("../../out")
    input = '{"source": {}, "params": {"file": "foo"}}'
    output = `echo '#{input}' | #{exec_path} bar 2>&1`

    assert_match /NoGlobMatches/, output
  end

  def test_in_echos_version
    exec_path = Pathname(__dir__).join("../../in")
    input = JSON.generate(
      "source" => { "" => "" },
      "version" => {
        "mynumber" => "3.6.x"
      }
    )
    output = `echo '#{input}' | #{exec_path} somedestination 2>&1`

    assert_equal(
      {"version" => {"mynumber" => "3.6.x"}},
      JSON.parse(output)
    )
  end

  def test_in_returns_zero
    exec_path = Pathname(__dir__).join("../../in")
    input = JSON.generate(
      "source" => { "" => "" },
      "version" => {
        "mynumber" => "3.6.x"
      }
    )

    assert(system("echo '#{input}' | #{exec_path} somedestination > /dev/null"))
  end
end
