#!/bin/bash
cd "$(dirname "$0")"
export PATH=/usr/local/Cellar/ruby/3.3.5/bin:"$PATH"    
asciidoctor-pdf *.adoc