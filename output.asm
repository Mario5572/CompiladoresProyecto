.data
_c : .word 0
$str0 : .asciiz "holal\n"
.text
.globl main
main:
li $t0, 0
sw $t0, _c
$l1:
la $a0, $str0
li $v0, 4
syscall
lw $t0, _c
bnez $t0, $l1
li $v0, 10
syscall