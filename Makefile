build:
	shards build --release
install: build
	mv ./bin/polycry ~/.bin/
