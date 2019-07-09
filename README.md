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
	
	
（5）mutex和condition

mutex

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
	
condiotion

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
生产者消费者里面存放资源使用的缓冲

知识点：
	对于无界缓冲
	利用deque来存储数据，模拟无界
	只有一个notEmpty条件变量，无需notfull条件变量，因为是无界的
	
	对于有界缓冲
	可以考虑用环形缓冲区防止拷贝，但是实际中没有使用，而是直接使用了boost的circular_buff
	利用circular_buff来存储数据，模拟有界
	需要两个条件变量来判断满了和空了


（7）ThreadPool实现

目的：
实现线程池的生产者消费者模型

知识点：
	是一个固定的线程池(由传入线程数为准)，run为向任务队列加任务，runInThread为线程队列执行的函数
	typedef boost::function<void ()> Task; 定义了一个类类型
	

（8）线程安全的Singleton

目的：
实现线程安全的单例模式类

知识点：
	保证线程安全的做法：
	pthread_once：保证一个函数只被执行一次，无锁情况保证线程安全，保证了只生成一个对象
	atexit：注册函数，程序（线程）结束时执行，在这里注册对象销毁
	typedef char T_must_be_complete_type[sizeof(T) == 0 ? -1 : 1]; 定义了一个数组类型，表示销毁的对象类型必须是
	一个complete_type，保证编译期就对不正确的类型报错。因为如果是不完全类型会导致数组的下标为-1

	
	incomplete_type：比如只声明没有定义的类，当定义他的指针，编译不会报错，利用上面的方式使得编译时这种类型时报错
	
（9） ThreadLocal<T>类

目的：
实现线程私有数据

知识点：

为什么需要线程特定数据
	在单线程程序中，我们经常要用到"全局变量"以实现多个函数间共享数据。
	在多线程环境下，由于数据空间是共享的，因此全局变量也为所有线程所共有。 
	但有时应用程序设计中有必要提供线程私有的全局变量，仅在某个线程中有效，但却可以跨多个函数访问。
	POSIX线程库通过维护一定的数据结构来解决这个问题，这个些数据称为（Thread-specific Data，或 TSD）。
	线程特定数据也称为线程本地存储TLS（Thread-local storage）
	对于POD类型的线程本地存储，可以用__thread关键字
	
	
POSIX对于TSD的封装实现（通过四个函数）

	创建key（所有线程共享）
	销毁key（所有线程销毁）
	获取线程某个指针对应的私有数据的地址（即指针值）
	设置线程某个指针对应的私有数据的地址（即指针值）
	
	一旦一个线程创建了一个key,那么所有线程都会有这个key，但是不同线程这个key指向的数据不同（堆上的），
	若要删除数据，可以在第一个函数里面设定回调来销毁堆上的数据（指针被销毁前调用）
	
	
在main线程中调用pthread_exit会起到只让main线程退出，但是保留进程资源，供其他由main创建的线程使用，直至所有线程都结束，
但在其他线程中不会有这种效果


SingletonThreadLocal（整个程序只有一个单例对象,每个线程里面的test是单独拥有）：

作用：
演示单例和singleton的结合使用（Threadlocal类里面的Test是单例的数据类型，只有一个Threadlocal类型的单例对象，
但是每个线程的Test数据有多份）


	#define STL muduo::Singleton<muduo::ThreadLocal<Test> >::instance().value()
	
	为了说明muduo::ThreadLocal<Test>只有一个单例对象，而每个线程依旧有自己的Test
	

（10） ThreadLocalSingleton<T>封装

作用：
每一个线程都一个T类的单例对象，区别SingletonThreadLocal类（实现功能一样（都是特有的TEST类，但是后者使用单例对象类来管理
），但是这一个更加自然）

知识点：
	Deleter（保存共有的指针，用于销毁所指向的线程特有的单例对象（功能和单例类的atexit一样），销毁时自动调用注册的对象销毁函数，无需自己去销毁
	）是ThreadLocalSingleton的一个嵌套类，用TSD实现，所以该类用了两种方式实现TLS（__thread和TSD）


(11) 日志的作用、级别、使用时序
作用：
	开发过程中：
	调试错误
	更好的理解程序
	运行过程中：
	诊断系统故障并处理
	记录系统运行状态
	
	Linux程序员很少使用gdb找错误，一般使用日志，编译运行还可以，逻辑错误还用gdb的话如大海捞针
	
