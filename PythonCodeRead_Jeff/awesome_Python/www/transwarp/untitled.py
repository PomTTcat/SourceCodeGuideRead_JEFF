# -*- coding: utf-8 -*-

'''

目标，传入数据库地址之后。
以后的语句操作都直接操作curous
db封装类

数据库地址相当于全局变量

db.create_db()
db.select
db.with.... 可以执行多句操作
db.connect() ?
db.事件



'''

print '-------__enter__ & __exit__-------'


class VOW(object):

    def __init__(self, text):
        print '__init__ now'
        self.text = text

    def init():
        print 'init now'

    def __enter__(self):
        self.text = "I say: " + self.text    # add prefix
        return self                          # note: return an object

    def __exit__(self, exc_type, exc_value, traceback):
        self.text = self.text + "!"          # add suffix


with VOW("I'm fine") as myvow:
    print(myvow.text)

print(myvow.text)
