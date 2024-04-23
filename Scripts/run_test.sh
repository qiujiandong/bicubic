#!/bin/bash

if [[ ! -f ../build/bicubic ]]
then
    echo "bicubic not found, Please build first"
fi

echo "Start process single image ..."
./../build/bicubic -f ./test/test_0.bmp -o ./result/result_0.bmp

echo "Start process single image in parallel ..."
./../build/bicubic -f ./test/test_0.bmp -o ./result/result_0.bmp -p

echo "Start process images ..."
./../build/bicubic -src ./test -dst ./result

echo "Start process images in parallel ..."
./../build/bicubic -src ./test -dst ./result -p
