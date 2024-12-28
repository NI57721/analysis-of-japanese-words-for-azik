#!/usr/bin/bash -eu

wikipedia_titles=resources/wikipedia
wikipedia_tmp_dir=tmp/wikipedia
ekiden_urls=resources/vim-ekiden
ekiden_tmp_dir=tmp/ekiden

mkdir --parents $wikipedia_tmp_dir $ekiden_tmp_dir

query=$(ruby -ruri -e "puts URI.encode_uri_component('特別:データ書き出し')")
cat $wikipedia_titles | while read title; do
  echo $title
  title=${title// /_}
  encodedTitle=$(ruby -ruri -e "puts URI.encode_uri_component(\"${title//"/\\"}\")")
  curl https://ja.wikipedia.org/w/index.php?title=$query/$encodedTitle > $wikipedia_tmp_dir/$title.xml
  sleep 1
done

mkdir --parents ekiden_articles
cat $ekiden_urls | while read url; do
  echo $url
  slug=${url##*/}
  curl https://zenn.dev/$url > $ekiden_tmp_dir/$slug.xml
  sleep 1
done

