#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'mecab'
require 'nokogiri'

class Analyser
  ArticlesPath = 'tmp/wikipedia'
  EkidenPath = 'tmp/ekiden'
  Vowels = %w[a e i o u]
  Consonants = %w[k ky g gy s sy z zy t ty ts n ny h hy f b by p py v m my y r w]
  Others = %w[L N]

  class << self
    def analyse_ekiden
      result = Array.new(3){Hash.new(0)}
      files = Dir.children(EkidenPath)
      "InsertButtonToCodeBlock"
      files.each do |fname|
        html = Nokogiri::HTML.parse(open(EkidenPath + '/' + fname).read)
        text = html.css('[class^=InsertButtonToCodeBlock]').to_s
        if text.empty?
          text = html.to_s
        end
        analyse(text, result)
      end
      result
    end

    def analyse_wikipedia
      result = Array.new(3){Hash.new(0)}
      files = Dir.children(ArticlesPath)
      files.each do |fname|
        text = open(ArticlesPath + '/' + fname).read
        analyse(text, result)
      end
      result
    end

    def analyse(text, hashes = Array.new(3){Hash.new(0)})
      nodes = Node.new(text)
      roman = Roman.romanize(nodes.each_bunsetsu(katakana: false).map(&:itself).join(' '))
      count_vowel(hashes[0], roman)
      count_consonant(hashes[0], roman)
      count_vowel_combination(hashes[1], roman)
      count_consonant_combination(hashes[2], roman)
      hashes
    end

    def count_vowel(hash, roman)
      (Vowels + Others).each do |c|
        hash[c] += roman.scan(c).count
      end
    end

    def count_consonant(hash, roman)
      Consonants.map do |c|
        hash[c] += roman.scan(c).count
      end
    end

    def count_vowel_combination(hash, roman)
      (Vowels + Others).each do |c1|
        (Vowels + Others).each do |c2|
          hash[c1 + c2] += roman.scan(Regexp.new(c1 + '[^ aeiou]*' + c2)).count
        end
      end
    end

    def count_consonant_combination(hash, roman)
      Vowels.each do |c1|
        ([''] + Others).each do |c2|
          ([''] + Consonants).each do |c3|
            %w[a e i o u].each do |c4|
              regexp = Regexp.new('(' + Consonants.join('|') + ')' + c1 + c2 + c3 + c4)
              hash[c1 + c2 + c3 + c4] += roman.scan(regexp).count
            end
          end
        end
      end
    end
  end
end

class Node
  def initialize(sentence, *params)
    @sentence = sentence
    @tagger = MeCab::Tagger.new(params.join(' '))
  end

  def each_node
    return to_enum(:each_node) unless block_given?

    node = @tagger.parseToNode(@sentence)
    until node.nil?
      yield node unless node.feature.start_with?('BOS/EOS,')
      node = node.next
    end

    self
  end

  # Iterate words by separating sentences by bunsetsu or the ends of nouns.
  # If katakata is false, skip a word when the word ends with a katakana character or ー.
  def each_bunsetsu(katakana: true)
    return to_enum(:each_bunsetsu, katakana:) unless block_given?

    words = []
    each_node do |node|
      word = Word.new(node)
      if word.meishi?
        yield Word.combine(words) unless words.empty?
        yield Word.combine([word]) if (katakana || word.genkei !~ /[\p{Katakana}ー]$/) && !word.yomi.nil?
        words.clear
        next
      elsif (word.able_to_start_bunsetsu? || word.kigou?) && !words.empty?
        yield Word.combine(words)
        words.clear
      end
      words.push(word) unless word.kigou?
    end
    yield Word.combine(words) unless words.all?(&:kigou?)
    self
  end
end

class Word
  attr_reader :hinshi, :category1, :category2, :category3, :katsuyougata,
    :katsuyoukei, :genkei, :yomi, :hatsuon
  StartOfBunsetsu = %w[名詞 動詞 接頭詞 副詞 感動詞 形容詞 形容動詞 連体詞]

  def initialize(node)
    @hinshi, @category1, @category2, @category3, @katsuyougata, @katsuyoukei,
      @genkei, @yomi, @hatsuon = node.feature.split(',')
  end

  def able_to_start_bunsetsu?
      StartOfBunsetsu.include?(@hinshi)
  end

  def meishi?
    @hinshi == '名詞'
  end

  def kigou?
    @hinshi == '記号'
  end

  class << self
    def combine(words)
      words.flat_map(&:yomi).join
    end
  end
end

