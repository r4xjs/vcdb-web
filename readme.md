```shell
git clone https://github.com/r4xjs/vcdb-web
cd vcdb-web
git submodule init
git submodule update
chmod -R o+r *
find . -type d -exec chmod o+x "{}" \;
```
