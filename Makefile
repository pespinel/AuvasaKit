.PHONY: help format lint lint-fix build test clean check install-hooks

# Default target
help:
	@echo "AuvasaKit - Available targets:"
	@echo ""
	@echo "  make format       - Format code with SwiftFormat"
	@echo "  make lint         - Run SwiftLint"
	@echo "  make lint-fix     - Auto-fix SwiftLint violations where possible"
	@echo "  make build        - Build the package"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make check        - Run format + lint + build (pre-commit check)"
	@echo "  make install-hooks - Install git pre-commit hook"
	@echo ""

# Format code with SwiftFormat
format:
	@echo "📝 Formatting code with SwiftFormat..."
	@swiftformat . --quiet || (echo "❌ SwiftFormat failed. Install with: brew install swiftformat" && exit 1)
	@echo "✅ Formatting complete"

# Run SwiftLint
lint:
	@echo "🔎 Linting with SwiftLint..."
	@swiftlint lint --strict || (echo "❌ SwiftLint found violations" && exit 1)
	@echo "✅ Linting passed"

# Auto-fix SwiftLint violations
lint-fix:
	@echo "🔧 Auto-fixing SwiftLint violations..."
	@swiftlint --fix --format || (echo "❌ SwiftLint autocorrect failed" && exit 1)
	@echo "✅ Auto-fix complete"

# Build the package
build:
	@echo "🔨 Building package..."
	@swift build
	@echo "✅ Build complete"

# Run tests
test:
	@echo "🧪 Running tests..."
	@swift test
	@echo "✅ Tests passed"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf .build
	@rm -rf .swiftpm
	@echo "✅ Clean complete"

# Full check (format + lint + build) - used by pre-commit and CI
check: format lint build
	@echo ""
	@echo "✅ All checks passed! Ready to commit."

# Install git pre-commit hook
install-hooks:
	@echo "📦 Installing git pre-commit hook..."
	@mkdir -p .git/hooks
	@echo '#!/bin/sh' > .git/hooks/pre-commit
	@echo 'make check' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Pre-commit hook installed"
	@echo "   Hook will run 'make check' before each commit"
