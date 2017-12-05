/*
*************************************************************************
*
*                   "DHRYSTONE" Benchmark Program
*                   -----------------------------
*
*  Version:    C, Version 2.1
*
*  File:       dhry_1.c (part 2 of 3)
*
*  Date:       May 25, 1988
*
*  Author:     Reinhold P. Weicker
*
*************************************************************************
*/

#include "orca_time.h"
#include "malloc.h"
#include "dhry.h"
/*COMPILER COMPILER COMPILER COMPILER COMPILER COMPILER COMPILER*/
               
#ifdef COW
#define compiler  "Watcom C/C++ 10.5 Win386"
#define options   "  -otexan -zp8 -5r -ms"
#endif
#ifdef CNW
#define compiler  "Watcom C/C++ 10.5 Win386"
#define options   "   No optimisation"
#endif
#ifdef COD
#define compiler  "Watcom C/C++ 10.5 Dos4GW"
#define options   "  -otexan -zp8 -5r -ms"
#endif
#ifdef CND
#define compiler  "Watcom C/C++ 10.5 Dos4GW"
#define options   "   No optimisation"
#endif
#ifdef CONT
#define compiler  "Watcom C/C++ 10.5 Win32NT"
#define options   "  -otexan -zp8 -5r -ms"
#endif
#ifdef CNNT
#define compiler  "Watcom C/C++ 10.5 Win32NT"
#define options   "   No optimisation"
#endif
#ifdef COO2
#define compiler  "Watcom C/C++ 10.5 OS/2-32"
#define options   "  -otexan -zp8 -5r -ms"
#endif
#ifdef CNO2
#define compiler  "Watcom C/C++ 10.5 OS/2-32"
#define options   "   No optimisation"
#endif
 

/* Global Variables: */
 
Rec_Pointer     Ptr_Glob,
  Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
  Ch_2_Glob;
int             Arr_1_Glob [50];
int             Arr_2_Glob [50] [50];
int             getinput = 0;

 
char Reg_Define[] = "Register option      Selected.";
 
Enumeration Func_1 (Capital_Letter Ch_1_Par_Val,
                    Capital_Letter Ch_2_Par_Val);
/* 
   forward declaration necessary since Enumeration may not simply be int
*/
 
#ifndef ROPT
#define REG
/* REG becomes defined as empty */
/* i.e. no register variables   */
#else
#define REG register
#endif

void Proc_1 (REG Rec_Pointer Ptr_Val_Par);
void Proc_2 (One_Fifty *Int_Par_Ref);
void Proc_3 (Rec_Pointer *Ptr_Ref_Par);
void Proc_4 (); 
void Proc_5 ();
void Proc_6 (Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par);
void Proc_7 (One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val,
             One_Fifty *Int_Par_Ref);
void Proc_8 (Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref,
             int Int_1_Par_Val, int Int_2_Par_Val);
                               
Boolean Func_2 (Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref);

 
/* variables for time measurement: */
 
#define Too_Small_Time 2
/* Measurements should last at least 2 seconds */
 
uint32_t          Begin_Cycle,
  End_Cycle;
double User_Time;
 
double          Microseconds,
  Dhrystones_Per_Second,
  Vax_Mips;
 
/* end of variables for time measurement */
 
 
int main (int argc, char *argv[])
/*****/
 
/* main program, corresponds to procedures        */
/* Main and Proc_0 in the Ada version             */
{
  printf ("\r\n");
  printf ("Dhrystone Benchmark, Version 2.1 (Language: C or C++)\r\n");
  printf ("\r\n");

  double dtime();
 
  One_Fifty   Int_1_Loc;
  REG   One_Fifty   Int_2_Loc;
  One_Fifty   Int_3_Loc;
  REG   char        Ch_Index;
  Enumeration Enum_Loc;
  Str_30      Str_1_Loc;
  Str_30      Str_2_Loc;
  REG   int         Run_Index;
  REG   int         Number_Of_Runs; 
  int         count = 10;
  char        general[9][80] = {" "};

 
  /* Initializations */
  if (argc > 1)
    {
      switch (argv[1][0])
        {
        case 'Y':
          getinput = 1;
          break;
        case 'y':
          getinput = 1;
          break;
        }
    }
 
  /***********************************************************************
   *         Change for compiler and optimisation used                   *
   ***********************************************************************/
 
  Next_Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));
  Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));
  if((Next_Ptr_Glob == NULL) || (Ptr_Glob == NULL)){
    printf("Fail during malloc; dying\r\n");
    return 1;
  }
 
  Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
  Ptr_Glob->Discr                       = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp      = 40;
  strcpy (Ptr_Glob->variant.var_1.Str_Comp, 
          "DHRYSTONE PROGRAM, SOME STRING");       
  strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");
 
  Arr_2_Glob [8][7] = 10;
  /* Was missing in published program. Without this statement,   */
  /* Arr_2_Glob [8][7] would have an undefined value.            */
  /* Warning: With 16-Bit processors and Number_Of_Runs > 32000, */
  /* overflow may occur for this array element.                  */
 
  if (getinput == 0)
    {
      printf ("No run time input data\r\n\r\n");
    }
  else
    {
      printf ("With run time input data\r\n\r\n");
    }
   
