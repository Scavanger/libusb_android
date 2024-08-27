import 'dart:ffi';
import 'dart:io';
import 'dart:async';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:libusb_android/libusb_android.dart';
import 'package:libusb_android_helper/libusb_android_helper.dart';

const String _libName = 'libusb_android';
final DynamicLibrary _dynamicLibrary = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();

final LibusbAndroidBindings _bindings = LibusbAndroidBindings(_dynamicLibrary);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const int libusbStringDescriptorMaxLength = 255;
  String _message = "";
  UsbDevice? _device;
  final Map<String, String> _deviceInfo = {};
  final Pointer<Pointer<libusb_context>> _libusbContext = calloc<Pointer<libusb_context>>();

  @override
  void dispose() {
    cleanupLibusb();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    String msg = "";
    try {
      initLibusb();
      checkUsbDevices();
      LibusbAndroidHelper.usbEventStream?.listen((event) async {
        try {
          if (event.action == UsbAction.usbDeviceAttached) {  
            _device = event.device;
            try {
              await _requestPermissionAndOpenDevice();
              msg = getDeviceMessage();
            } catch (e) {
              msg = "Error: $e";
            }
          } else if (event.action == UsbAction.usbDeviceDetached) {
            _device = null;
            msg = "USB device disconnected";
          }
        } catch (e) {
          _device = null;
          msg = "Error: $e";
        }
        if (mounted) {
          setState(() => _message = msg);
        }
      });
    } catch (e) {
      msg = "Error: $e";
    }
  }

  Future<List<UsbDevice>> _getUsbDevices() async {
    List<UsbDevice>? devices = await LibusbAndroidHelper.listDevices();
    if (devices != null) {
      return devices;
    } else {
      return List<UsbDevice>.empty();
    }
  }

  Future<void> _requestPermissionAndOpenDevice() async {
    if (_device == null) {
      return;
    }
    if (!(await _device!.hasPermission())){
      await _device!.requestPermission();
    }
    if (await _device!.open()) {
      Pointer<Pointer<libusb_device_handle>> deviceHandle = calloc<Pointer<libusb_device_handle>>();
      Pointer<libusb_device_descriptor> deviceDescriptor = calloc<libusb_device_descriptor>();
      Pointer<Utf8> manufacturerStringPtr = calloc<UnsignedChar>(libusbStringDescriptorMaxLength).cast();
      Pointer<Utf8> productStringPtr = calloc<UnsignedChar>(libusbStringDescriptorMaxLength).cast();
      
      try {
        int result = _bindings.libusb_wrap_sys_device(_libusbContext.value, _device!.handle, deviceHandle);
        if (result < 0) {
            throw StateError("Unable to set device handle");
        }
        
        Pointer<libusb_device> device = _bindings.libusb_get_device(deviceHandle.value);
        result = _bindings.libusb_get_device_descriptor(device, deviceDescriptor);
        if (result < 0) {
            throw StateError("");
        } 

        result = _bindings.libusb_get_string_descriptor_ascii(deviceHandle.value, deviceDescriptor.ref.iManufacturer, manufacturerStringPtr.cast<UnsignedChar>(), libusbStringDescriptorMaxLength);
        if (result < 0) {
            throw StateError("Unable to get manufacturer string");
        }

        result = _bindings.libusb_get_string_descriptor_ascii(deviceHandle.value, deviceDescriptor.ref.iProduct, productStringPtr.cast<UnsignedChar>(), libusbStringDescriptorMaxLength);
        if (result < 0) {
            throw StateError("Unable to get product string");
        }

        _deviceInfo.addAll({
          "manufacturer": manufacturerStringPtr.toDartString(),
          "product": productStringPtr.toDartString(),
          "vid": "0x${deviceDescriptor.ref.idVendor.toRadixString(16)}",
          "pid": "0x${deviceDescriptor.ref.idProduct.toRadixString(16)}"
        });
      } finally {
        calloc.free(deviceHandle);
        calloc.free(deviceDescriptor);
        calloc.free(manufacturerStringPtr);
        calloc.free(productStringPtr);
      }
    }
    
  }

  String getDeviceMessage() {
    if (_deviceInfo.isNotEmpty) {
      return """USB Device connected:
Manufacturer: ${_deviceInfo["manufacturer"]}
Product: ${_deviceInfo["product"]}
VID: ${_deviceInfo["pid"]}
PID: ${_deviceInfo["vid"]}""";
    } else {
      return "Error: Unable to open device";
    }
  }

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

  void cleanupLibusb() {
    calloc.free(_libusbContext);
  }

  void checkUsbDevices() async {
    String msg = "";
    try {
      List<UsbDevice> devices = await _getUsbDevices();
      if (devices.isNotEmpty) {
        _device = devices.first;
        await _requestPermissionAndOpenDevice();
        msg = getDeviceMessage();
      }
    } on PlatformException catch(e) {
      msg = "Error: ${e.message}";
    }
    if (mounted) { 
      setState(() => _message = msg);
    }    
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Libusb Android example'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
               Text(_message.isEmpty ? "No device connected" : _message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
