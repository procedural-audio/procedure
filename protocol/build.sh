rm -rf dart/lib/generated
mkdir dart/lib/generated
protoc --dart_out=grpc:dart/lib/generated -Iconfig config/protocol.proto
