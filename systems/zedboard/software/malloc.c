#include "malloc.h"
#include "printf.h"

static char heap[HEAP_SIZE];

void *malloc(size_t bytes){
  static size_t heap_base = 0;
  printf("Malloc at 0x%08X of 0x%08X bytes (0x%08X bytes remaining)\r\n", (int)heap_base, (int)bytes, (int)(HEAP_SIZE-heap_base));
  if(heap_base + bytes > HEAP_SIZE){
    return NULL;
  }
  void *return_ptr = &heap[heap_base];
  heap_base += bytes;
  return return_ptr;
}  
