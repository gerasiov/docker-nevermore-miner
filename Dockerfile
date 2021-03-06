ARG CUDA_VER=9.1
ARG MINER_VER=0.2.3

FROM nvidia/cuda:${CUDA_VER}-devel as build
ARG MINER_VER
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update&&apt-get install -qq --no-install-recommends -y build-essential git automake libssl-dev libcurl4-openssl-dev
RUN git clone https://github.com/brian112358/nevermore-miner.git \
	&& cd nevermore-miner \
	&& git checkout v${MINER_VER}

ENV CUDA_CFLAGS="-O3 -lineno -Xcompiler -Wall  -D_FORCE_INLINES"
ENV CXXFLAGS="-O3 -D_REENTRANT -falign-functions=16 -falign-jumps=16 -falign-labels=16"
COPY dev-fee.patch /nevermore-miner
RUN cd nevermore-miner \
	&& ./autogen.sh \
	&& ./configure --with-cuda=/usr/local/cuda --with-nvml=libnvidia-ml.so \
	&& patch -p1 < dev-fee.patch \
	&& make -j $(nproc)

FROM nvidia/cuda:${CUDA_VER}-base
LABEL maintainer="Alexander Gerasiov"
RUN apt-get update&&apt-get install -qq --no-install-recommends libcurl3 libgomp1&&rm -rf /var/lib/apt/lists/*
COPY --from=build /nevermore-miner/ccminer /
ENTRYPOINT ["/ccminer"]
