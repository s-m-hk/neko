/*
 Copyright (c) 2021-2023, The Neko Authors
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

   * Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the following
     disclaimer in the documentation and/or other materials provided
     with the distribution.

   * Neither the name of the authors nor the names of its
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#include <device/device_config.h>
#include <device/cuda/check.h>
#include "tensor_kernel.h"
#include <stdio.h>

#define max(a,b) \
  ({ __typeof__ (a) _a = (a);  \
     __typeof__ (b) _b = (b);   \
     _a > _b ? _a : _b; })


extern "C" {

  /** Fortran wrapper for tnsr3d **/
  void cuda_tnsr3d(void *v, int *nv, void *u, int *nu,
		   void *A, void *Bt, void *Ct, int *nel) {
    const dim3 nthrds(1024, 1, 1);
    const dim3 nblcks(*nel, 1, 1);
    const cudaStream_t stream = (cudaStream_t) glb_cmd_queue;

    int n = max(*nu,*nv);
#define CASE(N)                                                              \
    case N:                                                                  \
    tnsr3d_kernel<real, N>                                                   \
      <<<nblcks, nthrds, 0, stream>>>((real *) v, *nv,                       \
                                      (real *) u, *nu,                       \
                                      (real *) A, (real *) Bt, (real *) Ct); \
    CUDA_CHECK(cudaGetLastError());                                          \
    break

#define CASE_LARGE(N)                                                        \
    case N:                                                                  \
    tnsr3d_kernel_large<real, N>                                             \
      <<<nblcks, nthrds, 0, stream>>>((real *) v, *nv,                       \
                                      (real *) u, *nu,                       \
                                      (real *) A, (real *) Bt, (real *) Ct); \
    CUDA_CHECK(cudaGetLastError());                                          \
    break

    switch(n) {
      CASE(2);
      CASE(3);
      CASE(4);
      CASE(5);
      CASE(6);
      CASE(7);
      CASE(8); 
      CASE(9);
      CASE(10);
      CASE(11);
      CASE(12);
      CASE(13);
      CASE(14);
      CASE_LARGE(15);
      CASE_LARGE(16);
    default:
      {
        fprintf(stderr, __FILE__ ": size not supported: %d\n", n);
        exit(1);
      }
    }    
  }
}
