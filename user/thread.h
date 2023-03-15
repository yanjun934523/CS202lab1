#ifndef THREAD_H
#define THREAD_H

// This file comes straight from lab manual

// Define a lock_t struct with a single integer field called "locked"
struct lock_t {
    int locked;
};

// Declare function prototypes for thread management and synchronization
int thread_create(void *(start_routine)(void*), void *arg);
void lock_init(struct lock_t* lock);
void lock_acquire(struct lock_t* lock);
void lock_release(struct lock_t* lock);

#endif