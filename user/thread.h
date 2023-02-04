#ifndef THREAD_H
#define THREAD_H

// This file comes straight from lab manual
struct lock_t {
    int locked;
};
int thread_create(void *(start_routine)(void*), void *arg);
void lock_init(struct lock_t* lock);
void lock_acquire(struct lock_t* lock);
void lock_release(struct lock_t* lock);

#endif


