/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
  *
 * Written (W) 2011 Baozeng Ding
  *  
 */

%pragma(java) jniclassimports=%{
import org.jblas.*;
%}
%typemap(javaimports) SWIGTYPE%{
import org.jblas.*;
%}
/* One dimensional input/output arrays */

%define TYPEMAP_SGVECTOR(SGTYPE, JTYPE, JAVATYPE, JNITYPE)

%typemap(jni) shogun::SGVector<SGTYPE>		%{JNITYPE##Array%}
%typemap(jtype) shogun::SGVector<SGTYPE>		%{JTYPE[]%}
%typemap(jstype) shogun::SGVector<SGTYPE> 	%{JTYPE[]%}

%typemap(in) shogun::SGVector<SGTYPE> (JNITYPE *jarr) {
	int32_t i, len;
	SGTYPE *array;
	if (!$input) {
		SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException, "null array");
		return $null;	
	}
	
	len = JCALL1(GetArrayLength, jenv, $input);
	jarr = JCALL2(Get##JAVATYPE##ArrayElements, jenv, $input, 0);
	if (!jarr)
		return $null;
	
	array = new SGTYPE[len];
	if (!array) {
		SWIG_JavaThrowException(jenv, SWIG_JavaOutOfMemoryError, "array memory allocation failed");
		return $null;
	}
	for (i = 0; i < len; i++) {
		array[i] = jarr[i];	
	}
	
	$1 = shogun::SGVector<SGTYPE>((SGTYPE *)array, len);
}

%typemap(out) shogun::SGVector<SGTYPE> {
	JNITYPE *arr;
	int32_t i;
	JNITYPE##Array res = JCALL1(New##JAVATYPE##Array, jenv, $1.length);
	if (!res)
		return NULL;
	
	arr = JCALL2(Get##JAVATYPE##ArrayElements, jenv, res, 0);
	if (!arr)
		return NULL;
	
	for (i=0; i < $1.length; i++)
		arr[i] = (JNITYPE)$1.vector[i];
	
	JCALL3(Release##JAVATYPE##ArrayElements, jenv, res, arr, 0);	
	$result = res;
}

%typemap(javain) shogun::SGVector<SGTYPE> "$javainput"
%typemap(javaout) shogun::SGVector<SGTYPE> {
	return $jnicall;
}

%enddef

/* Define concrete examples of the TYPEMAP_SGVECTOR macros */
TYPEMAP_SGVECTOR(bool, boolean, Boolean, jboolean)
TYPEMAP_SGVECTOR(char, byte, Byte, jbyte)
TYPEMAP_SGVECTOR(uint8_t, byte, Byte, jbyte)
TYPEMAP_SGVECTOR(int16_t, short, Short, jshort)
TYPEMAP_SGVECTOR(uint16_t, int, Int, jint)
TYPEMAP_SGVECTOR(int32_t, int, Int, jint)
TYPEMAP_SGVECTOR(uint32_t, long, Long, jlong)
TYPEMAP_SGVECTOR(int64_t, int, Int, jint)
TYPEMAP_SGVECTOR(uint64_t, long, Long, jlong)
TYPEMAP_SGVECTOR(long long, long, Long, jlong)
TYPEMAP_SGVECTOR(float32_t, float, Float, jfloat)
TYPEMAP_SGVECTOR(float64_t, double, Double, jdouble)

#undef TYPEMAP_SGVECTOR

/* Two dimensional input/output arrays */
%define TYPEMAP_SGMATRIX(SGTYPE, JTYPE, JAVATYPE, JNITYPE, TOARRAY, CLASSDESC, CONSTRUCTOR)

%typemap(jni) shogun::SGMatrix<SGTYPE>		%{jobject%}
%typemap(jtype) shogun::SGMatrix<SGTYPE>		%{##JAVATYPE##Matrix%}
%typemap(jstype) shogun::SGMatrix<SGTYPE> 	%{##JAVATYPE##Matrix%}

%typemap(in) shogun::SGMatrix<SGTYPE>
{
	jclass cls;
	jmethodID mid;
	SGTYPE *array;
	##JNITYPE##Array jarr;
	JNITYPE *carr;
	int32_t i,len, rows, cols;
	
	if (!$input) {
		SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException, "null array");
		return $null;	
	}
	
	cls = JCALL1(GetObjectClass, jenv, $input);
	if (!cls)
		return $null;	

	mid = JCALL3(GetMethodID, jenv, cls, "toArray", TOARRAY);
	if (!mid)
		return $null;
	
	jarr = (##JNITYPE##Array)JCALL2(CallObjectMethod, jenv, $input, mid);
	carr = JCALL2(Get##JAVATYPE##ArrayElements, jenv, jarr, 0);
	len = JCALL1(GetArrayLength, jenv, jarr);
	array = new SGTYPE[len];
	for (i = 0; i < len; i++) {
		array[i] = (SGTYPE)carr[i];
	}
	
	JCALL3(Release##JAVATYPE##ArrayElements, jenv, jarr, carr, 0);	

	mid = JCALL3(GetMethodID, jenv, cls, "getRows", "()I");
	if (!mid) 
		return $null;
	
	rows = (int32_t)JCALL2(CallIntMethod, jenv, $input, mid);
	
	mid = JCALL3(GetMethodID, jenv, cls, "getColumns", "()I");
	if (!mid)
		return $null;
	
	cols = (int32_t)JCALL2(CallIntMethod, jenv, $input, mid);
	
    $1 = shogun::SGMatrix<SGTYPE>((SGTYPE*)array, rows, cols);
}

%typemap(out) shogun::SGMatrix<SGTYPE>
{
	int32_t rows = $1.num_rows;
	int32_t cols = $1.num_cols;
	int32_t len = rows * cols;
	JNITYPE arr[len];
	jobject res;
	int32_t i;
	
	jclass cls;
	jmethodID mid;
		
	cls = JCALL1(FindClass, jenv, CLASSDESC);
	if (!cls)
		return $null;
	
	mid = JCALL3(GetMethodID, jenv, cls, "<init>", CONSTRUCTOR);
	if (!mid)
		return $null;	

	##JNITYPE##Array jarr = (##JNITYPE##Array)JCALL1(New##JAVATYPE##Array, jenv, len);
	if (!jarr)
		return $null;

	for (i = 0; i < len; i++) {
		arr[i] = (JNITYPE)$1.matrix[i];
	}
	JCALL4(Set##JAVATYPE##ArrayRegion, jenv, jarr, 0, len, arr);
	
	res = JCALL5(NewObject, jenv, cls, mid, rows, cols, jarr);
	$result = (jobject)res;
}

%typemap(javain) shogun::SGMatrix<SGTYPE> "$javainput"
%typemap(javaout) shogun::SGMatrix<SGTYPE> {
	return $jnicall;
}

%enddef

/*Define concrete examples of the TYPEMAP_SGMATRIX macros */
TYPEMAP_SGMATRIX(float32_t, float, Float, jfloat, "()[F", "org/jblas/FloatMatrix","(II[F)V")
TYPEMAP_SGMATRIX(float64_t, double, Double, jdouble, "()[D", "org/jblas/DoubleMatrix", "(II[D)V")

#undef TYPEMAP_SGMATRIX

