---
layout:     post
title:      关于try-catch-finally的测试总结
date:       2018-05-04
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - JAVA杂记
---

#### 测试代码

```
package com.teligen.importance.suspect;

public class TryCatchFinallyTest {

    public static int resInt() {
        int k = 10;
        try {
            // finally 一直会被执行，但是整形变量return返回值在finally之前执行
            // int属于基本数据类型，返回结果会被直接写在执行栈内存中，故而导致finally中的赋值不再有效
            return k;
        } catch (Exception e) {
            e.getMessage();
        } finally {
            k = 20;
            System.out.println("FINALLY------\t" + k);
        }
        return k;
    }

    public static String resString() {
        String k = "A";
        try {
            // finally 一直会被执行，但是String变量return返回值在finally之前执行
            // String属于基本数据类型，返回结果会被直接写在执行栈内存中，故而导致finally中的赋值不再有效
            return k;
        } catch (Exception e) {
            e.getMessage();
        } finally {
            k = "B";
            System.out.println("FINALLY------\t" + k);
        }
        return k;
    }

    public static StringBuilder resObject() {
        StringBuilder stb = new StringBuilder();
        try {
            // finally 一直会被执行，但是类类型变量return返回值在finally之前执行
            // StringBuilder为类类型变量，执行栈中存在指针地址信息，指向堆内存地址，
            // 返回结果的指针会被直接写在执行栈内存中，故而导致finally中的赋值是有效
            return stb.append("A");
        } catch (Exception e) {
            e.getMessage();
        } finally {
            stb.append("A");
            System.out.println("FINALLY------\t" + stb.toString());
        }
        return stb;
    }

    public static void main(String[] args) {
        // finally代码块一直会被执行
        System.out.println(resInt());
        System.out.println(resString());
        System.out.println(resObject().toString());
        // 代码进栈顺序：System.out.println ==》 return ==》 finally ==》 打印输出
    }
}
```

#### 总结
- `finally`代码块一直会被执行，只要线程仍然可运行。
- `return`返回值存在两种情况
   + 返回基本数据类型：返回值会直接写在占内存中，获取返回值时直接在占内存通过变量名称匹配即可获取数据值
   + 返回类类型：返回值是一个地址指针，指针信息被直接写在栈内存中，获取返回值时类类型变量通过指针在堆内存中获取数据值
- 测试代码进栈的逻辑顺序是：**System.out.println ==》 return ==》 finally**，实际执行顺序反之