# MyMuduo
从0到1实现muduo网络库

Part1: muduo_base 部分的实现

(1)Timestamp

功能：
时间戳类


知识点：

继承less_than_comparable<Timestamp>，只需实现<，其他自动实现，模板元思想
copyable：空基类，是一个标识类，继承此类表示是值类型，可以拷贝
类的内部可以访问对象的私有成员
PRId64实现了可移植打印（32位和64位统一化）需要先定义#define __STDC_FORMAT_MACROS才能使用
BOOST_STATIC_ASSERT：编译时断言

（2）AtomicIntegerT

功能：
原子操作类

知识点：

为什么要使用原子操作
	避免加锁操作（加锁消耗太大），操作系统提供了一系列原子操作，使用这些原子性操作，编译的时候需要加-march=cpu-type（直接写native）
	cmake中加-march=native

	
	CAS（Compare And Swap）
	
volatile的作用
	作为指令关键字，确保本条指令不会因编译器的优化而省略，且要求每次直接读值。简单地说就是防止编译器对代码进行优化
	当要求使用volatile 声明的变量的值的时候，系统总是重新从它所在的内存读取数据，而不是使用保存在寄存器中的备份。即使它前面的指令刚刚
	从该处读取过数据。而且读取的数据立刻被保存
	用于多线程操作，因为可能内存中的数据被其他线程修改了，若优化后从寄存器取值就不对了，所以要避免优化


（3）Types.h

功能：
定义有一个向下转型以及隐式转换的模板函数

知识点：

__gnu_cxx::__sso_string：
sso如果字符串长度超过15就会在堆上分配内存（否则在栈上），无论长短字符都是深拷贝
std::string类型的C字符都是在堆上，地址相同，修改时才会换地址（写时复制）

（4）Exception

功能：
异常类的封装

知识点：

backtrace，栈回溯，保存各个栈帧的地址
backtrace_symbols，根据地址，转成相应的函数符号
利用 abi::__cxa_demangle名字还原而不是使用C++改名的

（5）Thread

功能：
线程类的封装

知识点：

线程标识符：
	pthread_self（获得的是线程库的线程号，全局不唯一pthread_t）
	gettid（由于线程也是由进程实现的，该函数获得全局唯一线程号tid）但glibc并没有实现该函数，只能通过Linux的系统调用syscall来获取。
	
__thread关键字：
	gcc内置的线程局部存储设施，每个线程都会有一份，如果不加这个修饰，则是共享的
	__thread只能修饰POD类型
	POD类型（plain old data），与C兼容的原始数据，例如，结构和整型等C语言中的类型是 POD 类型，但带有用户定义的构造函数或虚函数的类
	则不是
	
	如果是非POD类型也想线程局部存储，可以使用封装tsd（线程特定数据）
	
boost::is_same：判断两个是否是同一类型
	
pthread_atfork：int pthread_atfork(void (*prepare)(void), void (*parent)(void), void (*child)(void));
	调用fork时，内部创建子进程前在父进程中会调用prepare，内部创建子进程成功后，父进程会调用parent ，子进程会调用child
	使用原因 因为fork可能在子线程中被调用，那么fork得到一个新进程，只有一个执行序列，只有一个线程（调用fork的线程被继承下来）所以需要
	改变名字为main（之前是线程的名字，这个新线程是这个子进程的主线程，所以要改为main）
	
	实际上，多线程最好不要混合多进程，混用容易产生死锁等问题
	父进程在创建子进程的时候，只会复制当前线程的状态，其他的线程不会复制（因此之前的子线程锁住了条件，再fork继承了死锁状态又加锁，从而
	死锁，因为子线程没有可以解锁的线程了）利用pthread_atfork可以防止这种死锁的发生，通过fork前解锁（具体看代码）父进程中再加锁
	
	
一些技巧：
	通过缓存tid，来防止每次都需要系统调用
	加上（void），防止变量在release状态未使用而报错，因为assert语句只有debug模式会执行
	
	
（5）mutex

功能：
互斥锁的封装

知识点：
	RAII：资源获取即初始化，且无需自己释放
	
	MutexLockGuard类（采用RAII思想）更为常用，MutexLock 存在死锁风险（提前退出而没有解锁），而MutexLockGuard会自动调用构造析构
	
		两者关系：
	第二个类并不拥有mutex，不管理其生存期，因为是引用类型，所以这俩个类只是关联关系，没有存在聚合（整理与局部）关系 ，如果还负责对
	象的销毁，称之为组合关系
	
	第二个类不允许构造匿名对象，因为临时对象不能长时间拥有锁
	
		
	技巧：通过定义匿名对象宏来报错
	
(5) condiotion

功能：
封装条件变量

知识点：
	CountDownLatch类是对条件变量的封装类：倒计时，到0唤醒，包含一个condition类一个mutex类
	既可以用于所有子线程等待主线程发起 “起跑” 
	也可以用于主线程等待子线程初始化完毕才开始工作
	等待wait要放在while循环里面，而不能用if来判断资源有无，否则会有假唤醒
	
	技巧：
	利用mutable修饰在常量函数里面改变成员变量
	
	ptr_vector可以自动销毁指针对象指向的成员

(6) 无界缓冲BlockinngQueue和有界缓冲BoundedBlockingQueue

功能：
生产者消费者里面存放资源的缓冲

知识点：
	对于无界缓冲
	利用deque来存储数据，模拟无界
	只有一个notEmpty条件变量，无需notfull条件变量，因为是无界的
	
	对于有界缓冲
	可以考虑用环形缓冲区防止拷贝，但是实际中没有使用，而是直接使用了boost的circular_buff
	利用circular_buff来存储数据，模拟有界
	需要两个条件变量来判断满了和空了


（7）


Part2: muduo_net 部分的实现

Part3: muduo库使用示例

Part4: 基于muduo库的ABC_Bank

