#!/bin/bash

# Set the default value
dir=${1:-obj1}

mkdir -p data/$dir/color
/bin/ffmpeg -i data/$dir/video.mp4 -vf zscale=p=bt709:t=bt709:m=bt709:r=tv,unsharp,format=yuv420p data/$dir/color/%03d.png