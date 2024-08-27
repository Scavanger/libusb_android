import 'dart:ffi';

final class Timeval extends Struct {
  @Long()
  external int tv_sec;

  @Susecond()
  external int tv_usec;
}

@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidRiscv64: Int64(),
  Abi.androidX64: Int64(),
})
base class Susecond extends AbiSpecificInteger {
  const Susecond();
}

@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidRiscv64: Int64(),
  Abi.androidX64: Int64(),
})
final class Ssize extends AbiSpecificInteger {
  const Ssize();
}
