!===--test_target_map_program_array.F90 ----mapping of arrays in programs--===!
!
! OpenMP API Version 4.5 Nov 2015
!
! Testing the mapping of arrays that are created inside program
! definitions
!
!!===----------------------------------------------------------------------===!
#include "ompvv.F90"

#define N 100

      PROGRAM test_target_map_program_array
        USE iso_fortran_env
        USE ompvv_lib
        USE omp_lib
        implicit none
        INTEGER :: array_1d(N)
        INTEGER :: array_2d(N,N)
        INTEGER :: array_3d(N,N,N)

        OMPVV_TEST_OFFLOADING
        OMPVV_TEST_VERBOSE(test_program_map_to_array() .ne. 0)
        OMPVV_TEST_VERBOSE(test_program_map_from_array() .ne. 0)
        OMPVV_TEST_VERBOSE(test_program_map_tofrom_array() .ne. 0)

        OMPVV_REPORT_AND_RETURN()


        CONTAINS
          ! Function to tests the map (to:...)
          INTEGER FUNCTION  test_program_map_to_array()
            INTEGER :: helper_array_1d(N)
            INTEGER :: helper_array_2d(N,N)
            INTEGER :: helper_array_3d(N,N,N)
            INTEGER :: err_before, err_after

            OMPVV_GET_ERRORS(err_before)

            OMPVV_INFOMSG("testing map(to...) of array in program")

            array_1d(:) = 10
            array_2d(:,:) = 10
            array_3d(:,:,:) = 10

            !$omp target map(to: array_1d, array_2d, array_3d) &
            !$omp map(from: helper_array_1d, helper_array_2d) &
            !$omp map(from: helper_array_3d)
              helper_array_1d = array_1d
              helper_array_2d = array_2d
              helper_array_3d = array_3d

              ! This value should not be copied back
              ! Assumes that that the target region is neither
              ! executed on the host nor with unified-shared memory
              array_1d(:) = 0
              array_2d(:,:) = 0
              array_3d(:,:,:) = 0
            !$omp end target

            OMPVV_TEST_VERBOSE(ANY(helper_array_1d /= 10))
            OMPVV_TEST_VERBOSE(ANY(helper_array_2d /= 10))
            OMPVV_TEST_VERBOSE(ANY(helper_array_3d /= 10))

            ! check that it did not copy back
            OMPVV_TEST_VERBOSE(ANY(array_1d /= 10))
            OMPVV_TEST_VERBOSE(ANY(array_2d /= 10))
            OMPVV_TEST_VERBOSE(ANY(array_3d /= 10))

            OMPVV_GET_ERRORS(err_after)

            test_program_map_to_array = err_before - err_after

          END FUNCTION test_program_map_to_array
          ! Function to tests the map (from:...)
          INTEGER FUNCTION  test_program_map_from_array()
            INTEGER :: helper_array_1d(N)
            INTEGER :: helper_array_2d(N,N)
            INTEGER :: helper_array_3d(N,N,N)
            INTEGER :: err_before, err_after
            CHARACTER(len=400) :: msgHelper

            OMPVV_GET_ERRORS(err_before)

            OMPVV_INFOMSG("testing map(from...) of array in program")

            array_1d(:) = 999
            array_2d(:,:) = 999
            array_3d(:,:,:) = 999

            !$omp target map(from: array_1d, array_2d, array_3d) &
            !$omp map(from: helper_array_1d, helper_array_2d) &
            !$omp map(from: helper_array_3d)
              ! NOTE: array_1d/2d/3d is uninitialized,
              ! unless distributed-shared memory or executed on the host
              helper_array_1d = array_1d
              helper_array_2d = array_2d
              helper_array_3d = array_3d

              array_1d(:) = 20
              array_2d(:,:) = 20
              array_3d(:,:,:) = 20
            !$omp end target

            ! Checking that data is not copied to the device
            ! Assumes that that the target region is neither
            ! executed on the host nor with unified-shared memory
            ! Assumes additionally that an uninit array has not 999 for all elems
            WRITE(msgHelper, *) "Array seemed to have been copied to &
              & the device when using the from modifier."
            OMPVV_WARNING_IF(ALL(helper_array_1d == 999), msgHelper)
            OMPVV_WARNING_IF(ALL(helper_array_2d == 999), msgHelper)
            OMPVV_WARNING_IF(ALL(helper_array_3d == 999), msgHelper)

            OMPVV_TEST_VERBOSE(ANY(array_1d /= 20))
            OMPVV_TEST_VERBOSE(ANY(array_2d /= 20))
            OMPVV_TEST_VERBOSE(ANY(array_3d /= 20))

            OMPVV_GET_ERRORS(err_after)

            test_program_map_from_array = err_before - err_after

          END FUNCTION test_program_map_from_array
          ! Function to tests the map (tofrom:...)
          INTEGER FUNCTION  test_program_map_tofrom_array()
            INTEGER :: helper_array_1d(N)
            INTEGER :: helper_array_2d(N,N)
            INTEGER :: helper_array_3d(N,N,N)
            INTEGER :: err_before, err_after

            OMPVV_GET_ERRORS(err_before)

            OMPVV_INFOMSG("testing map(tofrom...) of array in program")

            array_1d(:) = 10
            array_2d(:,:) = 10
            array_3d(:,:,:) = 10

            !$omp target map(tofrom: array_1d, array_2d, array_3d) &
            !$omp map(from: helper_array_1d, helper_array_2d) &
            !$omp map(from: helper_array_3d)
              helper_array_1d = array_1d
              helper_array_2d = array_2d
              helper_array_3d = array_3d

              array_1d(:) = 20
              array_2d(:,:) = 20
              array_3d(:,:,:) = 20
            !$omp end target

            ! Testing the to functionality
            OMPVV_TEST_VERBOSE(ANY(helper_array_1d /= 10))
            OMPVV_TEST_VERBOSE(ANY(helper_array_2d /= 10))
            OMPVV_TEST_VERBOSE(ANY(helper_array_3d /= 10))

            ! Testing the from functionality
            OMPVV_TEST_VERBOSE(ANY(array_1d /= 20))
            OMPVV_TEST_VERBOSE(ANY(array_2d /= 20))
            OMPVV_TEST_VERBOSE(ANY(array_3d /= 20))

            OMPVV_GET_ERRORS(err_after)

            test_program_map_tofrom_array = err_before - err_after

          END FUNCTION test_program_map_tofrom_array
      END PROGRAM test_target_map_program_array
