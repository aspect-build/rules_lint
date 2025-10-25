"Utilities to register Terraform/TFLint toolchains when using WORKSPACE mode."

load("@rules_tf//tf/toolchains:toolchains.bzl", "tf_toolchains")
load("@rules_tf//tf/toolchains/terraform:toolchain.bzl", "terraform_download")
load("@rules_tf//tf/toolchains/tflint:toolchain.bzl", "tflint_download")
load("@rules_tf//tf/toolchains/tfdoc:toolchain.bzl", "tfdoc_download")
load("@rules_tf//tf/toolchains/tofu:toolchain.bzl", "tofu_download")
load("@rules_tf//tf:versions.bzl", "TFDOC_VERSION", "TFLINT_VERSION")
load("@host_platform//:constraints.bzl", "HOST_CONSTRAINTS")

_DEFAULT_MIRROR = {"aws": "hashicorp/aws:5.90.0"}

def rules_lint_setup_tf_toolchains(
        version = None,
        mirror = None,
        tflint_version = None,
        tfdoc_version = None,
        use_tofu = False,
        repo_prefix = "rules_lint"):
    """Register Terraform/TFLint toolchains in WORKSPACE installs.

    This helper mirrors the `tf_repositories.download` module extension from `rules_tf`
    so that WORKSPACE users can obtain the same binaries. The host OS/arch is detected
    automatically using Bazel's host platform constraints.

    Args:
        version: Terraform (or OpenTofu when `use_tofu=True`) version to download.
        mirror: Map of Terraform providers to mirror alongside the toolchain.
        tflint_version: Version of TFLint to download. Defaults to rules_tf setting.
        tfdoc_version: Version of terraform-docs to download. Defaults to rules_tf setting.
        use_tofu: If True, downloads OpenTofu instead of Terraform.
        repo_prefix: Prefix used for the intermediate repositories created by this helper.
    """
    if version == None:
        fail("rules_lint_setup_tf_toolchains requires the 'version' argument to be set")

    host_os = _detect_host_os()
    host_arch = _detect_host_arch()

    mirror = mirror or _DEFAULT_MIRROR
    tflint_version = tflint_version or TFLINT_VERSION
    tfdoc_version = tfdoc_version or TFDOC_VERSION

    terraform_repo = "{}_tf_{}_{}".format(repo_prefix, host_os, host_arch)
    terraform_download(
        name = terraform_repo,
        version = version,
        os = host_os,
        arch = host_arch,
        mirror = mirror,
    )

    tfdoc_repo = "{}_tfdoc_{}_{}".format(repo_prefix, host_os, host_arch)
    tfdoc_download(
        name = tfdoc_repo,
        version = tfdoc_version,
        os = host_os,
        arch = host_arch,
    )

    tflint_repo = "{}_tflint_{}_{}".format(repo_prefix, host_os, host_arch)
    tflint_download(
        name = tflint_repo,
        version = tflint_version,
        os = host_os,
        arch = host_arch,
    )

    tofu_repos = []
    if use_tofu:
        tofu_repo = "{}_tofu_{}_{}".format(repo_prefix, host_os, host_arch)
        tofu_download(
            name = tofu_repo,
            version = version,
            os = host_os,
            arch = host_arch,
            mirror = mirror,
        )
        tofu_repos.append(tofu_repo)

    tf_toolchains(
        name = "tf_toolchains",
        tflint_repos = [tflint_repo],
        tfdoc_repos = [tfdoc_repo],
        terraform_repos = [] if use_tofu else [terraform_repo],
        tofu_repos = tofu_repos,
        os = host_os,
        arch = host_arch,
    )

    native.register_toolchains("@tf_toolchains//:all")

def _detect_host_os():
    if "@platforms//os:linux" in HOST_CONSTRAINTS:
        return "linux"
    if "@platforms//os:osx" in HOST_CONSTRAINTS:
        return "darwin"
    if "@platforms//os:windows" in HOST_CONSTRAINTS:
        return "windows"
    fail("Unsupported host OS constraints: {}".format(HOST_CONSTRAINTS))

def _detect_host_arch():
    if (
        "@platforms//cpu:aarch64" in HOST_CONSTRAINTS or
        "@platforms//cpu:arm64" in HOST_CONSTRAINTS
    ):
        return "arm64"
    if (
        "@platforms//cpu:x86_64" in HOST_CONSTRAINTS or
        "@platforms//cpu:amd64" in HOST_CONSTRAINTS
    ):
        return "amd64"
    fail("Unsupported host architecture constraints: {}".format(HOST_CONSTRAINTS))
