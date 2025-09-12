//
//  RibbonBar.h
//  RibbonBar
//
//  Created by bedtime on 5/17/25.
//

#ifndef RibbonBar_h
#define RibbonBar_h

#import <Foundation/Foundation.h>

extern void * gHook;

typedef void (*GumInterceptorReplaceFuncType)(void *, void *, void *, void *, void * *);
typedef void (*GumInterceptorBeginTransactionFuncType)(void *);
typedef void (*GumInterceptorEndTransactionFuncType)(void *);

extern GumInterceptorReplaceFuncType GumInterceptorReplaceFunc;
extern GumInterceptorBeginTransactionFuncType GumInterceptorBeginTransactionFunc;
extern GumInterceptorEndTransactionFuncType GumInterceptorEndTransactionFunc;

#endif /* RibbonBar_h */
