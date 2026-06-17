# ═══════════════════════════════════════════════════
#  Aether Player — Makefile (CMake + Ninja 封装)
#
#  底层构建系统已切换为 CMake + Ninja。
#  此 Makefile 仅提供便捷命令。
# ═══════════════════════════════════════════════════

.PHONY: help configure build build-linux build-windows build-android package clean

help: ## Show this help
	@echo "Aether Player — CMake + Ninja Build System"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Direct CMake usage:"
	@echo "    cmake -B build -G Ninja"
	@echo "    cmake --build build"
	@echo "    cmake --build build --target package-deb"

configure: ## Configure build (Linux)
	cmake -B build -G Ninja

configure-deb: ## Configure with .deb packaging
	cmake -B build -G Ninja -DPACKAGE_DEB=ON

build: ## Build everything (Go + Flutter)
	cmake --build build

build-server: ## Build Go backend only
	cmake --build build --target server

build-flutter: ## Build Flutter only
	cmake --build build --target flutter-build

package: ## Package (.deb, depends on configure flags)
	cmake --build build --target package

clean: ## Clean all build artifacts
	rm -rf build app/build
