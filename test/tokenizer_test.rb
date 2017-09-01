gem "minitest"
require 'minitest/autorun'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/tokenizer.rb"

class TestTokenizer < Minitest::Test
  def test_classify
    sq = 39.chr
    bs = 92.chr

    t = Sneaql::Core::Tokenizer.new
    [
      [' ', :whitespace],
      [bs, :escape],
      ['f', :word],
      ['-', :word],
      [':', :colon],
      [sq, :singlequote],
      ['{', :openbrace],
      ['}', :closebrace],
      ['>', :operator],
      ['%', :nonword],
    ].each do |c|
      assert_equal(
        c[1],
        t.classify(c[0])
      )
    end
  end

  def test_classify_all
    sq = 39.chr
    bs = 92.chr

    t = Sneaql::Core::Tokenizer.new
    assert_equal(
      [
        :whitespace,
        :escape,
        :word,
        :colon,
        :singlequote,
        :openbrace,
        :closebrace,
        :operator,
        :nonword
      ],
      t.classify_all(' ' + bs + 'f:' + sq + '{}>%')
    )
  end

  def test_tokenize
    sq = 39.chr
    bs = 92.chr

    t = Sneaql::Core::Tokenizer.new
    [
      [
        'execute_if a = 2',
        [
          'execute_if',
          'a',
          '=',
          '2'
        ]
      ],
      [
        'execute_if a = -2',
        [
          'execute_if',
          'a',
          '=',
          '-2'
        ]
      ],
      [
        'execute_if a = '+ sq + 'hello world' + sq,
        [
          'execute_if',
          'a',
          '=',
          "'hello world'"
        ]
      ],
      [
        'execute_if a = '+ sq + 'hello' + bs + sq +'s world' + sq,
        [
          'execute_if',
          'a',
          '=',
          "'hello's world'"
        ]
      ]
    ].each do |c|
      assert_equal(
        c[1],
        t.tokenize(c[0])
      )
    end
  end
end
