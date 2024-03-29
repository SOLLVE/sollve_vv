!===---- test_target_data_map_from_array_sections.F90 - mapping array sections ---===//
!
! OpenMP API Version 4.5 Nov 2015
!
! Testing array sections mapping from. This tests must cover dynamically allocated
! arrays, 1D, 2D and 3D arrays. As well as sections mapping
!
!===-------------------------------------------------------------------------===//
#include "ompvv.F90"

#define N 50

      PROGRAM test_target_data_map_from
        USE iso_fortran_env
        USE ompvv_lib
        USE omp_lib
        implicit none
        LOGICAL :: isOffloading
        INTEGER :: i,j
        CHARACTER(len=500) :: msgHelper

        OMPVV_TEST_AND_SET_OFFLOADING(isOffloading)
        OMPVV_TEST_VERBOSE(test_array_sections_pointer_1D() .NE. 0)
        OMPVV_TEST_VERBOSE(test_array_sections_pointer_2D() .NE. 0)
        OMPVV_TEST_VERBOSE(test_array_sections_pointer_3D() .NE. 0)
        OMPVV_TEST_VERBOSE(test_array_sections_1D() .NE. 0)
        OMPVV_TEST_VERBOSE(test_array_sections_2D() .NE. 0)
        OMPVV_TEST_VERBOSE(test_array_sections_3D() .NE. 0)

        OMPVV_REPORT_AND_RETURN()

        CONTAINS
          ! Testing pointer array sections 1D
          INTEGER FUNCTION test_array_sections_pointer_1D()
            INTEGER, ALLOCATABLE, DIMENSION(:) :: my1DPtr
            INTEGER, ALLOCATABLE, DIMENSION(:) :: my1DPtr2
            INTEGER, ALLOCATABLE, DIMENSION(:) :: my1DPtr3
            INTEGER, DIMENSION (N) :: myTmpArray
            INTEGER :: errors, testVal
            OMPVV_INFOMSG("test array sections pointer 1D")
            errors = 0

            ! array allocation
            allocate(my1DPtr(N))
            allocate(my1DPtr2(N))
            allocate(my1DPtr3(N))

            ! array initialization
            my1DPtr(:) = 10
            my1DPtr2(:) = 10
            my1DPtr3(:) = 10
            myTmpArray(:) = 0

            ! testing map(from:...) with different array sections

            !$omp target data map(from: my1DPtr(10:N-10)) &
            !$omp map(from: my1DPtr2(10:), my1DPtr3(:N-10))

              !$omp target map(alloc: my1DPtr(10:N-10)) &
              !$omp map(alloc: my1DPtr2(10:), my1DPtr3(:N-10)) &
              !$omp map(tofrom: myTmpArray)
                ! This should result in garbage writes to myTmpArray.
                ! Since the arrays are not copied to, they should not
                ! have the value of the host.
                myTmpArray(10:N-10) = myTmpArray(10:N-10) + &
                &                     my1DPtr(10:N-10)
                myTmpArray(10:) = myTmpArray(10:) + my1DPtr2(10:)
                myTmpArray(:N-10) = myTmpArray(:N-10) + my1DPtr3(:N-10)

                ! Asign a value to the region and
                ! checking for this value on the host
                my1DPtr(10:N-10) = 0
                my1DPtr2(10:) = 0
                my1DPtr3(:N-10) = 0
              !$omp end target

            !$omp end target data

            !testing that the array is just copied from and not to
            IF (isOffloading) THEN
              testVal = (N-19)*10 + &
              &         (N-9)*10 + &
              &         (N-10)*10
              ! Since the data should not have been copied over the device
              ! we want to make sure that the data for the variab
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DPtr(10:N-10) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DPtr2(10:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DPtr3(:N-10) /= 0))

            deallocate(my1DPtr)
            deallocate(my1DPtr2)
            deallocate(my1DPtr3)

            test_array_sections_pointer_1D = errors
          END FUNCTION test_array_sections_pointer_1D

          ! Testing pointer array sections 2D
          INTEGER FUNCTION test_array_sections_pointer_2D()
            INTEGER, ALLOCATABLE, DIMENSION(:,:) :: my2DPtr
            INTEGER, ALLOCATABLE, DIMENSION(:,:) :: my2DPtr2
            INTEGER, ALLOCATABLE, DIMENSION(:,:) :: my2DPtr3
            INTEGER, DIMENSION (N,N) :: myTmpArray
            INTEGER :: errors, testVal
            OMPVV_INFOMSG("test array sections pointer 2D")
            errors = 0

            ! array allocation
            allocate(my2DPtr(N,N))
            allocate(my2DPtr2(N,N))
            allocate(my2DPtr3(N,N))

            ! array initialization
            my2DPtr(:,:) = 10
            my2DPtr2(:,:) = 10
            my2DPtr3(:,:) = 10
            myTmpArray(:,:) = 0

            ! testing map(from:...) with different array sections
            ! 2.10.5 Specs: If a list item is an array section
            ! it must specify contiguous storage.

            DO i = 1,N
              !$omp target data map(from: my2DPtr(10:N-10, i)) &
              !$omp map(from: my2DPtr2(10:, i), my2DPtr3(:N-10, i)) &
              !$omp map(tofrom: myTmpArray)

                !$omp target map(alloc: my2DPtr(10:N-10, i)) &
                !$omp map(alloc: my2DPtr2(10:, i), my2DPtr3(:N-10, i)) &
                !$omp map(tofrom: myTmpArray)
                  ! This should result in garbage writes to myTmpArray.
                  ! Since the arrays are not copied to, they should not
                  ! have the value of the host.
                  myTmpArray(10:N-10, i) = &
                  &    myTmpArray(10:N-10, i) + &
                  &    my2DPtr(10:N-10, i)
                  myTmpArray(10:, i) = &
                  &    myTmpArray(10:, i) + &
                  &    my2DPtr2(10:, i)
                  myTmpArray(:N-10, i) = &
                  &    myTmpArray(:N-10, i) + &
                  &    my2DPtr3(:N-10, i)
                  ! Asign a value to the region and
                  ! checking for this value on the host
                  my2DPtr(10:N-10, i) = 0
                  my2DPtr2(10:, i) = 0
                  my2DPtr3(:N-10, i) = 0
                !$omp end target
              !$omp end target data
            END DO

            !testing that the array is just copied from and not to
            IF (isOffloading) THEN
              testVal = N*(N-19)*10 + &
              &         N*(N-9)*10 + &
              &         N*(N-10)*10
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DPtr(10:N-10,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DPtr2(10:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DPtr3(:N-10,:) /= 0))

            deallocate(my2DPtr)
            deallocate(my2DPtr2)
            deallocate(my2DPtr3)
            test_array_sections_pointer_2D = errors
          END FUNCTION test_array_sections_pointer_2D

          ! Testing pointer array sections 3D
          INTEGER FUNCTION test_array_sections_pointer_3D()
            INTEGER, ALLOCATABLE, DIMENSION(:,:,:) :: my3DPtr
            INTEGER, ALLOCATABLE, DIMENSION(:,:,:) :: my3DPtr2
            INTEGER, ALLOCATABLE, DIMENSION(:,:,:) :: my3DPtr3
            INTEGER, DIMENSION (N,N,N) :: myTmpArray
            INTEGER :: errors, testVal
            errors = 0
            OMPVV_INFOMSG("test array sections pointer 3D")

            ! array allocation
            allocate(my3DPtr(N,N,N))
            allocate(my3DPtr2(N,N,N))
            allocate(my3DPtr3(N,N,N))

            ! array initialization
            my3DPtr(:,:,:) = 10
            my3DPtr2(:,:,:) = 10
            my3DPtr3(:,:,:) = 10
            myTmpArray(:,:,:) = 0

            ! testing map(from:...) with different array sections
            ! 2.10.5 Specs: If a list item is an array section
            ! it must specify contiguous storage.

            DO i = 1,N
              DO j = 1,N
                !$omp target data map(from: my3DPtr(10:N-10, i, j)) &
                !$omp map(from: my3DPtr2(10:, i, j), my3DPtr3(:N-10, i, j)) &
                !$omp map(tofrom: myTmpArray)

                  !$omp target map(alloc: my3DPtr(10:N-10, i, j)) &
                  !$omp map(alloc: my3DPtr2(10:, i, j), my3DPtr3(:N-10, i, j)) &
                  !$omp map(tofrom: myTmpArray)
                    ! This should result in garbage writes to myTmpArray.
                    ! Since the arrays are not copied to, they should not
                    ! have the value of the host.
                    myTmpArray(10:N-10, i, j) = &
                    &    myTmpArray(10:N-10, i, j) + &
                    &    my3DPtr(10:N-10, i, j)
                    myTmpArray(10:, i, j) = &
                    &    myTmpArray(10:, i, j) + &
                    &    my3DPtr2(10:, i, j)
                    myTmpArray(:N-10, i, j) = &
                    &    myTmpArray(:N-10, i, j) + &
                    &    my3DPtr3(:N-10, i, j)

                    ! Asign a value to the region and
                    ! checking for this value on the host
                    my3DPtr(10:N-10, i, j) = 0
                    my3DPtr2(10:, i, j) = 0
                    my3DPtr3(:N-10, i, j) = 0
                  !$omp end target
                !$omp end target data
              END DO
            END DO


            !testing that the array is just copied from and not to
            IF (isOffloading) THEN
              testVal = N*N*(N-19)*10 + &
              &         N*N*(N-9)*10 + &
              &         N*N*(N-10)*10
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DPtr(10:N-10,:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DPtr2(10:,:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DPtr3(:N-10,:,:) /= 0))

            deallocate(my3DPtr)
            deallocate(my3DPtr2)
            deallocate(my3DPtr3)
            test_array_sections_pointer_3D = errors
          END FUNCTION test_array_sections_pointer_3D

          ! Testing array sections 1D
          INTEGER FUNCTION test_array_sections_1D()
            INTEGER, DIMENSION(N) :: my1DArray
            INTEGER, DIMENSION(N) :: my1DArray2
            INTEGER, DIMENSION(N) :: my1DArray3
            INTEGER, DIMENSION(N) :: myTmpArray
            INTEGER :: errors, testVal
            OMPVV_INFOMSG("test array sections 1D")
            errors = 0

            ! array initialization
            my1DArray(:) = 10
            my1DArray2(:) = 10
            my1DArray3(:) = 10
            myTmpArray(:) = 0

            ! testing map(from:...) with different array sections

            !$omp target data map(from: my1DArray(10:N-10)) &
            !$omp map(from: my1DArray2(10:), my1DArray3(:N-10)) &
            !$omp map(tofrom: myTmpArray)

              !$omp target map(alloc: my1DArray(10:N-10)) &
              !$omp map(alloc: my1DArray2(10:), my1DArray3(:N-10)) &
              !$omp map(tofrom: myTmpArray)
                ! This should result in garbage writes to myTmpArray.
                ! Since the arrays are not copied to, they should not
                ! have the value of the host.
                myTmpArray(10:N-10) = &
                &    myTmpArray(10:N-10) + &
                &    my1DArray(10:N-10)
                myTmpArray(10:) = &
                &    myTmpArray(10:) + &
                &    my1DArray2(10:)
                myTmpArray(:N-10) = &
                &    myTmpArray(:N-10) + &
                &    my1DArray3(:N-10)
                ! Asign a value to the region and
                ! checking for this value on the host
                my1DArray(10:N-10) = 0
                my1DArray2(10:) = 0
                my1DArray3(:N-10) = 0
              !$omp end target

            !$omp end target data

            !testing that the array is just copied from and not to
            IF (isOffloading) THEN
              testVal = (N-19)*10 + &
              &         (N-9)*10 + &
              &         (N-10)*10
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DArray(10:N-10) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DArray2(10:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my1DArray3(:N-10) /= 0))

            test_array_sections_1D = errors
          END FUNCTION test_array_sections_1D

          ! Testing array sections 2D
          INTEGER FUNCTION test_array_sections_2D()
            INTEGER, DIMENSION(N,N) :: my2DArray
            INTEGER, DIMENSION(N,N) :: my2DArray2
            INTEGER, DIMENSION(N,N) :: my2DArray3
            INTEGER, DIMENSION(N,N) :: myTmpArray
            INTEGER :: errors, testVal, i
            OMPVV_INFOMSG("test array sections 2D")
            errors = 0

            ! array initialization
            my2DArray(:,:) = 10
            my2DArray2(:,:) = 10
            my2DArray3(:,:) = 10
            myTmpArray(:,:) = 0

            ! testing map(from:...) with different array sections

            DO i = 1,N
              !$omp target data map(from: my2DArray(10:N-10, i)) &
              !$omp map(from: my2DArray2(10:, i), my2DArray3(:N-10, i)) &
              !$omp map(tofrom: myTmpArray)

                !$omp target map(alloc: my2DArray(10:N-10, i)) &
                !$omp map(alloc: my2DArray2(10:, i), my2DArray3(:N-10, i)) &
                !$omp map(tofrom: myTmpArray)
                  ! This should result in garbage writes to myTmpArray.
                  ! Since the arrays are not copied to, they should not
                  ! have the value of the host.
                  myTmpArray(10:N-10, i) = &
                  &    myTmpArray(10:N-10, i) + &
                  &    my2DArray(10:N-10, i)
                  myTmpArray(10:, i) = &
                  &    myTmpArray(10:, i) + &
                  &    my2DArray2(10:, i)
                  myTmpArray(:N-10, i) = &
                  &    myTmpArray(:N-10, i) + &
                  &    my2DArray3(:N-10, i)
                  ! Asign a value to the region and
                  ! checking for this value on the host
                  my2DArray(10:N-10, i) = 0
                  my2DArray2(10:, i) = 0
                  my2DArray3(:N-10, i) = 0
                !$omp end target
              !$omp end target data
            END DO

            !testing that the array is just copied from and not to
            IF (isOffloading) THEN
              testVal = N*(N-19)*10 + &
              &         N*(N-9)*10 + &
              &         N*(N-10)*10
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DArray(10:N-10,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DArray2(10:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my2DArray3(:N-10,:) /= 0))

            test_array_sections_2D = errors
          END FUNCTION test_array_sections_2D

          ! Testing array sections 3D
          INTEGER FUNCTION test_array_sections_3D()
            INTEGER, DIMENSION(N,N,N) :: my3DArray
            INTEGER, DIMENSION(N,N,N) :: my3DArray2
            INTEGER, DIMENSION(N,N,N) :: my3DArray3
            INTEGER, DIMENSION(N,N,N) :: myTmpArray
            INTEGER :: errors, testVal, i
            OMPVV_INFOMSG("test array sections 3D")
            errors = 0

            ! array initialization
            my3DArray(:,:,:) = 10
            my3DArray2(:,:,:) = 10
            my3DArray3(:,:,:) = 10
            myTmpArray(:,:,:) = 0

            ! testing map(from:...) with different array sections
            ! 2.10.5 Specs: If a list item is an array section
            ! it must specify contiguous from.

            DO i = 1,N
              DO j = 1,N
                !$omp target data map(from: my3DArray(10:N-10, i, j)) &
                !$omp map(from: my3DArray2(10:, i, j), my3DArray3(:N-10, i, j)) &
                !$omp map(tofrom: myTmpArray)

                  !$omp target map(alloc: my3DArray(10:N-10, i, j)) &
                  !$omp map(alloc: my3DArray2(10:, i, j), my3DArray3(:N-10, i, j)) &
                  !$omp map(tofrom: myTmpArray)
                    ! This should result in garbage writes to myTmpArray.
                    ! Since the arrays are not copied to, they should not
                    ! have the value of the host.
                    myTmpArray(10:N-10, i, j) = &
                    &    myTmpArray(10:N-10, i, j) + &
                    &    my3DArray(10:N-10, i, j)
                    myTmpArray(10:, i, j) = &
                    &    myTmpArray(10:, i, j) + &
                    &    my3DArray2(10:, i, j)
                    myTmpArray(:N-10, i, j) = &
                    &    myTmpArray(:N-10, i, j) + &
                    &    my3DArray3(:N-10, i, j)
                    ! Asign a value to the region and
                    ! checking for this value on the host
                    my3DArray(10:N-10, i, j) = 0
                    my3DArray2(10:, i, j) = 0
                    my3DArray3(:N-10, i, j) = 0
                  !$omp end target
                !$omp end target data
              END DO
            END DO

            !testing that the array is just copied to and not from
            IF (isOffloading) THEN
              OMPVV_INFOMSG("test array sections pointer 3D")
              testVal = N*N*(N-19)*10 + &
              &         N*N*(N-9)*10 + &
              &         N*N*(N-10)*10
              WRITE(msgHelper,*) "When using map from, the arrays might &
              & have been moved to the deice as well."
              OMPVV_WARNING_IF(SUM(myTmpArray) == testVal, msgHelper)
            END IF

            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DArray(10:N-10,:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DArray2(10:,:,:) /= 0))
            OMPVV_TEST_AND_SET_VERBOSE(errors, ANY(my3DArray3(:N-10,:,:) /= 0))

            test_array_sections_3D = errors
          END FUNCTION test_array_sections_3D
      END PROGRAM
