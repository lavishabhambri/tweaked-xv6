// // #include "kernel/types.h"
// // #include "kernel/stat.h"
// // #include "user/user.h"
// // #include "kernel/fcntl.h"
// // // int 
// // // main(int argc, char *argv[]) 
// // // { 
// // // 	char s[64];
// // //   int id;

// // // 	strcpy(s,argv[1]);
// // // 	argv++;
// // //   id = fork();

	
// // //     if (id == 0) { 
// // //       trace();
// // //       exec(s, argv); 
// // //       printf(1, "Child: WE DON'T SEE THIS\n"); 
// // //       exit(0);  
// // //     } else { 
// // //       id = wait(); 
// // //       printf(1, "Parent: child terminated\n"); 
// // //     } 
// // //     exit(0); 
// // // }

// // int 
// // main(int argc, char ** argv) 
// // {
// //   int pid = fork();
// //   if(pid < 0) {
// //     printf("fork(): failed\n");
// //     exit(1);
// //   } else if(pid == 0) {
// //     if(argc == 1) {
// //       sleep(10);
// //       exit(0);
// //     } else {
// //       exec(argv[2], argv + 1);
// //       printf("exec(): failed\n");
// //       exit(1);
// //     }  
// //   } else {
// //     //   printf("STRACE CALLED");
// //     strace(0);
// //     // int rtime, wtime;
// //     // waitx(0, &wtime, &rtime);
// //     // printf("\nwaiting:%d\nrunning:%d\n", wtime, rtime);
// //   }
// //   exit(0);
// // }


// // We cannot include many header files because definitions will conflict
// // Including header files included by other programs eg `cat`
// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"

// // OUR file
// #include "strace.h"


// void forkrun() {
// 	int fr = fork();
// 	if (fr == -1) {
// 		printf("Fork error!\n");
// 		return;
// 	} else if (fr == 0) {
// 		close(open("README", 0));
// 		// exit the child early
// 		// Or output would be confusing
// 		exit(0);
// 	} else {
// 		// wait();
// 	}
// }

// int main() {
// 	// printf("Process is being traced.\n");
// 	// strace(T_TRACE);
// 	// forkrun();

// 	// strace(T_UNTRACE);
// 	// printf("Processs & forks being traced.\n");
// 	strace(T_TRACE | T_ONFORK);
// 	// forkrun();
//   int fr = fork();
// 	if (fr == -1) {
// 		printf("Fork error!\n");
// 	} else if (fr == 0) {
// 		close(open("README", 0));
// 		// exit the child early
// 		// Or output would be confusing
// 		exit(0);
// 	} else {
// 		strace(T_TRACE | T_ONFORK);
// 	}

// 	// strace(T_UNTRACE);
// 	// printf("Process not being traced.\n");
// 	// forkrun();

// 	exit(0);
// }

#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int i;
  char *nargv[MAXARG];

  if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){
    fprintf(2, "Usage: %s mask command\n", argv[0]);
    exit(1);
  }

  if (strace(atoi(argv[1])) < 0) {
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }
  
  for(i = 2; i < argc && i < MAXARG; i++){
    nargv[i-2] = argv[i];
  }
  exec(nargv[0], nargv);
  exit(0);
}