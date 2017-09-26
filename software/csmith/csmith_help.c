#include <stdlib.h>
int printf (const char *restrict str, ...) {
	return 0;
}
void * memcpy (void * restrict dest, const void * restrict src, size_t n)
{
	for(size_t i=0;i<n;n++){
		((char*)dest)[i] = ((char*)src)[i] ;
	}
	return dest;
}
void *memset(void *s, int c, size_t n){
	char* ss=s;
	while(n--){
		ss[n]=c;
	}
	return s;
}
int strcmp (const char * a, const char *b)
{

	while(*a && *b && *a == *b){
		a++;b++;
	}
	if(*a == *b) return 0;
	if(*a < *b) return -1;
	return 1;


}
