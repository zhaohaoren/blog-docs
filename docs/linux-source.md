---
title: Linux中的source命令和直接执行脚本的区别
date: 2020-05-10 01:43:41
tags:
---

source 以及 . 直接在当前的进程中读取脚本的配置，不会开一个新的进程！ source会将脚本的内容直接影响到父进程的（因为它不开辟新线程，可以说是直接在当前进程中加入脚本的执行内容）。所以你source之后，里面配置的变量都会加入到当前环境中，你可以在该shell中调用脚本中的变量！

而./xx.sh 以及 sh xx.sh 是在当前进程下新开一个子shell进程运行这个脚本，当脚本运行完毕了，sh中设置的变量和子进程一起被销毁了！（该子shell继承了父进程的shell的环境变量，子shell结束了变量将被销毁，如果使用了export可以将子shell的变量反馈到父级别的shell中）

