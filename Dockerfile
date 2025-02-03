# bring in the micromamba image so we can copy files from it
FROM mambaorg/micromamba:1.5.10 AS micromamba

# This is the image we are going add micromaba to:
FROM nvidia/cuda:11.7.1-devel-ubuntu22.04

USER root

# if your image defaults to a non-root user, then you may want to make the
# next 3 ARG commands match the values in your image. You can get the values
# by running: docker run --rm -it my/image id -a
ARG MAMBA_USER=mambauser
ARG MAMBA_USER_ID=57439
ARG MAMBA_USER_GID=57439
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_entrypoint.sh /usr/local/bin/_entrypoint.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh

USER $MAMBA_USER

SHELL ["/usr/local/bin/_dockerfile_shell.sh"]

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# Optional: if you want to customize the ENTRYPOINT and have a conda
# environment activated, then do this:
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "my_entrypoint_program"]

# You can modify the CMD statement as needed....
CMD ["/bin/bash"]



# Cuda Environment Variables
#ENV CUDA_HOME="/usr/local/cuda"
ENV TCNN_CUDA_ARCHITECTURES=86
#ENV TCNN_CUDA_ARCHITECTURES=90;89;86;80;75;70;61;52;37
ARG TORCH_CUDA_ARCH_LIST="8.6+PTX"
#ARG TORCH_CUDA_ARCH_LIST="3.7;5.2;6.1;7.0;7.5;8.6;8.9;9.0+PTX"
ARG CUDA_ARCHITECTURES=86
#ARG CUDA_ARCHITECTURES=90;89;86;80;75;70;61;52;37


ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
USER root

RUN apt update --fix-missing && apt install -y wget gnupg2 git cmake


RUN apt install -y python3 python3-pip python3-venv \
libglew-dev libgl1-mesa-dev libglib2.0-0 libopencv-dev protobuf-compiler libgoogle-glog-dev libboost-all-dev libhdf5-dev libatlas-base-dev

RUN mkdir /external

WORKDIR /workspace

RUN cd /external && git clone https://github.com/NVIDIA/cuda-samples.git
#RUN cd /external/cuda-samples/ && make
ENV CUDA_SAMPLES_INC=/external/cuda-samples/Common



COPY --chown=$MAMBA_USER:$MAMBA_USER submodules/openpose /workspace/submodules/openpose
RUN cd submodules/openpose && mkdir build && cd build && cmake -DUSE_CUDNN=OFF .. && make -j`nproc`

COPY --chown=$MAMBA_USER:$MAMBA_USER ./requirements.txt /workspace/requirements.txt
COPY --chown=$MAMBA_USER:$MAMBA_USER ./environment.yaml /workspace/environment.yaml
COPY --chown=$MAMBA_USER:$MAMBA_USER submodules/smplify-x/requirements.txt /workspace/submodules/smplify-x/requirements.txt




RUN cd /workspace && micromamba install -y -n base -f ./environment.yaml && \
    micromamba clean --all --yes


	
ARG MAMBA_DOCKERFILE_ACTIVATE=1





