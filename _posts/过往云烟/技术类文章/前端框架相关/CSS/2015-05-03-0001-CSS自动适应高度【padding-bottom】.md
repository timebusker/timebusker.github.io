---
layout:     post
title:      CSS自动适应高度【padding-bottom】
date:       2015-05-12
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - CSS
---

> 纯Css实现Div高度根据自适应宽度（百分比）调整

在如今响应式布局的要求下，很多能自动调整尺寸的元素能够做到高宽自适应，如img，通过{width:50%;height:auto;}实现图片高度跟随宽度比例调整。
然而，用的最多的标签一哥Div却不能做到自动调整（要么从父级继承，要么自行指定px，要么给百分比！但是这个百分比是根据父级的高度来计算的，根本不是根据元素自身的宽度，那么就做不到Div的宽高达成一定的比例=-=）。


##### 直接指定div的宽高+zoom来实现自适应

```
div{width:50px;heigth:50px;zoom:1.1;}
```

这样能达到初步的等宽高div，但是局限性太大，PASS！

##### 通过js动态判断div的宽度来设置高度

```
div{width:50%;}
window.onresize = function(){div.height(div.width);}
```

也能实现等宽高div，但是总觉得有点别扭，PASS！

##### 通过宽高单位来设置

```
div{width:20vw;height:20vw;/*20vw为viewport width的20%*/}
```

但是很多设备不支持这个属性，兼容性太差，PASS！

##### 通过float来设置

```
#aa{background:#aaa;;}
#bb{background:#ddd;;float:left} 
#cc{background:#eee;;float:right}

<div id="aa">父div 
　　<div id="bb">子div</div> 
　　<div id="cc">子div</div> 
　　<div style="clear:both">就是这个用于clear错误的</div>
</div>
```

能够让父级元素aa根据子元素的高度自动改变高度（在子元素里放置自适应元素）来调整高宽比一致，然而太麻烦，PASS！

##### 通过padding来实现此功能(推荐)

通过以上几个方案的实验，发现宽度的自适应是根据viewport的width来调整的，比如{width：50%}就是浏览器可视区域的50%，resize之后也会自动调整。
而height指定百分比后，他会自行找到viewport的height来调整，跟width一毛钱关系没有，自然两者不能达到比例关系了。通过这个思路，要找到一个能跟viewport的width扯上裙带关系的属性，就能解决这个问题了。
这个属性就是padding，padding是根据viewport的width来调整的，巧就巧在padding-top和padding-bottom也是根据viewport的width来计算的，那么通过设置这个属性就能跟width达成某种比例关系了，
我们首先指定元素的width为父级元素的50%（父级元素为任意有高宽的元素，不能指定特定父级元素，否则影响此方案的通用性）。

```
.father{width:100px;height:100px;background:#222}
.element{width:50%;background:#eee;}
```

这个时候我们再设置element的height为0，`padding-bottom:50%;`

```
.element{width:50%;height:0;padding-bottom:50%;background:#eee;}
```

element就变成了一个宽度50%，高度为0（但是他有50%width的padding-bottom）的正方形了，效果如下图灰白色的div

![image](img/older/css/css-padding.jpg)  

这个时候可能有人要问了，这个div的高度为0，那如果我要在element里放置元素呢，那岂不是overflow了，这里就要提到overflow属性了，它的计算是包括div的content和padding的，也就是说，
原来你的div可能是个{width：50px;height:50px;padding:0}的div，现在变成{width:50px;height:0;padding-bottom:50px;}的div了，尺寸还是一样的，通过指定这个div的子元素的定位，一样可以正常显示

![image](img/older/css/css-padding1.jpg)  

#### 参考
[【文章】](http://zihua.li/2013/12/keep-height-relevant-to-width-using-css/)