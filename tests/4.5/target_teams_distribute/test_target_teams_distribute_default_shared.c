//===--- test_target_teams_distribute_default_shared.c-----------------------===//
//
// OpenMP API Version 4.5 Nov 2015
//
// This test uses the default(shared) clause on a target teams distribute
// directive.  The test aims to validate that when the default(shared) clause
// is present, that all variables without explicit data sharing attributes
// will be shared within the region.  To test this, we test that a data element
// that should be shared due to the default(shared) clause is available to
// all the teams.  The first test uses atomic to write to the variable without
// race conditions.  The second test allows these race contitions, but then
// validates that the resulting value is one of the possible values.  The last
// test, instead of testing writes, only reads from the variable and tests that
// all teams can read the shared value.
//
////===----------------------------------------------------------------------===//

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include "ompvv.h"

#define N 1024

int main() {
  int isOffloading = 0;
  OMPVV_TEST_AND_SET_OFFLOADING(isOffloading);
  int a[N];
  int share = 0;
  int errors = 0;
  int num_teams;
  
  for (int x = 0; x < N; ++x) {
    a[x] = x;
  }
  
#pragma omp target data map(to: a[0:N]) map(tofrom: share, num_teams)
  {
#pragma omp target teams distribute default(shared) defaultmap(tofrom:scalar)
    for (int x = 0; x < N; ++x) {
      num_teams = omp_get_num_teams();
#pragma omp atomic
      share = share + a[x];
    }
  }
  
  for (int x = 0; x < N; ++x) {
    share = share - x;
  }
  OMPVV_TEST_AND_SET_VERBOSE(errors, (share != 0));
    
  share = 5;

#pragma omp target data map(tofrom: a[0:N]) map(tofrom: share)
  {
#pragma omp target teams distribute default(shared) defaultmap(tofrom:scalar)
    for (int x = 0; x < N; ++x) {
      a[x] = a[x] + share;
    }
  }

  for (int x = 0; x < N; ++x) {
    OMPVV_TEST_AND_SET_VERBOSE(errors, (a[x] - 5 != x));
    if (a[x] - 5 != x) {
      break;
    }
  }

  if (num_teams == 1) {
    OMPVV_WARNING("Test operated on one team, results of default shared test are inconclusive.");
  }

  OMPVV_REPORT_AND_RETURN(errors);
}
