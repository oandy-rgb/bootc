set dotenv-filename := "image-template.env"
set dotenv-load

image_name := env_var("IMAGE_NAME")
default_tag := env_var("DEFAULT_TAG")
base_image := env_var("BASE_IMAGE")

default:
    @just --list

build:
    podman build --pull=always --build-arg BASE_IMAGE="{{ base_image }}" -t "localhost/{{ image_name }}:{{ default_tag }}" .

switch:
    sudo bootc switch --transport containers-storage "localhost/{{ image_name }}:{{ default_tag }}"

build-and-switch:
    just build
    just switch

check:
    just --fmt --check
    bash -n build_files/build.sh
