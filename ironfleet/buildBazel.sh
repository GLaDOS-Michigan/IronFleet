#!/bin/bash

cd ./tools/NuBuild
bazel build --spawn_strategy=standalone //NuBuild:NuBuild
cd -
