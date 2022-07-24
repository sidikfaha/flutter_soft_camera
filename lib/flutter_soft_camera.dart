library flutter_soft_camera;

import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soft_camera/helpers.dart';

class SoftCameraStyle {
  Color? primary;
}

class SoftCamera extends StatefulWidget {
  final CameraController controller;
  final void Function(XFile)? onCapture;
  final void Function(XFile)? onVideo;
  final bool isVideo;
  final SoftCameraStyle? style;

  const SoftCamera({
    Key? key,
    this.onCapture,
    this.isVideo = false,
    this.onVideo,
    this.style,
    required this.controller,
  }) : super(key: key);

  @override
  State<SoftCamera> createState() => _SoftCameraState();
}

class _SoftCameraState extends State<SoftCamera> {
  final Duration _animationDuration = const Duration(milliseconds: 300);

  late CameraController _ctr;
  late Size _mediaSize;
  late double _scale;
  late SoftCameraStyle _style;
  late Color _shooterColor;

  // State
  bool _loading = true;
  int _cameraId = 1;
  bool _capturing = false;
  Color _cameraOverlayColor = Colors.white.withOpacity(1);
  bool _recording = false;

  // Shooter state
  double _shooterStrokeWidth = 15;

  _init() async {
    _initData();
    _initCamera();
  }

  _initData() {
    _style = widget.style ?? SoftCameraStyle();
    _shooterColor = _style.primary ?? Colors.white;
  }

  _initCamera() {
    _ctr = widget.controller;

    _ctr.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    _ctr.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _mediaSize = MediaQuery.of(context).size;
        _scale = 1 / (_ctr.value.aspectRatio * _mediaSize.aspectRatio);
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            log('User denied camera access.');
            break;
          default:
            log('Handle other errors.');
            break;
        }
      }
    }).whenComplete(() {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _init();
    });
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool loaded = !_loading;

    return !loaded
        ? const Center(child: CircularProgressIndicator())
        : _camera();
  }

  Widget _camera() {
    return SizedBox(
      height: double.infinity,
      child: Stack(
        children: [
          ClipRect(
            clipper: _MediaSizeClipper(_mediaSize),
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topCenter,
              child: CameraPreview(_ctr),
            ),
          ),
          _capturing
              ? AnimatedContainer(
                  duration: _animationDuration,
                  color: _cameraOverlayColor,
                )
              : const SizedBox.shrink(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _style.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Nav.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox.shrink(),
                  GestureDetector(
                    onTap: widget.isVideo
                        ? (_recording ? _stopRecording : _startVideoRecord)
                        : _captureImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _shooterColor,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white,
                          width: _shooterStrokeWidth,
                        ),
                      ),
                      alignment: Alignment.center,
                    ),
                  ),
                  !_recording
                      ? GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _style.primary?.withOpacity(.3),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.repeat_rounded,
                              color: _style.primary,
                            ),
                          ),
                        )
                      : const SizedBox(width: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _switchCamera() {
    _cameraId = _cameraId == 0 ? 0 : 1;
    _loading = true;
    _initCamera();
  }

  _captureImage() async {
    _playSound();
    _showOverlay();

    final image = await _ctr.takePicture();
    log(image.path);

    if (widget.onCapture != null) {
      widget.onCapture!(image);
    }
  }

  _startVideoRecord() async {
    await _ctr.startVideoRecording();

    _recording = true;
    _shooterColor = Colors.red;
    _shooterStrokeWidth = 4;
    setState(() {});
  }

  _stopRecording() {
    _playSound();
    _showOverlay(); // Change to a video sound play

    _ctr.stopVideoRecording().then((value) {
      if (widget.onVideo != null) {
        widget.onVideo!(value);
      }
      _recording = false;
      _shooterColor = _style.primary ?? Colors.white;
      _shooterStrokeWidth = 10;
      setState(() {});
    });
  }

  _playSound() {
    (AudioPlayer()).play(AssetSource('camera.ogg'));
  }

  _showOverlay() async {
    setState(() {
      _capturing = true;
      _cameraOverlayColor = Colors.white;
    });

    await Future.delayed(const Duration(milliseconds: 10));

    setState(() {
      _cameraOverlayColor = Colors.transparent;
    });

    await Future.delayed(_animationDuration);

    setState(() {
      _capturing = false;
    });
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
