#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// test for procinfo system call
int main(int argc,char *argv[]){
	int n = 0;

	if (argc >= 2){
		n= atoi(argv[1]);
	}
	if(n==1||n==2||n==3){	
		printf("Proc Info(%d)\n",n);
	}

    for (int i = 0; i < 10; i++) {
        procinfo(n);
    }
	exit(0);
}