class Roman
  attr_reader :katakana
  KatakanaToRoman = {
    'ア' => 'a',
    'イ' => 'i',
    'ウ' => 'u',
    'エ' => 'e',
    'オ' => 'o',
    'カ' => 'ka',
    'キ' => 'ki',
    'ク' => 'ku',
    'ケ' => 'ke',
    'コ' => 'ko',
    'キャ' => 'kya',
    'キュ' => 'kyu',
    'キェ' => 'kye',
    'キョ' => 'kyo',
    'ガ' => 'ga',
    'ギ' => 'gi',
    'グ' => 'gu',
    'ゲ' => 'ge',
    'ゴ' => 'go',
    'ギャ' => 'gya',
    'ギュ' => 'gyu',
    'ギェ' => 'gye',
    'ギョ' => 'gyo',
    'サ' => 'sa',
    'シ' => 'si',
    'ス' => 'su',
    'セ' => 'se',
    'ソ' => 'so',
    'シャ' => 'sya',
    'シュ' => 'syu',
    'シェ' => 'sye',
    'ショ' => 'syo',
    'ザ' => 'za',
    'ジ' => 'zi',
    'ズ' => 'zu',
    'ゼ' => 'ze',
    'ゾ' => 'zo',
    'ジャ' => 'zya',
    'ジュ' => 'zyu',
    'ジェ' => 'zye',
    'ジョ' => 'zyo',
    'タ' => 'ta',
    'チ' => 'ti',
    'ツ' => 'tu',
    'テ' => 'te',
    'ト' => 'to',
    'チャ' => 'tya',
    'チュ' => 'tyu',
    'チェ' => 'tye',
    'チョ' => 'tyo',
    'ツァ' => 'tsa',
    'ツィ' => 'tsi',
    'ツェ' => 'tse',
    'ツォ' => 'tso',
    'ダ' => 'da',
    'ヂ' => 'di',
    'ヅ' => 'du',
    'デ' => 'de',
    'ド' => 'do',
    'ヂャ' => 'dya',
    'ヂュ' => 'dyu',
    'ヂェ' => 'dye',
    'ヂョ' => 'dyo',
    'ナ' => 'na',
    'ニ' => 'ni',
    'ヌ' => 'nu',
    'ネ' => 'ne',
    'ノ' => 'no',
    'ニャ' => 'nya',
    'ニュ' => 'nyu',
    'ニェ' => 'nye',
    'ニョ' => 'nyo',
    'ハ' => 'ha',
    'ヒ' => 'hi',
    'フ' => 'hu',
    'ヘ' => 'he',
    'ホ' => 'ho',
    'ヒャ' => 'hya',
    'ヒュ' => 'hyu',
    'ヒェ' => 'hye',
    'ヒョ' => 'hyo',
    'ファ' => 'fa',
    'フィ' => 'fi',
    'フェ' => 'fe',
    'フォ' => 'fo',
    'バ' => 'ba',
    'ビ' => 'bi',
    'ブ' => 'bu',
    'ベ' => 'be',
    'ボ' => 'bo',
    'ビャ' => 'bya',
    'ビュ' => 'byu',
    'ビェ' => 'bye',
    'ビョ' => 'byo',
    'ヴァ' => 'va',
    'ヴィ' => 'vi',
    'ヴ' => 'vu',
    'ヴェ' => 've',
    'ヴォ' => 'vo',
    'パ' => 'pa',
    'ピ' => 'pi',
    'プ' => 'pu',
    'ペ' => 'pe',
    'ポ' => 'po',
    'ピヤ' => 'pya',
    'ピュ' => 'pyu',
    'ピェ' => 'pye',
    'ピョ' => 'pyo',
    'マ' => 'ma',
    'ミ' => 'mi',
    'ム' => 'mu',
    'メ' => 'me',
    'モ' => 'mo',
    'ミャ' => 'mya',
    'ミュ' => 'myu',
    'ミェ' => 'mye',
    'ミョ' => 'myo',
    'ヤ' => 'ya',
    'ユ' => 'yu',
    'ヨ' => 'yo',
    'ラ' => 'ra',
    'リ' => 'ri',
    'ル' => 'ru',
    'レ' => 're',
    'ロ' => 'ro',
    'リャ' => 'rya',
    'リュ' => 'ryu',
    'リェ' => 'rye',
    'リョ' => 'ryo',
    'ワ' => 'wa',
    'ヰ' => 'wi',
    'ヱ' => 'we',
    'ヲ' => 'wo',
    'ー' => '-',
    'ン' => 'N',
    'ッ' => 'L',
  }

  def initialize(katakana)
    @katakana = katakana
  end

  def romanize
    @katakana.gsub(/[\p{Katakana}][ァィゥェォャュョ]?/, KatakanaToRoman)
  end

  class << self
    def romanize(katakana)
      roman = self.new(katakana)
      roman.katakana.gsub(/[\p{Katakana}][ァィゥェォャュョ]?/, KatakanaToRoman)
    end
  end
end

def to_json(analysed_data)
  result = {}
  result[:vowel], result[:consonant], result[:vowel_combination] =
    analysed_data.map do |arr|
      arr.sort{|a, b| b[1] <=> a[1]}
    end
  JSON.generate(result)
end

def main(argv)
  case argv[0]
  when 'wikipedia'
    to_json(Analyser.analyse_wikipedia)
  when 'ekiden'
    to_json(Analyser.analyse_ekiden)
  else
    raise('%s given to %s' % [
      argv.size == 1 ? 'An invalid argument is' : 'Invalid arguments are',
      $PROGRAM_NAME
    ])
  end
end

puts main(ARGV)

