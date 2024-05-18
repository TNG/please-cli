#!/usr/bin/env bats

load $BATS_TEST_DIRNAME/../please.sh

@test "join elements with a comma" {
  result=$(join_by ',' 'a' 'b' 'c')
  [ "$result" == "a,b,c" ]
}

@test "join elements with a semicolon" {
  result=$(join_by ';' '1' '2' '3')
  [ "$result" == "1;2;3" ]
}

@test "join with a space as delimiter" {
  result=$(join_by ' ' 'x' 'y' 'z')
  [ "$result" == "x y z" ]
}

@test "join with an empty delimiter" {
  result=$(join_by '' '1' '2' '3')
  [ "$result" == "123" ]
}

@test "no delimiter provided should return the first element" {
  result=$(join_by '' 'single')
  [ "$result" == "single" ]
}

@test "join using array with no elements" {
  qaMessages=()

  result=$(join_by , "${qaMessages[@]}")
  [ "$result" == "" ]
}

@test "join using array with one element" {
  qaMessages=("a")

  result=$(join_by , "${qaMessages[@]}")
  [ "$result" == "a" ]
}

@test "join using array with two elements" {
  qaMessages=("a" "b")

  result=$(join_by , "${qaMessages[@]}")
  [ "$result" == "a,b" ]
}