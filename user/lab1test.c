#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc,char *argv[]){
	int n = 0;

	if (argc >= 2){
		n= atoi(argv[1]);
	}
	if(n==1||n==2||n==3){	
		printf("info(%d)\n",n);
	}
	sysinfo(n);
	exit(0);
}
