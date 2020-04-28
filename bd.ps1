$debug_flags = " -debug -opt:0 -vet -define:DEBUG=1"
$release_flags = " -disable-assert -opt:3 -define:DEBUG=0"
$common_flags = "-show-timings -collection:shared=../shared"
odin build . -show-timings -collection:shared=../shared -opt:2
