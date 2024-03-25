# 第一阶段：基于 Rust 环境构建 wasm 文件
FROM rust:latest as build
WORKDIR /src
COPY . .
RUN rustup target add wasm32-wasi
RUN cargo build --release --target wasm32-wasi

# 第二阶段：安装 containerd-shim-wasmtime
FROM rust:latest as runtime
WORKDIR /src
RUN apt-get update && apt-get install -y protobuf-compiler git
RUN git clone https://github.com/containerd/runwasi.git
WORKDIR /src/runwasi
RUN cargo build --release
RUN cp target/release/containerd-shim-wasmtime-v1 /out/

# 第三阶段：从 scratch 开始，复制 wasm 文件和 containerd-shim-wasmtime 到新的镜像
FROM scratch
COPY --from=build /src/target/wasm32-wasi/release/docker-wasm-demo-rust.wasm /hello.wasm
COPY --from=runtime /out/containerd-shim-wasmtime-v1 /containerd-shim-wasmtime-v1
ENTRYPOINT [ "/containerd-shim-wasmtime-v1" ]
CMD ["/hello.wasm"]