日志级别
	TRACE
	指出比DEBUG粒度更细的一些信息事件（开发过程中使用）
	DEBUG
	指出细粒度信息事件对调试应用程序是非常有帮助的。（开发过程中使用）
	INFO
	表明消息在粗粒度级别上突出强调应用程序的运行过程。
	WARN
	系统能正常运行，但可能会出现潜在错误的情形。
	ERROR
	指出虽然发生错误事件，但仍然不影响系统的继续运行。
	FATAL
	指出每个严重的错误事件将会导致应用程序的退出。
	
	从上往下级别增大
	muduo日志级别默认INFO，低于该级别的不会输出
	
	LOG_ERROR 应用级别的错误，LOG_SYSERR 系统级别（会根据errno来判断）的错误 但两者日志级别都是ERROR
	
	输出样例：muduo::Logger(__FILE__（文件名）, __LINE__（行号）, muduo::Logger::TRACE（级别）, __func__（当前函数）)
	
	通过setoutput选择输出到特定的文件

使用时序

	Logger外层类，Impl为嵌套的实际的实现（格式化日志），借助LogStream输出，先输出到FixedBuffer缓冲区，然后通过g_output输出到文件或者标准输出的缓冲里（Log类的析构函数里实现），通过g_flush将对应缓冲输出到文件或设备(标准输入输出是行缓冲，文件是全缓冲，运行过程中无需flush,只有当出错时才需要flush)
	
	fopen文件的a选项表示追加，e选项exec函数不会被继承该文件指针


(12) 	Logger类和LogStream类封装

作用：
封装日志类

知识点：
	SIZE为非类型参数，直接传递值就行
	is_arithmetic：算术类型
	std::numeric_limits<int16_t>::min() 基值
	#pragma GCC diagnostic ignored "-Wold-style-cast" 当前忽略掉警告
	
	经测试，Logstream写缓存性能居中，对比ssprintf和streamstream

		StringPiece类：谷歌提供的，用于实现高效的字符串传递，避免了拷贝，因为是用指针（传入类型是各种，无需强制转换）
	通过宏来实现更多的运算符（还需要辅助的运算符）


		__type_traits：类型特性，利用模板的特化，实现更高的运行效率（每个类定义一些特征，模板程序中判断是否有这些特性，
	然后按着这些特征更好地编程）

(13) Logfile类的封装

作用：
实现日志滚动

知识点：
	日志滚动条件
	文件大小（例如每写满1G换下一个文件）
	时间（每天零点新建一个日志文件，不论前一个文件是否写满）
	
	一个典型的日志文件名
	logfile_test.20130411-115604.popo.7743.log

	UTC时间和GMT时间是一样的，北京时间为UTC+8
	
	basename：basename的作用是从文件名中去除目录和后缀

	多个线程对同一文件写入，效率可能不如单个线程，因为IO总线不能运行
	如果一定要多个线程写入，采用异步线程（之后会讲到）

	FILE类不是线程安全的，因为是无锁写入（提高效率）。通过LogFile类保证了线程安全
	startOfPeriod每次都会调整为零点，所以只有第二天才会有差异，当天时间调整后都为零点
	使用_r后缀的函数获取时间，保证线程安全（通过传出参数而不是返回指向一块可能被其他线程更改的缓冲区的时间）
	
	
FileUtil空间：SmallFile类应用读取小文件
	读到字符串（大小无限制）或者自己的缓冲区（大小有限制）
	pread：设置偏移读取
	cmdline就会打出本条命令
	
	pread可以从指定的偏移位置来读取文件
	
	scoped_ptr是一个类似于auto_ptr的智能指针，它包装了new操作符在堆上分配的动态对象，能够保证动态创建的对象在任何时候都可以被正确的删除。但是scoped_ptr的所有权更加严格，不能转让，一旦scoped_pstr获取了对象的管理权，你就无法再从它那里取回来。
	
	和unique_ptr的区别
	scoped_ptr是一个类似于auto_ptr的智能指针，它包装了new操作符在堆上分配的动态对象，能够保证动态创建的对象在任何时候都可以被正确的删除。但是scoped_ptr的所有权更加严格，不能转让，一旦scoped_pstr获取了对象的管理权，你就无法再从它那里取回来。 unique_ptr 独占所指向的对象, 同一时刻只能有一个 unique_ptr 指向给定对象(通过禁止拷贝语义, 只有移动语义来实现), 定义于 memory (非memory.h)中, 命名空间为 std



