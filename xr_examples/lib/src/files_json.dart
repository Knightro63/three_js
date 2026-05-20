import 'dart:io';
import 'package:flutter/foundation.dart';

bool get actualVR => kIsWeb || Platform.isAndroid || Platform.isIOS;

List<String> filesJson = [
  if(actualVR) 'webxr_ar_cones',
  'webxr_vr_cardboard',
  if(actualVR) 'webxr_vr_handinput_cubes',
  'webxr_vr_rollercoaster',
  'webxr_vr_panorama',
  'webxr_vr_panorama_depth',
  if(actualVR) 'webxr_vr_teleport',
  'webxr_vr_video',
  if(actualVR) 'webxr_xr_ballshooter',
  if(actualVR) 'webxr_xr_cubes',
  if(actualVR) 'webxr_xr_dragging',
  if(actualVR) 'webxr_xr_paint',
  if(actualVR) 'webxr_xr_sculpt',
];
