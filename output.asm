.data
_a : .word 0
_b : .word 0
$str0 : .asciiz "hola\n"
$str1 : .asciiz "Quee\n"
$str2 : .asciiz "si funciona\n"
.text
.globl main
main:
li $t0, 2
sw $t0, _b
lw $t0, _b
li $t1, 2
sub $t0, $t0, $t1
beqz $t0, $l2
la $a0, $str0
li $v0, 4
syscall
j $l3
$l2:
li $t1, 6
sw $t1, _b
la $a0, $str1
li $v0, 4
syscall
lw $t1, _b
beqz $t1, $l1
la $a0, $str2
li $v0, 4
syscall
$l1:
$l3:
li $v0, 10
syscall