WWW = www

.PHONY: build update push

all: update build push

build:
	umask 022
	hugo -D
	find public -type d -exec chmod o+x "{}" \;
	chmod -R o+r public

update:
	cd content/vcdb; git pull origin master
push:
	rsync -arvpsS ./public/ $(WWW):/var/www/vcdb/
