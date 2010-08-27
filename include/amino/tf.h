/* -*- mode: C; c-basic-offset: 4  -*- */
/* ex: set shiftwidth=4 expandtab: */
/*
 * Copyright (c) 2010, Georgia Tech Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *     * Redistributions of source code must retain the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the Georgia Tech Research Corporation nor
 *       the names of its contributors may be used to endorse or
 *       promote products derived from this software without specific
 *       prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GEORGIA TECH RESEARCH CORPORATION ''AS
 * IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GEORGIA
 * TECH RESEARCH CORPORATION BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef AMINO_TF_H
#define AMINO_TF_H

#define AA_TF_EPSILON .0001

#define AA_TF_QUAT_IDENT ( (double[4]){0,0,0,1} )
#define AA_TF_AXANG_IDENT ( (double[4]){0,0,0,0} )
#define AA_TF_ROTVEC_IDENT ( (double[3]){0,0,0} )

/**************/
/* Transforms */
/**************/

AA_API void aa_tf_12( const double T[12], const double p0[3], double p1[3] );
//AA_API void aa_tf_16( const double T[16], const double p0[4], double p1[4] );
AA_API void aa_tf_93( const double R[9], const double v[3], const double p0[3], double p1[4] );
AA_API void aa_tf_q3( const double quat[4], const double v[3], const double p0[3], double p1[4] );

AA_API void aa_tf_12inv( double T[12] );
//AA_API void aa_tf_16inv( double T[16] );
AA_API void aa_tf_93inv( double R[9], double v[3] );
AA_API void aa_tf_q3inv( double q[4], double v[3] );

AA_API void aa_tf_12chain( const double T1[12], const double T2[12], double T[12] );
//AA_API void aa_tf_16chain( double T1[16], const double T2[16], double T[16] );
AA_API void aa_tf_93chain( const double R0[9], const double v0[3],
                             const double R1[9], const double v1[3],
                             double R[9], double v[3] );
AA_API void aa_tf_q3chain( const double q0[4], const double v0[3],
                             const double q1[4], const double v1[3],
                             const double q[4], const double v[3] );

/** Normalize Quaternion */
AA_API void aa_tf_qnormalize( double q[4] );

/** Quaternion conjugate */
AA_API void aa_tf_qconj( const double q[4], double r[4] );

/** Quaternion inverse */
AA_API void aa_tf_qinv( const double q[4], double r[4] );

/** Quaternion addition. */
AA_API void aa_tf_qadd( const double a[4], const double b[4], double c[4] );

/** Quaternion subtraction. */
AA_API void aa_tf_qsub( const double a[4], const double b[4], double c[4] );

/** Quaternion multiplication. */
AA_API void aa_tf_qmul( const double a[4], const double b[4], double c[4] );

/** Quaternion point rotation.
 *
 * This function is generated by Maxima.
 */
AA_API void aa_tf_qrot_( const double q[4], const double v[3], double p[3] );

/** Quaternion point rotation. */
static inline void aa_tf_qrot( const double q[4], const double v[3], double p[3] ) {
    aa_tf_qrot_(q,v,p);
}
/** Relative orientation.
    \f[ q_{\rm rel} = q_1 q_2^{-1} \f]
 */
AA_API void aa_tf_qrel(const double q1[4], const double q2[4], double q_rel[4]);

/** Quaternion SLERP. */
AA_API void aa_tf_qslerp( double t, const double a[4], const double b[4], double c[4] );

/** Quaternion to axis-angle. */
AA_API void aa_tf_quat2axang( const double q[4], double axang[4] );


/** axis-angle to quaternion. */
AA_API void aa_tf_axang2quat( const double axang[4], double q[4] );

AA_API void aa_tf_axang_make( double x, double y, double z, double theta, double axang[4] );

/** Scales angle by k * 2 * pi.
 */
AA_API void aa_tf_axang_permute( const double rv[4], int k, double rv_p[4] );

AA_API void aa_tf_rotvec_permute( const double rv[3], int k, double rv_p[3] );

/** Scales rv by multiple of 2pi to minimized SSD with rv_near.
 */
AA_API void aa_tf_rotvec_near( const double rv[3], const double rv_near[3],
                               double rv_p[3] );

AA_API void aa_tf_axang2rotvec( const double axang[4], double rotvec[3] );

AA_API void aa_tf_rotvec2axang( const double rotvec[3], double axang[4] );

AA_API void aa_tf_rotvec2quat( const double rotvec[3], double q[4] );
AA_API void aa_tf_quat2rotvec( const double q[4], double rotvec[3] );

AA_API void aa_tf_quat2rotvec_near( const double q[4], const double rv_near[3],
                                    double rotvec[3] );

AA_API void aa_tf_quat2rotmat( const double quat[4], double rotmat[9] );
AA_API void aa_tf_rotmat2quat( const double rotmat[9], double quat[4] );

AA_API void aa_tf_rotmat2axang( const double R[9], double ra[4] );
AA_API void aa_tf_rotmat2rotvec( const double R[9], double rv[3] );

AA_API void aa_tf_axang2rotmat( const double ra[4], double R[9] );
AA_API void aa_tf_rotvec2rotmat( const double rv[3], double R[9] );

/* AA_API void aa_tf_tfv2tfq( const double vrv[6],  */
/*                            double x[3], double quat[4] ); */
/* AA_API void aa_tf_tfq2tfv( const double x[3], const double quat[4],  */
/*                            double vrv[6] ); */

/// tests if R is a rotation matrix
AA_API int aa_tf_isrotmat( const double R[9] );

#endif //AMINO_TF_H
