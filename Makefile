xml2rfc = "/usr/local/bin/xml2rfc"
saxpath = "$(HOME)/java/saxon-8-9-j/saxon8.jar"
saxon = java -classpath $(saxpath) net.sf.saxon.Transform -novw -l

draft_title = draft-ietf-httpbis-http2
current_rev = $(shell git tag | tail -1 | awk -F- '{print $$NF}')
next_rev = $(shell printf "%.2d" `echo ${current_rev}+1 | bc`)

stylesheet = lib/myxml2rfc.xslt
reduction  = lib/clean-for-DTD.xslt

extra_style = $(shell cat lib/style.css)

TARGETS = $(draft_title).html \
          $(draft_title).redxml \
          $(draft_title).txt

latest: $(TARGETS)

submit: $(draft_title)-$(next_rev).xml $(draft_title)-$(next_rev).txt

ifeq "$(shell uname -s 2>/dev/null)" "Darwin"
    sed_i := sed -i ''
else
    sed_i := sed -i
endif

$(draft_title)-$(next_rev).xml:
	cp $(draft_title).xml $(draft_title)-$(next_rev).xml
	$(sed_i) -e"s/$(draft_title)-latest/$(draft_title)-$(next_rev)/" $(draft_title)-$(next_rev).xml

.PHONY: idnits
idnits: $(draft_title)-$(next_rev).txt
	idnits $(draft_title)-$(next_rev).txt

clean:
	rm -f $(draft_title).redxml
	rm -f $(draft_title)*.txt
	rm -f $(draft_title)*.html

%.html: %.xml $(stylesheet)
	$(saxon) $< $(stylesheet) > $@
	$(sed_i) -e"s*</style>*</style><style tyle='text/css'>$(extra_style)</style>*" $@

%.redxml: %.xml $(reduction)
	$(saxon) $< $(reduction) > $@

%.txt: %.redxml
	$(xml2rfc) $< $@

%.xhtml: %.xml ../../rfc2629xslt/rfc2629toXHTML.xslt
	$(saxon) $< ../../rfc2629xslt/rfc2629toXHTML.xslt > $@

# backup issues
.PHONY: issues
issues:
	curl https://api.github.com/repos/http2/http2-spec/issues > issues.json
