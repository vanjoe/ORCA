#include "malloc.h"

static char heap[HEAP_SIZE];

void *malloc(size_t bytes){
  static size_t heap_base = 0;
  if(heap_base + bytes > HEAP_SIZE){
    return NULL;
  }
  void *return_ptr = &heap[heap_base];
  heap_base += bytes;
  return return_ptr;
}  
