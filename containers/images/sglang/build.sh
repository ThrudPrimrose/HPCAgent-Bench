#!/usr/bin/env bash
set -euo pipefail

# Build the SGLang inference image and import it to a squashfs. Run it on a COMPUTE node via
# build.sbatch: the base alone is 52 GB and cupy compiles from source.
#
# The build context is the REPOSITORY ROOT, because the Dockerfile bakes in the tuned fused_moe
# configs from there. Nothing is reached from outside the image at RUN time: a package reached
# through PYTHONPATH is invisible to the image digest.

# Slurm propagates the submitter's core limit and a dump lands in the CWD (an inode-quota checkout).
ulimit -c 0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck source=../build_common.sh
source "${SCRIPT_DIR}/../build_common.sh"

IMAGE_TAG="${IMAGE_TAG:-hpcagent-bench-sglang:latest}"
OUTPUT_SQSH="${OUTPUT_SQSH:-${CE_IMAGES:?set SCRATCH or CE_IMAGES}/hpcagent-bench-sglang.sqsh}"
BASE_IMAGE="${BASE_IMAGE:-$(ce_dockerfile_base "${SCRIPT_DIR}/Dockerfile")}"

mkdir -p "$(dirname "${OUTPUT_SQSH}")"

# ROCM_ARCH from gpu_arch.env for this job's partition; an unknown partition stops before any pull.
ce_gpu_arch

ce_podman_env

BUILD_ARGS=(--build-arg "ROCM_ARCH=${ROCM_ARCH}")
ce_pull_first "${SCRIPT_DIR}/Dockerfile" "sglang||${IMAGE_TAG}|${OUTPUT_SQSH}" -- "${BUILD_ARGS[@]}"
[[ "${CE_PULLED}" == 0 ]] || exit 0

ce_mirror_args
ce_gpu_args
ce_cache_base_image
ce_build "${SCRIPT_DIR}/Dockerfile" "" "${IMAGE_TAG}" "${OUTPUT_SQSH}" "${MIRROR_ARGS[@]}" "${GPU_ARGS[@]}" "${BUILD_ARGS[@]}"
