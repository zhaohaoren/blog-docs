#!/bin/bash
if [ -n "$1" ]; then
	echo "正在创建$1.md及图片文件夹";
	touch "docs/$1.md";
	mkdir "docs/$1";
else
    echo "请输入文件名"
fi