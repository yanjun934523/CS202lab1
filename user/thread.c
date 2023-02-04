#include "thread.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "user.h"

int thread_create(void *(start_routine)(void*), void *arg){
  // Allocate user stack AND call clone
  void* stack = malloc(PGSIZE);
  int retval = clone(stack);

  if(retval == 0){ // We are a thread
    start_routine(arg); // Call function and pass in argument
    exit(0); // Exit when done, per lab manual
  }
  else if (retval == -1){ // There was an error
    return retval;
  }
  else{
    return 0; // success
  }
}

// Looked at spin lock for the implementation below, kept it simple and at user level.
// Used the atomic instructions like requested by lab manual
void lock_init(struct lock_t* lock){
  lock->locked = 0;
}

void lock_acquire(struct lock_t* lock){
  // On RISC-V, sync_lock_test_and_set turns into an atomic swap:
  //   a5 = 1
  //   s1 = &lk->locked
  //   amoswap.w.aq a5, a5, (s1)

  while(__sync_lock_test_and_set(&lock->locked, 1) != 0)
    ;

  __sync_synchronize();
}

void lock_release(struct lock_t* lock){
  // Tell the C compiler and the CPU to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other CPUs before the lock is released,
  // and that loads in the critical section occur strictly before
  // the lock is released.
  // On RISC-V, this emits a fence instruction.
  __sync_synchronize();

  // Release the lock, equivalent to lk->locked = 0.
  // This code doesn't use a C assignment, since the C standard
  // implies that an assignment might be implemented with
  // multiple store instructions.
  // On RISC-V, sync_lock_release turns into an atomic swap:
  //   s1 = &lk->locked
  //   amoswap.w zero, zero, (s1)
  __sync_lock_release(&lock->locked);
}
