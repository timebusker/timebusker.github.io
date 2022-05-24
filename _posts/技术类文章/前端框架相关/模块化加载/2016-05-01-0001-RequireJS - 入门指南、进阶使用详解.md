---
layout:     post
title:      RequireJS - 入门指南、进阶使用详解
date:       2018-12-23
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - RequireJS
---

> 现在项目大都使用模块化开发，而 RequireJS 作为 AMD 模块开发的典范，还是很值得学习使用的。

### AMD 规范
#### AMD 基本介绍
- **AMD** 全称为 Asynchromous Module Definition（异步模块定义） 
- **AMD** 是 RequireJS 在推广过程中对模块定义的规范化产出，它是一个在浏览器端模块化开发的规范。
- **AMD** 模式可以用于浏览器环境并且允许非同步加载模块，同时又能**保证正确的顺序**，也可以**按需动态加载模块**。

#### AMD 模块规范
- **AMD** 通过异步加载模块。模块加载不影响后面语句的运行。所有依赖某些模块的语句均放置在回调函数中。
- **AMD** 规范只定义了一个函数 define，通过 define 方法定义模块。该函数的描述如下：

```
define(id?, dependencies?, factory)

# id：指定义中模块的名字（可选）。如果没有提供该参数，模块的名字应该默认为模块加载器请求的指定脚本的名字。如果提供了该参数，模块名必须是“顶级”的和绝对的（不允许相对名字）。
# dependencies：当前模块依赖的，已被模块定义的模块标识的数组字面量（可选）。
# factory：一个需要进行实例化的函数或者一个对象。
```

- AMD 规范允许输出模块兼容 CommonJS 规范，这时 define 方法如下：

```
define(function (require, exports, module) {
    var reqModule = require("./someModule");
    requModule.test();
      
    exports.asplode = function () {
        //someing
    }
});
```

### RequireJS 介绍 
#### 什么是 RequireJS
`RequireJS`是一个`JavaScript`模块加载器。它非常适合在浏览器中使用，但它也可以用在其他脚本环境, 比如`Rhino`和`Node`。
使用`RequireJS`加载模块化脚本将提高代码的加载速度和质量。

#### 使用 RequireJS 的好处
- **异步“加载”**。使用`RequireJS`，会在相关的`js`加载后执行回调函数，这个过程是异步的，所以它不会阻塞页面。
- **按需加载**。通过`RequireJS`，你可以在需要加载`js`逻辑的时候再加载对应的`js`模块，不需要的模块就不加载，这样避免了在初始化网页的时候发生大量的请求和数据传输。
- **更加方便的模块依赖管理**。通过`RequireJS`的机制，你能确保在所有的依赖模块都加载以后再执行相关的文件，所以可以起到依赖管理的作用。
- **更加高效的版本管理**。比如原来我们使用的`script`脚本引入的方式来引入一个`jQuery2.x`的文件，但如果有`100`个页面都是这么引用的，如果想换成`jQuery3.x`，那你就不得不去改这`100`个页面。而使用`requireJS`只需要改一处地方，即修改`config`中`jQuery`的`path`映射即可。
- 当然还有一些诸如`cdn`加载不到`js`文件，可以请求本地文件等其它的优点，这里就不一一列举了。

### RequireJS 的配置和使用
#### 下载最新版的 require.js
下载地址：[GitHub地址](https://github.com/requirejs/requirejs/releases)

#### [RequireJS - 入门指南、进阶使用详解（附样例）](http://www.hangge.com/blog/cache/detail_1702.html)

#### [RequireJS - 使用 r.js 实现模块、项目的压缩合并（压缩js、css文件）](http://www.hangge.com/blog/cache/detail_1704.html)

#### [JS - CommonJS、ES2015、AMD、CMD模块规范对比与介绍（附样例）](http://www.hangge.com/blog/cache/detail_1686.html)

#### [官网API](https://requirejs.org/docs/api.html)