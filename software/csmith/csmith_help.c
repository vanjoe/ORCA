
int printf (const char *restrict str, ...) {
	return 0;
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
