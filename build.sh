#!/bin/sh
rm -r build resources 2>/dev/null
hugo #--buildDrafts
chmod -R a+rX public resources
cp static/img/favicon.ico public/favicon.ico
cp static/img/favicon.ico public/favicon-32x32.ico
cp static/img/favicon.ico public/favicon-16x16.ico
