# 6.S081课程笔记 + Lab详解



## Xv6提供的一些系统调用

| **系统调用**                            | **描述**                                                    |
| --------------------------------------- | ----------------------------------------------------------- |
| `int fork()`                            | 创建一个进程，返回子进程的PID                               |
| `int exit(int status)`                  | 终止当前进程，并将状态报告给wait()函数。无返回              |
| `int wait(int *status)`                 | 等待一个子进程退出; 将退出状态存入*status; 返回子进程PID。  |
| `int kill(int pid)`                     | 终止对应PID的进程，返回0，或返回-1表示错误                  |
| `int getpid()`                          | 返回当前进程的PID                                           |
| `int sleep(int n)`                      | 暂停n个时钟节拍                                             |
| `int exec(char *file, char *argv[])`    | 加载一个文件并使用参数执行它; 只有在出错时才返回            |
| `char *sbrk(int n)`                     | 按n 字节增长进程的内存。返回新内存的开始                    |
| `int open(char *file, int flags)`       | 打开一个文件；flags表示read/write；返回一个fd（文件描述符） |
| `int write(int fd, char *buf, int n)`   | 从buf 写n 个字节到文件描述符fd; 返回n                       |
| `int read(int fd, char *buf, int n)`    | 将n 个字节读入buf；返回读取的字节数；如果文件结束，返回0    |
| `int close(int fd)`                     | 释放打开的文件fd                                            |
| `int dup(int fd)`                       | 返回一个新的文件描述符，指向与fd 相同的文件                 |
| `int pipe(int p[])`                     | 创建一个管道，把read/write文件描述符放在p[0]和p[1]中        |
| `int chdir(char *dir)`                  | 改变当前的工作目录                                          |
| `int mkdir(char *dir)`                  | 创建一个新目录                                              |
| `int mknod(char *file, int, int)`       | 创建一个设备文件                                            |
| `int fstat(int fd, struct stat *st)`    | 将打开文件fd的信息放入*st                                   |
| `int stat(char *file, struct stat *st)` | 将指定名称的文件信息放入*st                                 |
| `int link(char *file1, char *file2)`    | 为文件file1创建另一个名称(file2)                            |
| `int unlink(char *file)`                | 删除一个文件                                                |



## Xv6的内核文件

