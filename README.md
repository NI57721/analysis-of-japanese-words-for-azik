# Analysis of Japanese words for AZIK
This is scripts for analysis of Japanese, which tells us how often we input each of Roman combinations when we input Japanese :h

## Prerequisite
- Ruby ( => 3.3.0)
- Ruby Gems
  - mecab  ( => 0.996)
  - nokogiri ( => 1.18.0)

## Installation of resources
```bash
$ bin/install-articles.sh
```

By default, this script downloads all of the one hundred featured articles listed [here](https://ja.wikipedia.org/wiki/Wikipedia:%E7%A7%80%E9%80%B8%E3%81%AA%E8%A8%98%E4%BA%8B) on 29th December, 2024, and all of 161 [Vim ekiden](https://vim-jp.org/ekiden/) articles that is written as of the date mentioned above with polite tone, *keitai (敬体)*.
Fetched contents are saved in directories under tmp.
Note that this process will take a while.

## Analysis
```bash
$ bin/analysis.rb wikipedia > wikipedia.json
$ bin/analysis.rb ekiden > ekiden.json
```

The analysis script returns JSON-formatted strings that has three keys, that is, "vowel", "consonant", and "vowel_combination". The value for each key is an array in descending order to the frequency whose values consist of [pattern, count].

## Resutls
Here are the results of the analysis; [that for Wikipedia](https://gist.github.com/NI57721/2facb3227fa009c7d51e23710a2dc125) and [that for Vim ekiden](https://gist.github.com/NI57721/63eab2ddf9a0f4fa40e77c717eff84ce). Both of them are formed to make them easy to read.
