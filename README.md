![Push Validation](https://github.com/scavanger/libusb_android/actions/workflows/dart.yml/badge.svg)
# Libusb android

A ffi wrapper around `libusb` for Android.
Useful if you need more advanced USB functions than the native Java/Kotlin API in Android offers.

Credits:
Dart wrapper via `libusb` [https://github.com/woodemi/libusb.dart](https://github.com/woodemi/libusb.dart)

> [!IMPORTANT]
> libusb has the restriction on (unrooted) Android that no USB devices can be listed and found.
> Functions like `libusb_get_list_devices` will not find any devices. 
> See [libusb android readme](https://github.com/libusb/libusb/blob/master/android/README)

The devices must be listed and opened via the native Java/Kotlin API in order to obtain a native handle with which libusb can continue to work. 
You can use (libusb_android_helper)[https://pub.dev/packages/libusb_android_helper] for this 

## Getting Started

Add a dependency to your pubspec.yaml

```dart
dependencies:
	libusb_android: ^1.0.0
```

include the libusb_android_helper package at the top of your dart file.

```dart
import 'package:libusb_android_/libusb_android.dart';
```

If libusb_android_helper is not used, you have to write custom platform-specific code with Java or Kotlin:

Obtain USB permissions over the android.hardware.usb.UsbManager class
```java
usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();
for (UsbDevice usbDevice : deviceList.values()) {
    usbManager.requestPermission(usbDevice, mPermissionIntent);
}
```

Get the native FileDescriptor of the UsbDevice and transfer it to libusb_android
```java
UsbDeviceConnection usbDeviceConnection = usbManager.openDevice(device);
int fileDescriptor = usbDeviceConnection.getFileDescriptor();
```

For the use of `libusb_android_helper` see the readme there.

Initialize libusb:
```dart
const String _libName = 'libusb_android';
final DynamicLibrary _dynamicLibrary = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();
final LibusbAndroidBindings _bindings = LibusbAndroidBindings(_dynamicLibrary);
final Pointer<Pointer<libusb_context>> _libusbContext = calloc<Pointer<libusb_context>>();
// ...
void initLibusb() {
  int result = _bindings.libusb_set_option(_libusbContext.value, libusb_option.LIBUSB_OPTION_NO_DEVICE_DISCOVERY);
  if (result < 0) {
      throw StateError("Unable to set libusb option");
  }
  result =_bindings.libusb_init(_libusbContext);
  if (result < 0) {
      throw StateError("Unable to init libusb");
  }
}
// ...
calloc.free(_libusbContext);
```

Get libusb_device_handle:
```dart
Pointer<Pointer<libusb_device_handle>> deviceHandle = calloc<Pointer<libusb_device_handle>>();
int result = _bindings.libusb_wrap_sys_device(_libusbContext.value, handle_from_native_android_api, deviceHandle);
if (result < 0) {
    throw StateError("Unable to set device handle");
}
Pointer<libusb_device> device = _bindings.libusb_get_device(deviceHandle.value);
// ...
calloc.free(deviceHandle);
```

Now the libusb functions can be used normally.
