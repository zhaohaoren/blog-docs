# xx



## 环境配置

环境依赖

- Node.js (Node.js 版本需不低于 10.13，建议使用 Node.js 12.0 及以上版本)
- Git

初始化工作环境

- 安装hexo

  ```shell
  npm install -g hexo-cli
  ```

- 初始化工作目录

  ```shell
  hexo init <folder>
  cd <folder>
  npm install
  ```

这步完成后，目录大致如下：

```
.
├── _config.yml //网站的配置信息，配置网站的基本信息
├── package.json //应用程序的信息 相当于依赖吧
├── scaffolds //模版文件夹，hexo new 文章的时候，会按照这里模板来生成模板文件
├── source //存放用户资源
|   ├── _drafts
|   └── _posts //你的文章
└── themes //主题文件夹
```



## 切换主题

只需要在`themes`文件夹下新增自己指定名称的文件夹，然后修改 `_config.yml` 配置文件的`theme`设定。

Hexo主题是一个独立的项目，有自己独立的 `_config.yml` 配置文件。

如果配置了多个主题：Hexo 在合并主题配置时，Hexo 配置文件（ _config.yml）中的 `theme_config` 的优先级最高，其次是 `_config.[theme].yml` 文件，最后是位于主题目录下的 `_config.yml` 文件。



如果启动有异常，使用检查`package.json`的配置，是否缺少依赖，加上后在npm install下





支持latex

https://www.dazhuanlan.com/2019/12/18/5df9d7ce4d340/ 这是一般的，如果主题的提供这已经给我们支持了latex就可以直接直接配置。

如果主题提供者没有接入latex支持，需要我们自己配配置

https://adores.cc/posts/62947.html 首先要看你的模板引擎是啥，一般的是ejs，也有少部分的是pug。 

这些模板引擎就是layout的部分，他们定义了网站的基本格式，结构。模样，然后通过样式和js对其美化，

我这里就是用pug，上面博客是ejs。这时候你可能和我一样也不会js这些东西，可以去github搜索，有人实现的。

我找到：https://github.com/7ye/maupassant-hexo/search?q=mathjax

结合上面那个博客就可以自己去支持很多东西进去了





**一直参考这个人写的东西就好了，https://github.com/smallyunet/hexo-blog/blob/master/_config.yml**

自己开发hexo主题

https://www.cnblogs.com/yyhh/p/11058985.html