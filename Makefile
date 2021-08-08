WWW = www

.PHONY: build push

all: build push

build:
	umask 022
	hugo -D
push:
	rsync -arvpsS ./public/ $(WWW):/var/www/vcdb/
