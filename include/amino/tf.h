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

/** \file tf.h */
#ifndef AMINO_TF_H
#define AMINO_TF_H


/*********/
/* Types */
/*********/


/// A rotation matrix, column major
typedef double[9] aa_tf_rotmat_t;

/// A quaternion, x,y,z,w order
typedef double[4] aa_tf_quat_t;

/** A transformation matrix.
 *  The first 9 elements are a column major rotation matrix.
 *  The last 3 elements are the origin vector.
 */
typedef double[12] aa_tf_t;

/// a small number
#define AA_TF_EPSILON .0001

/// Identity transform
#define AA_TF_IDENT AA_FAR(1,0,0, 0,1,0, 0,0,1, 0,0,0)
/// Identity rotation matrix
#define AA_TF_ROTMAT_IDENT AA_FAR(1,0,0, 0,1,0, 0,0,1)
/// Identity quaternion
#define AA_TF_QUAT_IDENT ( (double[4]){0,0,0,1} )
/// Identity axis-angle
#define AA_TF_AXANG_IDENT ( (double[4]){0,0,0,0} )
/// Identity Rotation Vector
#define AA_TF_ROTVEC_IDENT ( (double[3]){0,0,0} )

/**************/
/* Transforms */
/**************/

/// apply a euclidean transform
AA_API void aa_tf_12( const double T[12], const double p0[3], double p1[3] );
/// apply a euclidean transform
AA_API void aa_tf_93( const double R[9], const double v[3], const double p0[3], double p1[4] );
/// apply a euclidean transform
AA_API void aa_tf_q3( const double quat[4], const double v[3], const double p0[3], double p1[4] );

/// invert transform
AA_API void aa_tf_12inv( const double T[12], double Ti[12] );
/// invert transform
AA_API void aa_tf_93inv( const double R[9], const double v[3],
                         double Ri[9], double vi[3] );
/// invert transform
AA_API void aa_tf_q3inv( double q[4], double v[3] );

/// chain two transforms
AA_API void aa_tf_12chain( const double T1[12], const double T2[12], double T[12] );
/// chain two transforms
AA_API void aa_tf_93chain( const double R0[9], const double v0[3],
                           const double R1[9], const double v1[3],
                           double R[9], double v[3] );
/// chain two transforms
AA_API void aa_tf_q3chain( const double q0[4], const double v0[3],
                           const double q1[4], const double v1[3],
                           const double q[4], const double v[3] );

/// relative transform
AA_API void aa_tf_93rel( const double R1[9], const double v1[3],
                         const double R2[9], const double v2[3],
                         double Rrel[9], double vrel[3] );

/// relative transform
AA_API void aa_tf_12rel( const double T1[12], const double T2[12], double Trel[12] );


/// tests if R is a rotation matrix
AA_API int aa_tf_isrotmat( const double R[9] );

/***************/
/* Quaternions */
/***************/

/** Normalize Quaternion.
 * \f[ \bf{q} \leftarrow \frac{\bf q}{\Arrowvert {\bf q} \Arrowvert} \f]
 */
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

/*********/
/* Axang */
/*********/


/// copy x,y,z,theta into axang
AA_API void aa_tf_axang_make( double x, double y, double z, double theta, double axang[4] );

/** Scales angle by k * 2 * pi.
 */
AA_API void aa_tf_axang_permute( const double rv[4], int k, double rv_p[4] );

/// find alternate equivalent representations of rv
AA_API void aa_tf_rotvec_permute( const double rv[3], int k, double rv_p[3] );

/** Scales rv by multiple of 2pi to minimized SSD with rv_near.
 */
AA_API void aa_tf_rotvec_near( const double rv[3], const double rv_near[3],
                               double rv_p[3] );

/***************/
/* Conversions */
/***************/

/** Quaternion to axis-angle. */
AA_API void aa_tf_quat2axang( const double q[4], double axang[4] );


/** axis-angle to quaternion. */
AA_API void aa_tf_axang2quat( const double axang[4], double q[4] );



/// convert axis-angle to rotation vector
AA_API void aa_tf_axang2rotvec( const double axang[4], double rotvec[3] );

/// convert rotation vector to axis-angle
AA_API void aa_tf_rotvec2axang( const double rotvec[3], double axang[4] );

/// covert rotation vector to quaternion
AA_API void aa_tf_rotvec2quat( const double rotvec[3], double q[4] );
/// covert quaternion to rotation vector
AA_API void aa_tf_quat2rotvec( const double q[4], double rotvec[3] );


/// covert quaternion to rotation vector minimizing distance from rv_near
AA_API void aa_tf_quat2rotvec_near( const double q[4], const double rv_near[3],
                                    double rotvec[3] );

/// convert quaternion to rotation matrix
AA_API void aa_tf_quat2rotmat( const double quat[4], double rotmat[9] );
/// convert rotation matrix to quaternion
AA_API void aa_tf_rotmat2quat( const double rotmat[9], double quat[4] );

/// convert rotation matrix to axis angle
AA_API void aa_tf_rotmat2axang( const double R[9], double ra[4] );
/// convert axis rotation matrix to rotation vector
AA_API void aa_tf_rotmat2rotvec( const double R[9], double rv[3] );

/// convert axis angle to rotation matrix
AA_API void aa_tf_axang2rotmat( const double ra[4], double R[9] );
/// convert rotatoin vector to rotation matrix
AA_API void aa_tf_rotvec2rotmat( const double rv[3], double R[9] );

/* AA_API void aa_tf_tfv2tfq( const double vrv[6],  */
/*                            double x[3], double quat[4] ); */
/* AA_API void aa_tf_tfq2tfv( const double x[3], const double quat[4],  */
/*                            double vrv[6] ); */

/** Convert ZYX Euler Angles to Rotation Matrix */
AA_API void aa_tf_eulerzyx2rotmat( const double e[3], double R[9] );
/** Convert Rotation Matrix to ZYX Euler Angles */
AA_API void aa_tf_rotmat2eulerzyx( const double R[9], double e[3] );
#endif //AMINO_TF_H