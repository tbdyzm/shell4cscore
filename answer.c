#include<stdio.h>
int main()
{
	int days,x,i;
	printf("Enter number of days in month: ");
	scanf("%2d", &days);
	printf("Enter starting day of the week( 1=Sun, 7=Sat): ");
	scanf("%1d", &x);
		if(days<28||days>31) { 
		printf("Error");
		return 0;
	}
	if(x<1||x>7){
		printf("Error");
		return 0;
		} 
	switch(x) {
		case 1:break;
		case 2:printf("   ");break;
		case 3:printf("      ");break;
		case 4:printf("         ");break;
		case 5:printf("            ");break;
		case 6:printf("               ");break;
		case 7:printf("                  ");break;
	}
	for(i=1;i<=days;++i) {
		printf("%3d", i); 
		if((i+x-1)%7==0) {
			printf("\n");
		}
		
	}
	printf("\n");
	return 0;
}