#ifdef ROPT
  printf ("Register option selected\r\n\r\n");
#else
  printf ("Register option not selected\r\n\r\n");
  strcpy(Reg_Define, "Register option  Not selected.");
#endif

  /*  
      if (Reg)
      {
      printf ("Program compiled with 'register' attribute\r\n");
      printf ("\r\n");
      }
      else
      {
      printf ("Program compiled without 'register' attribute\r\n");
      printf ("\r\n");
      }

      printf ("Please give the number of runs through the benchmark: ");
      {
      int n;
      scanf ("%d", &n);
      Number_Of_Runs = n;
      }   
      printf ("\r\n"); 
      printf ("Execution starts, %d runs through Dhrystone\r\n",
      Number_Of_Runs);
  */

  Number_Of_Runs = 10;

  do
    {

      Number_Of_Runs = Number_Of_Runs * 2;
      count = count - 1;
      Arr_2_Glob [8][7] = 10;
        
      /***************/
      /* Start timer */
      /***************/
  
      Begin_Cycle = get_time();
   
      for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index)
        {
 
          Proc_5();
          Proc_4();
          /* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true */
          Int_1_Loc = 2;
          Int_2_Loc = 3;
          strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
          Enum_Loc = Ident_2;
          Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);
          /* Bool_Glob == 1 */
          while (Int_1_Loc < Int_2_Loc)  /* loop body executed once */
            {
              Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
              /* Int_3_Loc == 7 */
              Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
              /* Int_3_Loc == 7 */
              Int_1_Loc += 1;
            }   /* while */
          /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
          Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
          /* Int_Glob == 5 */
          Proc_1 (Ptr_Glob);
          for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
            /* loop body executed twice */
            {
              if (Enum_Loc == Func_1 (Ch_Index, 'C'))
                /* then, not executed */
                {
                  Proc_6 (Ident_1, &Enum_Loc);
                  strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
                  Int_2_Loc = Run_Index;
                  Int_Glob = Run_Index;
                }
            }
          /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
          Int_2_Loc = Int_2_Loc * Int_1_Loc;
          Int_1_Loc = Int_2_Loc / Int_3_Loc;
          Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
          /* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 */
          Proc_2 (&Int_1_Loc);
          /* Int_1_Loc == 5 */
 
        }   /* loop "for Run_Index" */
 
      /**************/
      /* Stop timer */
      /**************/

      End_Cycle = get_time();
      User_Time = ((double)(End_Cycle - Begin_Cycle))/SYS_CLK;
             
      printf("%d runs %d.%d seconds %d runs/second\r\n", (int)Number_Of_Runs, (int)User_Time, ((int)(User_Time*10.0))%10, (int)(Number_Of_Runs/User_Time));
      if (User_Time > Too_Small_Time)
        {
          count = 0;
        }
      else
        {
          if (User_Time < (Too_Small_Time/20.0))
            {
              Number_Of_Runs = Number_Of_Runs * 5;
            }
        }
    }   /* calibrate/run do while */
  while (count >0);
 
  printf ("\r\n");
  printf ("Final values (* implementation-dependent):\r\n");
  printf ("\r\n");
  printf ("Int_Glob:      ");
  if (Int_Glob == 5)  printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d  ", Int_Glob);
      
  printf ("Bool_Glob:     ");
  if (Bool_Glob == 1) printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d\r\n", Bool_Glob);
      
  printf ("Ch_1_Glob:     ");
  if (Ch_1_Glob == 'A')  printf ("O.K.  ");               
  else                   printf ("WRONG ");
  printf ("%c  ", Ch_1_Glob);
         
  printf ("Ch_2_Glob:     ");
  if (Ch_2_Glob == 'B')  printf ("O.K.  ");
  else                   printf ("WRONG ");
  printf ("%c\r\n",  Ch_2_Glob);
   
  printf ("Arr_1_Glob[8]: ");
  if (Arr_1_Glob[8] == 7)  printf ("O.K.  ");
  else                     printf ("WRONG ");
  printf ("%d  ", Arr_1_Glob[8]);
            
  printf ("Arr_2_Glob8/7: ");
  if (Arr_2_Glob[8][7] == Number_Of_Runs + 10)
    printf ("O.K.  ");
  else                   printf ("WRONG ");
  printf ("%10d\r\n", Arr_2_Glob[8][7]);
   
  printf ("Ptr_Glob->            ");
  printf ("  Ptr_Comp:       *    %d\r\n", (int) Ptr_Glob->Ptr_Comp);
   
  printf ("  Discr:       ");
  if (Ptr_Glob->Discr == 0)  printf ("O.K.  ");
  else                       printf ("WRONG ");
  printf ("%d  ", Ptr_Glob->Discr);
            
  printf ("Enum_Comp:     ");
  if (Ptr_Glob->variant.var_1.Enum_Comp == 2)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d\r\n", Ptr_Glob->variant.var_1.Enum_Comp);
      
  printf ("  Int_Comp:    ");
  if (Ptr_Glob->variant.var_1.Int_Comp == 17)  printf ("O.K.  ");
  else                                         printf ("WRONG ");
  printf ("%d ", Ptr_Glob->variant.var_1.Int_Comp);
      
  printf ("Str_Comp:      ");
  if (strcmp(Ptr_Glob->variant.var_1.Str_Comp,
             "DHRYSTONE PROGRAM, SOME STRING") == 0)
    printf ("O.K.  ");
  else                printf ("WRONG ");   
  printf ("%s\r\n", Ptr_Glob->variant.var_1.Str_Comp);
   
  printf ("Next_Ptr_Glob->       "); 
  printf ("  Ptr_Comp:       *    %d", (int) Next_Ptr_Glob->Ptr_Comp);
  printf (" same as above\r\n");
   
  printf ("  Discr:       ");
  if (Next_Ptr_Glob->Discr == 0)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d  ", Next_Ptr_Glob->Discr);
   
  printf ("Enum_Comp:     ");
  if (Next_Ptr_Glob->variant.var_1.Enum_Comp == 1)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d\r\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
   
  printf ("  Int_Comp:    ");
  if (Next_Ptr_Glob->variant.var_1.Int_Comp == 18)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d ", Next_Ptr_Glob->variant.var_1.Int_Comp);
   
  printf ("Str_Comp:      ");
  if (strcmp(Next_Ptr_Glob->variant.var_1.Str_Comp,
             "DHRYSTONE PROGRAM, SOME STRING") == 0)
    printf ("O.K.  ");
  else                printf ("WRONG ");   
  printf ("%s\r\n", Next_Ptr_Glob->variant.var_1.Str_Comp);
   
  printf ("Int_1_Loc:     ");
  if (Int_1_Loc == 5)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d  ", Int_1_Loc);
      
  printf ("Int_2_Loc:     ");
  if (Int_2_Loc == 13)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d\r\n", Int_2_Loc);
   
  printf ("Int_3_Loc:     ");
  if (Int_3_Loc == 7)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d  ", Int_3_Loc);
   
  printf ("Enum_Loc:      ");
  if (Enum_Loc == 1)
    printf ("O.K.  ");
  else                printf ("WRONG ");
  printf ("%d\r\n", Enum_Loc);
   
  printf ("Str_1_Loc:                             ");
  if (strcmp(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING") == 0)
    printf ("O.K.  ");
  else                printf ("WRONG ");   
  printf ("%s\r\n", Str_1_Loc);
   
  printf ("Str_2_Loc:                             ");
  if (strcmp(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING") == 0)
    printf ("O.K.  ");
  else                printf ("WRONG ");   
  printf ("%s\r\n", Str_2_Loc);
         
  printf ("\r\n");
    
 
  if (User_Time < Too_Small_Time)
    {
      printf ("Measured time too small to obtain meaningful results\r\n");
      printf ("Please increase number of runs\r\n");
      printf ("\r\n");
    }
  else
    {
      Microseconds = User_Time * Mic_secs_Per_Second 
        / (double) Number_Of_Runs;
      Dhrystones_Per_Second = (double) Number_Of_Runs / User_Time;
      Vax_Mips = Dhrystones_Per_Second / 1757.0;
 
      printf ("Microseconds for one run through Dhrystone: ");
      printf ("%12.2lf \r\n", Microseconds);
      printf ("Dhrystones per Second:                      ");
      printf ("%10.0lf \r\n", Dhrystones_Per_Second);
      printf ("VAX  MIPS rating =                          ");
      printf ("%12.2lf \r\n",Vax_Mips);
      printf ("\r\n");

      /************************************************************************
       *             Type details of hardware, software etc.                  *
       ************************************************************************/

      /************************************************************************
       *                Add results to output file Dhry.txt                   *
       ************************************************************************/
      printf("-------------------- -----------------------------------"        
             "\r\n");
      printf("Dhrystone Benchmark  Version 2.1 (Language: C++)\r\n\r\n");
      printf("PC model             %s\r\n", general[1]);
      printf("CPU                  %s\r\n", general[2]);
      printf("Clock MHz            %s\r\n", general[3]);
      printf("Cache                %s\r\n", general[4]);
      printf("Options              %s\r\n", general[5]);
      printf("OS/DOS               %s\r\n", general[6]);
      printf("Run by               %s\r\n", general[7]);
      printf("From                 %s\r\n", general[8]);
      printf("Mail                 %s\r\n\r\n", general[0]);

      printf("Final values         (* implementation-dependent):\r\n");
      printf("\r\n");
      printf("Int_Glob:      ");
      if (Int_Glob == 5)  printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Int_Glob);
      
      printf("Bool_Glob:     ");
      if (Bool_Glob == 1) printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Bool_Glob);
      
      printf("Ch_1_Glob:     ");
      if (Ch_1_Glob == 'A')  printf("O.K.  ");               
      else                   printf("WRONG ");
      printf("%c\r\n", Ch_1_Glob);
         
      printf("Ch_2_Glob:     ");
      if (Ch_2_Glob == 'B')  printf("O.K.  ");
      else                   printf("WRONG ");
      printf("%c\r\n",  Ch_2_Glob);
   
      printf("Arr_1_Glob[8]: ");
      if (Arr_1_Glob[8] == 7)  printf("O.K.  ");
      else                     printf("WRONG ");
      printf("%d\r\n", Arr_1_Glob[8]);
            
      printf("Arr_2_Glob8/7: ");
      if (Arr_2_Glob[8][7] == Number_Of_Runs + 10)
        printf("O.K.  ");
      else                   printf("WRONG ");
      printf("%10d\r\n", Arr_2_Glob[8][7]);
   
      printf("Ptr_Glob->  \r\n");
      printf("  Ptr_Comp:       *  %d\r\n", (int) Ptr_Glob->Ptr_Comp);
   
      printf("  Discr:       ");
      if (Ptr_Glob->Discr == 0)  printf("O.K.  ");
      else                       printf("WRONG ");
      printf("%d\r\n", Ptr_Glob->Discr);
            
      printf("  Enum_Comp:   ");
      if (Ptr_Glob->variant.var_1.Enum_Comp == 2)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Ptr_Glob->variant.var_1.Enum_Comp);
      
      printf("  Int_Comp:    ");
      if (Ptr_Glob->variant.var_1.Int_Comp == 17)  printf("O.K.  ");
      else                                         printf("WRONG ");
      printf("%d\r\n", Ptr_Glob->variant.var_1.Int_Comp);
      
      printf("  Str_Comp:    ");
      if (strcmp(Ptr_Glob->variant.var_1.Str_Comp,
                 "DHRYSTONE PROGRAM, SOME STRING") == 0)
        printf("O.K.  ");
      else                printf("WRONG ");   
      printf("%s\r\n", Ptr_Glob->variant.var_1.Str_Comp);
   
      printf("Next_Ptr_Glob-> \r\n"); 
      printf("  Ptr_Comp:       *  %d", (int) Next_Ptr_Glob->Ptr_Comp);
      printf(" same as above\r\n");
   
      printf("  Discr:       ");
      if (Next_Ptr_Glob->Discr == 0)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Next_Ptr_Glob->Discr);
   
      printf("  Enum_Comp:   ");
      if (Next_Ptr_Glob->variant.var_1.Enum_Comp == 1)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
   
      printf("  Int_Comp:    ");
      if (Next_Ptr_Glob->variant.var_1.Int_Comp == 18)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Next_Ptr_Glob->variant.var_1.Int_Comp);
   
      printf("  Str_Comp:    ");
      if (strcmp(Next_Ptr_Glob->variant.var_1.Str_Comp,
                 "DHRYSTONE PROGRAM, SOME STRING") == 0)
        printf("O.K.  ");
      else                printf("WRONG ");   
      printf("%s\r\n", Next_Ptr_Glob->variant.var_1.Str_Comp);
   
      printf("Int_1_Loc:     ");
      if (Int_1_Loc == 5)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Int_1_Loc);
      
      printf("Int_2_Loc:     ");
      if (Int_2_Loc == 13)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Int_2_Loc);
   
      printf("Int_3_Loc:     ");
      if (Int_3_Loc == 7)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Int_3_Loc);
   
      printf("Enum_Loc:      ");
      if (Enum_Loc == 1)
        printf("O.K.  ");
      else                printf("WRONG ");
      printf("%d\r\n", Enum_Loc);
   
      printf("Str_1_Loc:     ");
      if (strcmp(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING") == 0)
        printf("O.K.  ");
      else                printf("WRONG ");   
      printf("%s\r\n", Str_1_Loc);
   
      printf("Str_2_Loc:     ");
      if (strcmp(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING") == 0)
        printf("O.K.  ");
      else                printf("WRONG ");   
      printf("%s\r\n", Str_2_Loc);
         
   
      printf("\r\n");
      printf("%s\r\n",Reg_Define);
      printf("\r\n");
      printf("Microseconds 1 loop:  %d\r\n",(int)Microseconds);
      printf("Dhrystones / second:  %d\r\n",(int)Dhrystones_Per_Second);
      printf("VAX MIPS rating:      %d\r\n\r\n",(int)Vax_Mips);
    }
   
  printf ("\r\n");
  printf ("A new results file will have been created in the same directory as the\r\n");
  printf (".EXE files if one did not already exist. If you made a mistake on input, \r\n");
  printf ("you can use a text editor to correct it, delete the results or copy \r\n");
  printf ("them to a different file name. If you intend to run multiple tests you\r\n");
  printf ("you may wish to rename DHRY.TXT with a more informative title.\r\n\r\n");
  printf ("Please submit feedback and results files as a posting in Section 12\r\n");
  printf ("or to Roy_Longbottom@compuserve.com\r\n\r\n");

  while(1){
  }
  return 0;
}
 
 
void Proc_1 (REG Rec_Pointer Ptr_Val_Par)
/******************/
 
/* executed once */
{
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;  
  /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */
   
  structassign (*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob);
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp 
    = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (&Next_Record->Ptr_Comp);
  /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp 
     == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
    /* then, executed */
    {
      Next_Record->variant.var_1.Int_Comp = 6;
      Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp, 
              &Next_Record->variant.var_1.Enum_Comp);
      Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
      Proc_7 (Next_Record->variant.var_1.Int_Comp, 10, 
              &Next_Record->variant.var_1.Int_Comp);
    }
  else /* not executed */
    structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
} /* Proc_1 */
 
 
void Proc_2 (One_Fifty *Int_Par_Ref)
/******************/
/* executed once */
/* *Int_Par_Ref == 1, becomes 4 */
 
{
  One_Fifty  Int_Loc;
  Enumeration   Enum_Loc;
 
  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
      /* then, executed */
      {
        Int_Loc -= 1;
        *Int_Par_Ref = Int_Loc - Int_Glob;
        Enum_Loc = Ident_1;
      } /* if */
  while (Enum_Loc != Ident_1); /* true */
} /* Proc_2 */
 
 
void Proc_3 (Rec_Pointer *Ptr_Ref_Par)
/******************/
/* executed once */
/* Ptr_Ref_Par becomes Ptr_Glob */
 
{
  if (Ptr_Glob != Null)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
} /* Proc_3 */
 
 
void Proc_4 () /* without parameters */
/*******/
/* executed once */
{
  Boolean Bool_Loc;
 
  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */
 
 
void Proc_5 () /* without parameters */
/*******/
/* executed once */
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
} /* Proc_5 */
 
 
/* Procedure for the assignment of structures,          */
/* if the C compiler doesn't support this feature       */
#ifdef  NOSTRUCTASSIGN
memcpy (d, s, l)
register char   *d;
register char   *s;
register int    l;
{
  while (l--) *d++ = *s++;
}
#endif

double dtime()
{
  
  /* #include <ctype.h> */

#define HZ SYS_CLK
  uint32_t tnow;

  double q;
  tnow = get_time();
  q = (double)tnow / (double)HZ;     
  return q;
}

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		printf("Illegal Instruction\r\n");
		for (;;);
	}

	// Ignore interrupt
	printf("Interrupt %d %d\r\n", cause, epc);
	return epc;
}