Part2: muduo_net 部分的实现

为什么需要网络库？
	Socket ApI不够完善，所以需要提供更改层次的封装，来降低开发难度
	
TCP网络编程本质
	TCP网络编程最本质是的处理三个半事件
	连接建立：服务器accept（被动）接受连接，客户端connect（主动）发起连接
	
	连接断开：主动断开（close、shutdown），被动断开（read返回0）
	
	消息到达：文件描述符可读（将数据从内核缓冲区移动到应用缓冲区，网络库回调注册的OnMessage检查是不是完整的包，若不是直接返回，继续循环读入缓存，若是，则应用层调用read把数据读取进行处理）
	
	消息发送完毕：这算半个。对于低流量的服务，可不必关心这个事件;这里的发送完毕是指数据写入操作系统缓冲区，将由TCP协议栈负责数据的发送与重传，不代表对方已经接收到数据。（必须把全部数据发送到内核缓冲区，若空间不够先放在应用缓冲区，若够了，内核发送发送完成事件，网络库调用OnWriteComplete函数才可以再次发送数据，以免丢包，所以适用于高流量服务）



(1) 什么都不做的EventLoop
	one loop 	per thread意思是说每个线程最多只能有一个EventLoop对象。若没有，就是非IO线程，可能是计算线程
	EventLoop对象构造的时候，会检查当前线程是否已经创建了其他EventLoop对象，如果已创建，终止程序（LOG_FATAL）
	EventLoop构造函数会记住本对象所属线程（threadId_）。
	创建了EventLoop对象的线程称为IO线程，其功能是运行事件循环（EventLoop::loop）
	
	loop只能在创建该对象的线程中被调用，会判断线程，若不是，直接退出
	
(2) Channel封装

作用：
负责注册和响应IO事件

知识点：
	它不拥有file descriptor。
	Channel是Acceptor、Connector、EventLoop（特有的那个CH）、TimerQueue、TcpConnection的成员，生命期由后者控制。
	POLLPRI：紧急事件，比如TCP带外数据
	POLLNVAL：文件描述符没有打开，或者非法fd
	POLLHUP:挂起，只在写时候出现
	POLLRDHUP:对等方关闭连接事件
	
	从poll移除关注时一定要先update为不关注事件才可以移除
	
	读回调需要一个时间戳
	
（3）定时器的选择

作用：
	定时函数，用于让程序等待一段时间或安排计划任务
	让eventloop能够处理定时器事件

知识点：
函数选择
	timerfd_* 入选的原因：
	1.sleep / alarm / usleep 在实现时有可能用了信号 SIGALRM，在多线程程序中处理信号是个相当麻烦的事情，应当尽量避免
	2.nanosleep 和 clock_nanosleep 是线程安全的，但是在非阻塞网络编程中，绝对不能用让线程挂起的方式来等待一段时间，程序会失去响应。正确的做法是注册一个时间回调函数。 
	3.getitimer 和 timer_create 也是用信号来 deliver 超时，在多线程程序中也会有麻烦。
	4.timer_create 可以指定信号的接收方是进程还是线程，算是一个进步，不过在信号处理函数(signal handler)能做的事情实在很受限。 
	5.timerfd_create 把时间变成了一个文件描述符，该“文件”在定时器超时的那一刻变得可读，这样就能很方便地融入到 select/poll 框架中，用统一的方式来处理 IO 事件和超时事件，这也正是 Reactor 模式的长处。
	
	
	多线程避免用信号
	
	若非要用信号处理，也可以用signalfd将信号转为文件描述符来处理
	
	muduo的定时器也是一次性定时，间隔性的需要多次注册（其实可以通过设置new_value的第一个参数实现间隔定时）
	
	若设置了水平触发，数据不读走的话会一直触发EPOLL（默认是EPOLL模式且为水平触发）
	
	quit函数可以跨线程调用，因为如果是其他线程，可能poll会阻塞，需要唤醒（通过添加监听管道fd，或者用eventfd）才能走到while判断
	
	bool类型quit操作本来就是原子性，所以不需要保护



	



Part3: muduo库使用示例

Part4: 基于muduo库的ABC_Bank

