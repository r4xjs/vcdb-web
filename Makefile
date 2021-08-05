
.PHONY: build
build:
	rm -rf .org-cache/*
	rm -rf build/*
	emacs -q --batch -l ./builder.el --funcall raxjs/build
	rm -rf .generate/*
generate:
	emacs -q --batch -l ./builder.el --funcall raxjs/generate-org-files



