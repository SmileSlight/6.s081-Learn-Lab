#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// 一次 sieve 调用是一个筛子阶段，会从 pleft 获取并输出一个素数 p，筛除 p 的所有倍数
// 同时创建下一 stage 的进程以及相应输入管道 pright，然后将剩下的数传到下一 stage 处理
void 
sieve(int pleft[2]) {
	int p;
        read(pleft[0], &p, sizeof(p));
        if(p == -1) {
                exit(0);
        }
        printf("prime %d\n", p);

        int pright[2];
        pipe(pright);

        if(fork() == 0) {
                close(pright[1]);
                close(pleft[0]);
                sieve(pright);
        }
        else {
                close(pright[0]);
                int buf;
                while(read(pleft[0], &buf, sizeof(buf)) && buf != -1) {
                        if(buf % p != 0) {
                                write(pright[1], &buf, sizeof(buf));
                        }
                }
                buf = -1;
                write(pright[1], &buf, sizeof(buf));
		wait(0);
		exit(0);
        }
}        

int 
main(int argc, char **argv) {
	int insight_pipe[2];
        pipe(insight_pipe);
        if(fork() == 0) {
                close(insight_pipe[1]);
                sieve(insight_pipe);
                exit(0);
        }
        else {
                close(insight_pipe[0]);
                int i;
                for(i = 2 ; i <= 35 ; i++) {
                        write(insight_pipe[1], &i, sizeof(i));
                }
                i = -1;
                write(insight_pipe[1], &i, sizeof(i));
        }
        wait(0);
        exit(0);
}