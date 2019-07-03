# MyMuduo
从0到1实现muduo网络库

Part1: muduo_base 部分的实现

(1)Timestamp

功能：时间戳类

继承less_than_comparable<Timestamp>，只需实现<，其他自动实现，模板元思想
copyable：空基类，是一个标识类，继承此类表示是值类型，可以拷贝
类的内部可以访问对象的私有成员
PRId64实现了可移植打印（32位和64位统一化）需要先定义#define __STDC_FORMAT_MACROS才能使用
BOOST_STATIC_ASSERT：编译时断言

（2）AtomicIntegerT

功能：原子操作类



Part2: muduo_net 部分的实现

Part3: muduo库使用示例

Part4: 基于muduo库的ABC_Bank

