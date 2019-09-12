; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt %s -instsimplify -S | FileCheck %s

; Here we subtract two values, check that subtraction did not overflow AND
; that the result is non-zero. This can be simplified just to a comparison
; between the base and offset.

declare void @use8(i8)
declare void @use64(i64)
declare void @use1(i1)

declare void @llvm.assume(i1)

; If we are checking that we either did not get null or got no overflow,
; this is tautological and is always true.

define i1 @t1(i8 %base, i8 %offset) {
; CHECK-LABEL: @t1(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[NO_UNDERFLOW:%.*]] = icmp uge i8 [[BASE]], [[OFFSET]]
; CHECK-NEXT:    call void @use1(i1 [[NO_UNDERFLOW]])
; CHECK-NEXT:    [[NOT_NULL:%.*]] = icmp ne i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NOT_NULL]])
; CHECK-NEXT:    [[R:%.*]] = or i1 [[NOT_NULL]], [[NO_UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %no_underflow = icmp uge i8 %base, %offset
  call void @use1(i1 %no_underflow)
  %not_null = icmp ne i8 %adjusted, 0
  call void @use1(i1 %not_null)
  %r = or i1 %not_null, %no_underflow
  ret i1 %r
}
define i1 @t1_strict_bad(i8 %base, i8 %offset) {
; CHECK-LABEL: @t1_strict_bad(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[NO_UNDERFLOW:%.*]] = icmp ugt i8 [[BASE]], [[OFFSET]]
; CHECK-NEXT:    call void @use1(i1 [[NO_UNDERFLOW]])
; CHECK-NEXT:    [[NOT_NULL:%.*]] = icmp ne i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NOT_NULL]])
; CHECK-NEXT:    [[R:%.*]] = or i1 [[NOT_NULL]], [[NO_UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %no_underflow = icmp ugt i8 %base, %offset ; but not for non-strict predicate
  call void @use1(i1 %no_underflow)
  %not_null = icmp ne i8 %adjusted, 0
  call void @use1(i1 %not_null)
  %r = or i1 %not_null, %no_underflow
  ret i1 %r
}
define i1 @t1_commutativity(i8 %base, i8 %offset) {
; CHECK-LABEL: @t1_commutativity(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[NO_UNDERFLOW:%.*]] = icmp ule i8 [[OFFSET]], [[BASE]]
; CHECK-NEXT:    call void @use1(i1 [[NO_UNDERFLOW]])
; CHECK-NEXT:    [[NOT_NULL:%.*]] = icmp ne i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NOT_NULL]])
; CHECK-NEXT:    [[R:%.*]] = or i1 [[NOT_NULL]], [[NO_UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %no_underflow = icmp ule i8 %offset, %base
  call void @use1(i1 %no_underflow)
  %not_null = icmp ne i8 %adjusted, 0
  call void @use1(i1 %not_null)
  %r = or i1 %not_null, %no_underflow
  ret i1 %r
}

; Likewise, if we are checking that we both got null and overflow happened,
; it makes no sense and is always false.

define i1 @t2(i8 %base, i8 %offset) {
; CHECK-LABEL: @t2(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[UNDERFLOW:%.*]] = icmp ult i8 [[BASE]], [[OFFSET]]
; CHECK-NEXT:    call void @use1(i1 [[UNDERFLOW]])
; CHECK-NEXT:    [[NULL:%.*]] = icmp eq i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NULL]])
; CHECK-NEXT:    [[R:%.*]] = and i1 [[NULL]], [[UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %underflow = icmp ult i8 %base, %offset
  call void @use1(i1 %underflow)
  %null = icmp eq i8 %adjusted, 0
  call void @use1(i1 %null)
  %r = and i1 %null, %underflow
  ret i1 %r
}
define i1 @t2_nonstrict_bad(i8 %base, i8 %offset) {
; CHECK-LABEL: @t2_nonstrict_bad(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[UNDERFLOW:%.*]] = icmp uge i8 [[ADJUSTED]], [[BASE]]
; CHECK-NEXT:    call void @use1(i1 [[UNDERFLOW]])
; CHECK-NEXT:    [[NULL:%.*]] = icmp eq i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NULL]])
; CHECK-NEXT:    [[R:%.*]] = and i1 [[NULL]], [[UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %underflow = icmp uge i8 %adjusted, %base ; but not for non-strict predicate
  call void @use1(i1 %underflow)
  %null = icmp eq i8 %adjusted, 0
  call void @use1(i1 %null)
  %r = and i1 %null, %underflow
  ret i1 %r
}
define i1 @t2_commutativity(i8 %base, i8 %offset) {
; CHECK-LABEL: @t2_commutativity(
; CHECK-NEXT:    [[ADJUSTED:%.*]] = sub i8 [[BASE:%.*]], [[OFFSET:%.*]]
; CHECK-NEXT:    call void @use8(i8 [[ADJUSTED]])
; CHECK-NEXT:    [[UNDERFLOW:%.*]] = icmp ugt i8 [[OFFSET]], [[BASE]]
; CHECK-NEXT:    call void @use1(i1 [[UNDERFLOW]])
; CHECK-NEXT:    [[NULL:%.*]] = icmp eq i8 [[ADJUSTED]], 0
; CHECK-NEXT:    call void @use1(i1 [[NULL]])
; CHECK-NEXT:    [[R:%.*]] = and i1 [[NULL]], [[UNDERFLOW]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %adjusted = sub i8 %base, %offset
  call void @use8(i8 %adjusted)
  %underflow = icmp ugt i8 %offset, %base
  call void @use1(i1 %underflow)
  %null = icmp eq i8 %adjusted, 0
  call void @use1(i1 %null)
  %r = and i1 %null, %underflow
  ret i1 %r
}
