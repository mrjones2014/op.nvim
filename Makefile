default: build-and-install

.PHONY: setup-hooks
setup-hooks:
	git config core.hooksPath .githooks/

.PHONY: build-macos
build-macos: clean
	cd go && GOOS=darwin GOARCH=amd64 go build -o ../bin/op-nvim-mac-amd64 && GOOS=darwin GOARCH=arm64 go build -o ../bin/op-nvim-mac-arm64
	lipo -create -output ./bin/op-nvim-mac-universal ./bin/op-nvim-mac-amd64 ./bin/op-nvim-mac-arm64
	rm -f ./bin/op-nvim-mac-amd64 ./bin/op-nvim-mac-arm64

.PHONY: build-linux
build-linux: clean
	cd go && GOOS=linux GOARCH=amd64 go build -o ../bin/op-nvim-linux

.PHONY: all
all: build-macos build-linux

.PHONY: clean
clean:
	rm -f ./bin/op-nvim-mac-universal ./bin/op-nvim-mac-arm64 ./bin/op-nvim-mac-arm64 ./bin/op-nvim-linux ./bin/op-nvim

.PHONY: test
test:
	@cd go && go test -v && cd ..

.PHONY: ensure-doc-deps
ensure-doc-deps:
	@mkdir -p lua-vendor
	@if test ! -d ./lua-vendor/ts-vimdoc.nvim; then git clone  git@github.com:ibhagwan/ts-vimdoc.nvim.git ./lua-vendor/ts-vimdoc.nvim/; fi
	@if test ! -d ./lua-vendor/nvim-treesitter; then git clone git@github.com:nvim-treesitter/nvim-treesitter.git ./lua-vendor/nvim-treesitter/; fi

.PHONY: update-doc-deps
update-doc-deps: ensure-doc-deps
	@echo "Updating ts-vimdoc.nvim..."
	@cd ./lua-vendor/ts-vimdoc.nvim/ && git pull && cd ..
	@echo "updating nvim-treesitter..."
	@cd ./lua-vendor/nvim-treesitter/ && git pull && cd ..

.PHONY: gen-vimdoc
gen-vimdoc: update-doc-deps
	@echo 'Installing Treesitter parsers...'
	@nvim --headless -u ./vimdocrc.lua -c 'TSUpdateSync markdown' -c 'TSUpdateSync markdown_inline' -c 'qa'
	@echo 'Generating vimdocs...'
	@nvim --headless -u ./vimdocrc.lua -c 'luafile ./vimdoc-gen.lua' -c 'qa'
	@nvim --headless -u ./vimdocrc.lua -c 'helptags doc' -c 'qa'

.PHONY: update-remote-plugin-manifest
update-remote-plugin-manifest: all install
	./bin/op-nvim --manifest op-nvim --location ./plugin/op.vim

.PHONY: install
install:
	rm -f ./bin/op-nvim
	mkdir -p bin
	./install.bash
	chmod +x ./bin/op-nvim

.PHONY: build-and-install
build-and-install: all install update-remote-plugin-manifest
