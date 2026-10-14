; RUN: opt -O2 -mtriple=bpf-pc-linux %s | llvm-dis > %t1
; RUN: llc -o - %t1 | FileCheck %s
;
; A preserve_field_info call whose result is unused is not the base of any
; access chain, so it is never relocated. It must be removed rather than
; turned into a GEP like a leftover preserve_struct_access_index call.
;
; Source:
;   struct s { int a; int b; } __attribute__((preserve_access_index));
;   int f(struct s *p)
;   {
;     (void)__builtin_preserve_field_info(p->b, 0);
;     return 0;
;   }
; Compilation flag:
;   clang -target bpf -O2 -S -emit-llvm -g -Xclang -disable-llvm-passes test.c


%struct.s = type { i32, i32 }

; Function Attrs: nounwind
define dso_local i32 @f(ptr noundef %0) #0 !dbg !11 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !22
    #dbg_declare(ptr %2, !21, !DIExpression(), !25)
  %3 = load ptr, ptr %2, align 8, !dbg !26, !tbaa !22
  %4 = call ptr @llvm.preserve.struct.access.index.p0.p0(ptr elementtype(%struct.s) %3, i32 1, i32 1), !dbg !27, !llvm.preserve.access.index !16
  %5 = call i32 @llvm.bpf.preserve.field.info.p0(ptr %4, i64 0), !dbg !28
  ret i32 0, !dbg !29
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.preserve.struct.access.index.p0.p0(ptr, i32 immarg, i32 immarg) #1

; Function Attrs: nounwind memory(none)
declare i32 @llvm.bpf.preserve.field.info.p0(ptr, i64 immarg) #2

attributes #0 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind memory(none) }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5}
!llvm.ident = !{!6}
!llvm.errno.tbaa = !{!7}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "dead_fi.c", directory: "/tmp/claude-1000/-home-prozak-sources-heimdall-experiment/50548d0c-a69e-4cf2-988f-1bc1b90944b1/scratchpad", checksumkind: CSK_MD5, checksum: "cfac3f89a4d7e04756fe38985c80b88c")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 2, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !20, keyInstructions: true)
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !15}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "s", file: !1, line: 1, size: 64, elements: !17)
!17 = !{!18, !19}
!18 = !DIDerivedType(tag: DW_TAG_member, name: "a", scope: !16, file: !1, line: 1, baseType: !14, size: 32)
!19 = !DIDerivedType(tag: DW_TAG_member, name: "b", scope: !16, file: !1, line: 1, baseType: !14, size: 32, offset: 32)
!20 = !{!21}
!21 = !DILocalVariable(name: "p", arg: 1, scope: !11, file: !1, line: 2, type: !15)
!22 = !{!23, !23, i64 0}
!23 = !{!"p1 _ZTS1s", !24, i64 0}
!24 = !{!"any pointer", !9, i64 0}
!25 = !DILocation(line: 2, column: 17, scope: !11)
!26 = !DILocation(line: 4, column: 38, scope: !11)
!27 = !DILocation(line: 4, column: 41, scope: !11)
!28 = !DILocation(line: 4, column: 8, scope: !11)
!29 = !DILocation(line: 5, column: 2, scope: !11, atomGroup: 1, atomRank: 1)

; CHECK-LABEL: f:
; CHECK:       w0 = 0
; CHECK-NEXT:  exit
; CHECK-NOT:   FieldReloc
