//===---- test_dispatch_nocontext.c -----------------------------------------===//
// 
// OpenMP API Version 5.1
//
// Uses dispatch construct as context for variant directive. Uses nocontext clause
// which can determine whether dispatch is a viable construct for the variant directive.
// When nocontext is true, then dispatch is not a viable construct and vice versa. 
//
// Inspired by "OpenMP 5.1 Features: The Dispatch Construct" video:
// https://www.youtube.com/watch?v=ruugaX95gIs
// 
//===-------------------------------------------------------------------------------===//

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "ompvv.h"
#include <stdbool.h>

#define N 1024

int arr[N]; // implicit map array 
int errors;
int i = 0;

void add_two(int *arr);

#pragma omp declare variant(add_two) match(construct={dispatch})
void add(int *arr){
   for (int i = 0; i < N; i++){ // Base function adds 1 to array values
      arr[i] = i+1;
   }
}

void add_two(int *arr){
   for (int i = 0; i < N; i++){
      arr[i] = i+2; // Variant function adds 2 to array values
   }
}

int test_wrapper() { 
   errors = 0;
   bool nocontext_arg;
   add(arr);
   for(i = 0; i < N; i++){
      OMPVV_TEST_AND_SET(errors, arr[i] != i+1);
   } 
   OMPVV_ERROR_IF(errors > 0, "Base function is not working properly");
   nocontext_arg = true;
   #pragma omp dispatch nocontext(nocontext_arg)
      add(arr);
   
   for(i = 0; i < N; i++){
      OMPVV_TEST_AND_SET(errors, arr[i] != i+1);
   }
   OMPVV_ERROR_IF(errors > 0, "Dispatch w/ nocontext true is not working properly");

   nocontext_arg = false;
   #pragma omp dispatch nocontext(nocontext_arg)
      add(arr);

   for(i = 0; i < N; i++){
      OMPVV_TEST_AND_SET(errors, arr[i] != i+2);
   }
   OMPVV_ERROR_IF(errors > 0, "Dispatch w/ nocontext false is not working properly");
   return errors;
}

int main () {
   OMPVV_TEST_OFFLOADING;
   OMPVV_TEST_AND_SET_VERBOSE(errors, test_wrapper());
   OMPVV_REPORT_AND_RETURN(errors);
}  