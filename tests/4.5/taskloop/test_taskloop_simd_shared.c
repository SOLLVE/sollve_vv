//===--test_taskloop_shared.c ----------------------------------------------------===//
//
// OpenMP API Version 4.5 Nov 2015
//
// Test uses a value within a taskloop & an atomic construct to update the value of
// s_val. The shared clause ensures that the s_val will be shared between threads,
// and therefore should be equal to N After the taskloop region.
//
////===--------------------------------------------------------------------------===//

#include <omp.h>
#include <stdio.h>
#include "ompvv.h"

#define N 1024

int taskloop_shared() {

  int errors = 0;
  int i, j;
  int A[N], B[N], C[N];
  for(int i = 0; i < N; i++){
    A[i] = 1;
    B[i] = 2;
    C[i] = 3;
  }

#pragma omp parallel
  {
    int s_val=4;

    #pragma omp taskloop simd shared(s_val)
      for (i = 0; i < N; i++){
        A[i] *= B[i] * C[i] * s_val;
      }
    #pragma omp barrier
    #pragma omp single
    for(int i = 0; i < N; i++){
      OMPVV_TEST_AND_SET_VERBOSE(errors, A[i] != B[i] * C[i] * s_val);
    }
  } //end parallel
  return errors;

}

int main() {
    int errors = 0;
    OMPVV_TEST_OFFLOADING;
    OMPVV_TEST_AND_SET_VERBOSE(errors, taskloop_shared());
    OMPVV_REPORT_AND_RETURN(errors);
}
