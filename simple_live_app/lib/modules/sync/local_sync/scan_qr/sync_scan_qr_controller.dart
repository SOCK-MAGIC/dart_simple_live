import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SyncScanQRControlelr extends BaseController {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? qrController;
  StreamSubscription<Barcode>? barcodeStreamSubscription;
  bool pause = false;

  void onQRViewCreated(MobileScannerController controller) {
    qrController = controller;
    qrController?.barcodes.listen((scanData) async {
      Log.d(scanData.toString());
      if (pause) {
        return;
      }
      pause = true;
      // 扫码成功后暂停摄像头
      await controller.stop();

      var code = scanData.barcodes.firstOrNull!.rawValue;
      // 处理扫码结果
      if (code?.isEmpty == true) {
        pause = false;
        await controller.start();
        return;
      }

      // 如果是5位字符串，为房间号
      if (code?.length == 5) {
        Get.offAndToNamed(RoutePath.kRemoteSyncRoom, arguments: code);
        return;
      } else {
        var addressList = code!.split(";");
        if (addressList.length >= 2) {
          //弹窗选择
          showPickerAddress(addressList);
        } else {
          Get.back(result: code);
        }
      }
    });
  }

  void showPickerAddress(List<String> addressList) async {
    SmartDialog.showToast("扫描到多个地址，请选择一个连接");
    var address = await Utils.showBottomSheet(
      title: '请选择地址',
      child: ListView.builder(
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(addressList[i]),
            onTap: () {
              Get.back(result: addressList[i]);
            },
          );
        },
        itemCount: addressList.length,
      ),
    );
    if (address != null && address.isNotEmpty) {
      Get.back(result: address);
    }
  }

  @override
  void onClose() {
    barcodeStreamSubscription?.cancel();
    qrController?.dispose();

    super.onClose();
  }
}
