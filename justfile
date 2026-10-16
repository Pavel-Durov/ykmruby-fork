yk_config := "/path/to/yk-config"
yk_profile := "release"

build: build-plain

build-plain:
    rake -m -j$(nproc)

# The instruction-size tables are static in the the codegen.c, so
# core can't import them. Extract them into src/yk_insn_size.h instead of
# keeping a hand-copied duplicate that could drift.
gen-yk-insn-size:
    scripts/gen_yk_insn_size.sh

build-yk: build-plain gen-yk-insn-size
    YK_CONFIG={{yk_config}} YK_PROFILE={{yk_profile}} rake clean MRUBY_CONFIG=yk_wordboxing
    YK_CONFIG={{yk_config}} YK_PROFILE={{yk_profile}} rake -m -j$(nproc) MRUBY_CONFIG=yk_wordboxing

test: test-plain

test-plain: build-plain
    rake test

test-yk: build-yk
    build/yk_wordboxing/bin/mruby -e 'puts "hello"'

hello: build-plain
    build/host/bin/mruby -e 'puts "hello"'

hello-yk: build-yk
    build/yk_wordboxing/bin/mruby -e 'puts "hello"'

clean:
    rake clean
