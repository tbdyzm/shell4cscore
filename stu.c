#include<stdio.h>
int main()
{
    int i = 1, j = 1, n, w;
    
    printf("Enter number of days in month: ");
    scanf("%d", &n);
    
    printf("Enter starting day of the week (1=Sun, 7=Sat): ");
    scanf("%d", &w);
    {
        
        for (; j < w - 1; j ++){
            printf("   ");
        }
        if ( w != 1 )
            printf("  ");
    }
    
    for (; i <= n; i++){
        if ( ( i - 8 + w ) % 7 == 0 )
            printf("%3d\n", i);
        else if ( ( i - 8 + w ) % 7 == 1 || ( i - 8 + w ) % 7 == -6)
            printf("%2d", i);
        else
            printf("%3d", i);
    }
    
    printf("\n");
    
    return 0;
}