XV6的源代码位于**kernel/**子目录中，源代码按照模块化的概念划分为多个文件，图2.2列出了这些文件，模块间的接口都被定义在了**def.h**（**kernel/defs.h**）。

| **文件**            | **描述**                                    |
| ------------------- | ------------------------------------------- |
| ***bio.c***         | 文件系统的磁盘块缓存                        |
| ***console.c***     | 连接到用户的键盘和屏幕                      |
| ***entry.S***       | 首次启动指令                                |
| ***exec.c***        | `exec()`系统调用                            |
| ***file.c***        | 文件描述符支持                              |
| ***fs.c***          | 文件系统                                    |
| ***kalloc.c***      | 物理页面分配器                              |
| ***kernelvec.S***   | 处理来自内核的陷入指令以及计时器中断        |
| ***log.c***         | 文件系统日志记录以及崩溃修复                |
| ***main.c***        | 在启动过程中控制其他模块初始化              |
| ***pipe.c***        | 管道                                        |
| ***plic.c***        | RISC-V中断控制器                            |
| ***printf.c***      | 格式化输出到控制台                          |
| ***proc.c***        | 进程和调度                                  |
| ***sleeplock.c***   | Locks that yield the CPU                    |
| ***spinlock.c***    | Locks that don’t yield the CPU.             |
| ***start.c***       | 早期机器模式启动代码                        |
| ***string.c***      | 字符串和字节数组库                          |
| ***swtch.c***       | 线程切换                                    |
| ***syscall.c***     | Dispatch system calls to handling function. |
| ***sysfile.c***     | 文件相关的系统调用                          |
| ***sysproc.c***     | 进程相关的系统调用                          |
| ***trampoline.S***  | 用于在用户和内核之间切换的汇编代码          |
| ***trap.c***        | 对陷入指令和中断进行处理并返回的C代码       |
| ***uart.c***        | 串口控制台设备驱动程序                      |
| ***virtio_disk.c*** | 磁盘设备驱动程序                            |
| ***vm.c***          | 管理页表和地址空间                          |



## Lec01 

### OS目的

- Abstraction
- Multiplex
- Isolation
- Sharing
- Security
- Peformance
- Range of uses

### **Why Hard and Interesting**

- Efficient ---- Abstract
- Powerful ---- Simple （Api）
- Flexible ---- Secure

## Lab1

启动XV6，按照文档执行就ok了。

```shell
$ git clone git://g.csail.mit.edu/xv6-labs-2020
$ cd xv6-labs-2020
$ git checkout util
$ make qemu
```

在XV6中没有ps命令，而是使用Ctrl+p来查看正在运行的进程。

> 另外说一下退出= = 先按 Ctrl + a 然后松开按 X 。。。 这个让我一顿折腾

### sleep

这一个就是仿照已有的程序调用一下sleep的系统调用就行了。

在Unix系统里面，默认情况下`0`代表`stdin`，`1`代表`stdout`，`2`代表`stderr`。这3个文件描述符在进程创建时就已经打开了的（从父进程复制过来的），可以直接使用。而分配文件描述符的时候是从当前未使用的最小的值来分配，因此可以关闭某个文件描述符再通过`open`或`dup`将该文件描述符分配给其他文件或pipe来实现输入输出重定向。

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc < 2){
    fprintf(2, "Usage: sleep [time]\n");
    exit(1);
  }

  int time = atoi(argv[1]);
  sleep(time);
  exit(0);
}
```



### pingpong

这一个实验就是用`pipe`打开两个管道，然后`fork`出一个子进程，完成要求的操作就行了。

`fork`函数是一次调用两次返回的函数，在父进程中返回子进程的pid，在子进程中返回0。

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[]){
    int p2c[2];
    int c2p[2];
    if(pipe(p2c) < 0){
        printf("pipe");
        exit(-1);
    }
    if(pipe(c2p) < 0){
        printf("pipe");
        exit(-1);
    }
    int pid = fork();
    if(pid == 0){
        // child
        char buf[10];
        read(p2c[0], buf, 10);
        printf("%d: received ping\n", getpid());
        write(c2p[1], "o", 2);
    }else if(pid > 0){
        // parent
        write(p2c[1], "p", 2);
        char buf[10];
        read(c2p[0], buf, 10);
        printf("%d: received pong\n", getpid());
    }
    close(p2c[0]);
    close(p2c[1]);
    close(c2p[0]);
    close(c2p[1]);
    exit(0);
}
```



### primes

这一个是实现管道的发明者Doug McIlroy提出的计算素数的方法，该方法类似于筛法，不过是用管道和多线程实现的。在`main`函数中父进程创建了一个管道，输入2~35。之后通过`prime`函数来实现输出，如果读取到了超过两个的数，就创建一个新进程来进行后续处理。

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void prime(int rd){
    int n;
    read(rd, &n, 4);
    printf("prime %d\n", n);
    int created = 0;
    int p[2];
    int num;
    while(read(rd, &num, 4) != 0){
        if(created == 0){
            pipe(p);
            created = 1;
            int pid = fork();
            if(pid == 0){
                close(p[1]);
                prime(p[0]);
                return;
            }else{
                close(p[0]);
            }
        }
        if(num % n != 0){
            write(p[1], &num, 4);
        }
    }
    close(rd);
    close(p[1]);
    wait(0);
}

int
main(int argc, char *argv[]){
    int p[2];
    pipe(p);

    int pid = fork();
    if(pid != 0){
        // first
        close(p[0]);
        for(int i = 2; i <= 35; i++){
            write(p[1], &i, 4);
        }
        close(p[1]);
        wait(0);
    }else{
        close(p[1]);
        prime(p[0]);
        close(p[0]);
    }
    exit(0);
}
```



### find

这一个就是仿照`ls.c`中的方法，对当前目录排除掉`.`和`..`后进行递归遍历，同时对路径名进行匹配，匹配到了就输出。不过库中没有提供`strstr`函数，只能自己写了个O(n2)�(�2)的子串匹配算法。

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

void match(const char* path, const char* name){
    //printf("%s %s", path, name);
    int pp = 0;
    int pa = 0;
    while(path[pp] != 0){
        pa = 0;
        int np = pp;
        while(name[pa] != 0){
            if (name[pa] == path[np]){
                pa++;
                np++;
            }
            else
                break;
        }
        if(name[pa] == 0){
            printf("%s\n", path);
            return;
        }
        pp++;
    }
}

void find(char *path, char *name){
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;

    if((fd = open(path, 0)) < 0){
        fprintf(2, "ls: cannot open %s\n", path);
        return;
    }
    
    if(fstat(fd, &st) < 0){
        fprintf(2, "ls: cannot stat %s\n", path);
        close(fd);
        return;
    }
    switch(st.type){
        case T_FILE:
            // printf("%s %d %d %l\n", path, st.type, st.ino, st.size);
            match(path, name);
            break;

        case T_DIR:
            if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
                printf("ls: path too long\n");
                break;
            }
            strcpy(buf, path);
            p = buf+strlen(buf);
            *p++ = '/';
            while(read(fd, &de, sizeof(de)) == sizeof(de)){
                if(de.inum == 0)
                    continue;
                if(de.name[0] == '.' && de.name[1] == 0) continue;
                if(de.name[0] == '.' && de.name[1] == '.' && de.name[2] == 0) continue;
                memmove(p, de.name, DIRSIZ);
                p[DIRSIZ] = 0;
                if(stat(buf, &st) < 0){
                    printf("ls: cannot stat %s\n", buf);
                    continue;
                }
                find(buf, name);
            }
            break;
    }
    close(fd);
}

int
main(int argc, char *argv[]){
    if (argc < 3){
        printf("Usage: find [path] [filename]\n");
        exit(-1);
    }
    find(argv[1], argv[2]);
    exit(0);
}
```



### xargs

这一个就是从输入中构造出新的argc数组，然后用`fork`和`exec`执行就行了。大部分时间都用在输入的处理上面了。。库里面没有提供`readline`函数和`split`，只能自己写。

```C
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

char* readline() {
    char* buf = malloc(100);
    char* p = buf;
    while(read(0, p, 1) != 0){
        if(*p == '\n' || *p == '\0'){
            *p = '\0';
            return buf;
        }
        p++;
    }
    if(p != buf) return buf;
    free(buf);
    return 0;
}

int
main(int argc, char *argv[]){
    if(argc < 2) {
        printf("Usage: xargs [command]\n");
        exit(-1);
    }
    char* l;
    argv++;
    char* nargv[16];
    char** pna = nargv;
    char** pa = argv;
    while(*pa != 0){
        *pna = *pa;
        pna++;
        pa++;
    }
    while((l = readline()) != 0){
        //printf("%s\n", l);
        char* p = l;
        char* buf = malloc(36);
        char* bh = buf;
        int nargc = argc - 1;
        while(*p != 0){
            if(*p == ' ' && buf != bh){
                *bh = 0;
                nargv[nargc] = buf;
                buf = malloc(36);
                bh = buf;
                nargc++;
            }else{
                *bh = *p;
                bh++;
            }
            p++;
        }
        if(buf != bh){
            nargv[nargc] = buf;
            nargc++;
        }
        nargv[nargc] = 0;
        free(l);
        int pid = fork();
        if(pid == 0){
            // printf("%s %s\n", nargv[0], nargv[1]);
            exec(nargv[0], nargv);
        }else{
            wait(0);
        }
    }
    exit(0);
}
```



## Lab2-syscall



### 系统调用全流程

```C
// 1)在user/user.h做函数声明
user/user.h:		用户态程序调用跳板函数 trace() 							
    
// 2) 在usys.pl 中 加上 entry("XXX") 
// Makefile调用usys.pl（perl脚本）生成usys.S，里面写了具体实现，通过ecall进入kernel，通过设置寄存器a7的值，表明调用哪个system call
user/usys.S:		跳板函数 trace() 使用 CPU 提供的 ecall 指令，调用到内核态 	

// 3) ecall表示一种特殊的trap，转到kernel/syscall.c:syscall执行
kernel/syscall.c	到达内核态统一系统调用处理函数 syscall()，所有系统调用都会跳到这里来处理。 
    
// 4) syscall.c中有个函数指针数组，即一个数组中存放了所有指向system call实现函数的指针，通过寄存器a7的值定位到某个函数指针，通过函数指针调用函数
kernel/syscall.c	syscall() 根据跳板传进来的系统调用编号，查询 syscalls[] 表，找到对应的内核函数并调用。 
    
kernel/sysproc.c	到达 sys_trace() 函数，执行具体内核操作 
```



这么繁琐的调用流程的主要目的是实现用户态和内核态的良好隔离。

并且由于内核与用户进程的页表不同，寄存器也不互通，所以参数无法直接通过 C 语言参数的形式传过来，而是需要使用 **argaddr、argint、argstr** 等系列函数，从进程的 trapframe 中读取用户进程寄存器中的参数。

同时由于页表不同，指针也不能直接互通访问（也就是内核不能直接对用户态传进来的指针进行解引用），而是需要使用 **copyin、copyout** 方法结合进程的页表，才能顺利找到用户态指针（逻辑地址）对应的物理内存地址。（在本 lab 第二个实验会用到）

```C
struct proc *p = myproc(); // 获取调用该 system call 的进程的 proc 结构 copyout(p->pagetable, addr, (char *)&data, sizeof(data));             // 将内核态的 data 变量（常为struct），结合进程的页表，写到进程内存空间内的 addr 地址处。 
```



### tracing

```C
uint64
sys_trace(void)
{
 	int mask;

 	if(argint(0, &mask) < 0)
    	return -1;
	
 	myproc()->syscall_trace = mask;
	return 0;
}

// tracing需要在中枢系统调用那边做修改
// kernel/syscall.c
void
syscall(void)
{
  	int num;
  	struct proc *p = myproc();

  	num = p->trapframe->a7;
  	if(num > 0 && num < NELEM(syscalls) && syscalls[num]) { // 如果系统调用编号有效
    	p->trapframe->a0 = syscalls[num](); 
		// 通过系统调用编号，获取系统调用处理函数的指针，调用并将返回值存到用户进程的 a0 寄存器中
		// 如果当前进程设置了对该编号系统调用的 trace，则打出 pid、系统调用名称和返回值。
    if((p->syscall_trace >> num) & 1) {
      	printf("%d: syscall %s -> %d\n",p->pid, syscall_names[num], p->trapframe->a0); 
        // syscall_names[num]: 从 syscall 编号到 syscall 名的映射表
    }
  	} else {
    	printf("%d %s: unknown sys call %d\n",
            	p->pid, p->name, num);
    	p->trapframe->a0 = -1;
  	}
}
```



### sysinfo

```C++
uint64
sys_sysinfo(void)
{
  // 从用户态读入一个指针，作为存放 sysinfo 结构的缓冲区
  uint64 addr;
  if(argaddr(0, &addr) < 0)
    return -1;
  
  struct sysinfo sinfo;
  sinfo.freemem = count_free_mem(); // kalloc.c
  sinfo.nproc = count_process(); // proc.c
  
  // 使用 copyout，结合当前进程的页表，获得进程传进来的指针（逻辑地址）对应的物理地址
  // 然后将 &sinfo 中的数据复制到该指针所指位置，供用户进程使用。
  if(copyout(myproc()->pagetable, addr, (char *)&sinfo, sizeof(sinfo)) < 0)
    return -1;
  return 0;
}
```

> ps: 这里不在给出每个头文件添加的代码 只给出具体的系统调用代码 因为涉及到多个文件 全部粘贴过来显得很臃肿 想获得提示的可以去看源代码 按照上面写的**系统调用流程**来串联
