# -*- coding: utf-8 -*-
# @Author: HUAWEI
# @Date:   2022-04-24 20:37:53
# @Last Modified by:   HUAWEI
# @Last Modified time: 2022-06-02 17:55:42

import os
import random
path='E:\\timebusker\\timebusker.github.io\\img\\top-photo'       
#获取该目录下所有文件，存入列表中
lists=os.listdir(path)
for file in lists:
    if file.endswith('.jpg'):
        print(file)
        old=path+ os.sep + file
        new=path+ os.sep + str(random.randint(0,999)) + file
        os.rename(old,new)

lists=os.listdir(path)
n=1
for file in lists:
    if file.endswith('.jpg'):
        print(file)
        old=path+ os.sep + file
        new=path+ os.sep + str(n) + '.jpg'
        os.rename(old,new)
        n+=1
