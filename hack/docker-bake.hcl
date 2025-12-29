group "default" {
  targets = ["regular"]
}

variable "IMAGE_NAME" {
  default = "ghcr.io/dotse/bbk"
}

variable "REGISTRY_CACHE" {
  default = "ghcr.io/dotse/bbk-cache"
}

variable "GIT_SHA" {
  default = "local-dev"
}

variable "GITHUB_REPOSITORY" {
  default = "dotse/bbk"
}

variable "BBKCLI_VERSIONS" {
  default = {
    "1.0.0" = {
      version = "1.0"
      extra_tags = ["1.0.0"]
    }
    "1.2.2" = {
      version = "1.2.2"
      extra_tags = ["1", "1.2", "latest"]
    }
  }
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/arm64"]
}

target "build-common" {
  pull = true
}

# Get the arguments for the build
function "get-args" {
  params = [bbkcli_version]
  result = {
    BBKCLI_VERSION = bbkcli_version
  }
}

# Get the cache-from configuration
function "get-cache-from" {
  params = [version]
  result = [
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}",
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("master-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get the cache-to configuration
function "get-cache-to" {
  params = [version]
  result = [
    "type=registry,mode=max,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}",
    "type=registry,mode=max,ref=${REGISTRY_CACHE}:${sha1("master-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get list of image tags and registries
function "get-tags" {
  params = [version, extra_versions]
  result = concat(
    [
      "${IMAGE_NAME}:${version}"
    ],
    flatten([
      for extra_version in extra_versions : [
        "${IMAGE_NAME}:${extra_version}"
      ]
    ])
  )
}

target "regular" {
  inherits = ["build-dockerfile", "build-platforms", "build-common"]
  matrix = {
    version = keys(BBKCLI_VERSIONS)
  }

  name = replace(version, ".", "_")
  args = get-args(BBKCLI_VERSIONS[version].version)
  tags = get-tags(version, BBKCLI_VERSIONS[version].extra_tags)
  cache-from = get-cache-from(version)
  cache-to   = get-cache-to(version)
  labels = {
      "org.opencontainers.image.created"       = "${timestamp()}"
      "org.opencontainers.image.version"       = BBKCLI_VERSIONS[version].version
      "org.opencontainers.image.revision"      = GIT_SHA
      "org.opencontainers.image.source"        = "https://github.com/${GITHUB_REPOSITORY}"
      "org.opencontainers.image.documentation" = "https://github.com/${GITHUB_REPOSITORY}/blob/master/README.md"
    }
}