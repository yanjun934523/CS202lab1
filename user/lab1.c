#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc,char *argv[]){
	int cc = 0;

	if (argc >= 2)cc= atoi(argv[1]);
    printf("info(%d)\n",cc);
	info(cc);
	exit(0);
}

