# Assignment - 4
## By Lavisha Bhambri - 2020101088

### Implementation of Scheduling Policies in xv6
1. Specification-1
For the system call tracing, I followed the same procedure just like the waitx system call(taught in tutorial).I created a variable in struct proc named mask that stores the mask value from the arguments passed by the user. I created 2 arrays of char* & int where I stored all the names & number of arguments of the system calls respectively. Then in the kernel/syscall.c file, I updated the  syscall() function and printed the pid, system call name, values of the arguments & return value of the system call. I also updated the fork() in the kernel/proc.c file to copy the trace mask from the parent to the child process. For making the system call accessible to the user, I added  $U/_strace to UPROGS in Makefile and also added the user-space stub & its prototype.

2. a) Specification-2
First of all, I added the CFLAG for the SCHEDULER in the Makefile and used the #ifdef and #endif statements. 
Round Robin (RR) - The default scheduler of xv6 was Robin Robin, so I just added the whole code of the scheduler in the #ifdef and #endif statements.

2. b) First Come First Serve (FCFS) - For this, I used startTime in struct proc. I created a struct proc* procWithMinTime, that stores the process struct having minimum time. Whenever the process is running, then the scheduler always has the lock of that process. So, I acquired the process lock and checked if the startTime of the current process is less than the startTime for the procWithMinTime. For the initial case when the process is runnable and procWithMinTime=0, then I simply updated the value of procWithMinTime to the current acquired process. I only released the lock of this acquired process once I found another candidate for the procWithMinTime. After getting the process having minimum start time among all the processes, I switched the CPU’s context to that process’s context, updated its state to RUNNING and finally released the lock of the procWithMinTime. There was an edge case to this scheduler, when I found no process then I would continue.

2. c) Priority Based Scheduler (PBS) - For this, I created a few variables in the struct proc namely, dynamicPriority, staticPriority, sleepStartTime, sleepEndTime, niceness. I assigned the staticPriority=60 & niceness=5 to the newly created process. I stored the time when the process had started sleeping, ended sleeping & ticks spent in running time (using increaseRunTime() which runs in each clock interrupt).  To get the time the process has been sleeping for, I updated the value of sleepStartTime & sleepEndTime of the process in 3 functions namely, kill(), wakeup(), sleep() and then I created a new function that updates the dynamic priority of the process using niceness, sleepTime (sleepEndTime - sleepStartTime) and runningTime. For the setpriority(), I iterated for the process having pid= given value of pid among all the processes & then I updated its value while returning the old priority.


### Possible Exploitation of MLFQ Policy by a Process

If a process voluntarily relinquishes control of the CPU, it leaves the queuing network, and when the process becomes ready again after the I/O, it is inserted at the tail of the same queue, from which it is relinquished earlier. This can be exploited by a coder if the coder adds a short I/O burst having frequency less than the time slice of the queue. Due to this, the process will be removed from the queue and be added back to the same queue (highest priority queue). This will hold the process in the same queue again and again and will get finished with the highest priority in the highest priority queue.

### Tabulation of the performances of the scheduling algorithms (Observed outputs)

1. Round Robin (RR) -
```c
Process 7 finished
Process 6 finished
Process 5 finished
Process 8 finished
Process 9 finished
PPPrrroooceccseessss s  21 0fi  fnfiiisnhnieissdh
heeddP
r
ocePssro c3es fsi n4i fshinedis
hed
Average rtime 115,  wtime 12
```

2. First Come First Serve Scheduling Policy (FCFS)
```
ProcPersosc es2s  f0in ifsihenidsh
ed
Process 1 finished
Process 5 finished
Process 3 finished
Process 4 finished
Process 7 finished
ProPcreoscse ss8  6f ifniniisshehded

Process 9 finished
Average rtime 51,  wtime 8
```

3. Priority Based Scheduling Policy (PBS) 
```
Process 5 finished
Process 7 finished
Process 6 finished
Process 8 finished
Process 9 finished
PPPrroocceesrso s2sc  efsi0n isfsi hn1eids
h efd
iPnrioscheesPsd r
o3c efisnsi sh4ed 
finished
Average rtime 113,  wtime 10
```

### Performance Comparison
On running the benchmark program provided by the TAs, I got the following results:-

1. Round Robin (RR) - On running the time command to run the benchmark code, so that it returns the running and waiting time of the whole process which depends on machine to machine, The average runtime & waiting time were found to be around 115 ticks & 12 ticks respectively on my machine.

2. First Come First Serve Scheduling Policy (FCFS) - On running the time command to run benchmark code, so that it returns the running and waiting time of the whole process, the waiting & running time, which depend on machine to machine, was found to be the least, around 21 ticks & 51 ticks on my machine, which should be expected actually, because identical processes are being created and FCFS does not allow pre-emption. So the extra overhead due to context switches is not there, and therefore, the waiting time is the least.

3. Priority Based Scheduling Policy (PBS) - On running the time command to run benchmark code, so that it returns the running and waiting time of the whole process, the waiting & running time, which depends on machine to machine, was found to be very similar to the Round Robin Policy, around 10 ticks & 113 ticks on my machine, which is very much expected because we are setting the default priority to be 60, and priorities are not being changed in between. Round Robin Policy is applied for processes having equal priorities, which explains the output.


**Observations** - 
The waiting time for the FCFS is the lowest as it does not waste time for choosing the process and directly takes the process having the lowest creation time. The waiting time of FCFS is lesser than the waiting time of PBS due to pre-emption of PBS which causes CPU to lose valuable time by choosing process again and again. Lastly, the waiting time of RR is high due to continuous process change which causes CPU to reduce effeciency.

### Other functionalities

## `waitx`
This function is a modification of the already existing wait function. It calculates runTime by incrementing it whenever the ticks are incremented and wtime is calculated by 
```c
wtime = p->endTime - (p->startTime + p->runTime);
```
Here endTime is the exit time of the process, startTime is start time/creation time, runTime is run time.

## `time`
This is a simple user defined function which can be used to check waitx system call.

## `setpriority`
This is a system call used to change the priority of processes in case of PBS scheduler.

## `setpriority priority pid`
This is a user defined function that can be used to set the priority of the processes in PBS scheduler. It uses **setpriority** system call in its implementation.




