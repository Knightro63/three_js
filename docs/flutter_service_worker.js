'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "dbfffc521a9545c9d35898e918d81464",
"version.json": "ff966ab969ba381b900e61629bfb9789",
"index.html": "610540efa1b6bd05156dfa4f9feb37d7",
"/": "610540efa1b6bd05156dfa4f9feb37d7",
"main.dart.js": "daca3a8911463604b0db218c725f9534",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.mjs": "a41d05a1019d8030b67565a6087ba0f4",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "0867c3e13649ac4d06fe34b7b3ddce08",
"main.dart.wasm": "e4a5e51af269b504c33075d2a8fa9266",
"assets/NOTICES": "82d9bca84156d7e4e32c4f1368f92c3c",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "5a167bb261e84ba39bfe78b6641e8ab3",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/flutter_soloud/web/worker.dart.js": "2fddc14058b5cc9ad8ba3a15749f9aef",
"assets/packages/flutter_soloud/web/init_module.dart.js": "ea0b343660fd4dace81cfdc2910d14e6",
"assets/packages/flutter_soloud/web/libflutter_soloud_plugin.js": "39308f9939684a6349f850c63d66c6ca",
"assets/packages/flutter_soloud/web/libflutter_soloud_plugin.wasm": "da6883b906173dea99c0e7618535abe4",
"assets/packages/three_js_objects/assets/Water_1_M_Normal.jpg": "a33d50da063b016852d1d139cf6e73b1",
"assets/packages/three_js_objects/assets/Water_2_M_Normal.jpg": "639428cf065384aae22d01b529011992",
"assets/packages/three_js_controls/assets/joystick_background.png": "8c9aa78348b48e03f06bb97f74b819c9",
"assets/packages/three_js_controls/assets/joystick_knob.png": "bb0811554c35e7d74df6d80fb5ff5cd5",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "48dbf1aa2a34fe2db8c3210a86293c9f",
"assets/fonts/MaterialIcons-Regular.otf": "c363ff21485c7fbcfb08ab399fcf6592",
"assets/assets/textures/edge3.jpg": "890d6ed0aa07e8f89a89193613c5b4cb",
"assets/assets/textures/jade.jpg": "52f2a3e6b9eb2f855a017c7f843245dd",
"assets/assets/textures/shaderball_ds.jpg": "a034b42627520fdfabc7506ed976f400",
"assets/assets/textures/decal/decal-diffuse.png": "f2fc2ddb66a092525b9eee5d1d2a0a9f",
"assets/assets/textures/decal/LICENSE.TXT": "26830afc25d3c907a69aa75ec56f493f",
"assets/assets/textures/decal/decal-normal.jpg": "be840b75f8b1451d6b3367b2f9e9982e",
"assets/assets/textures/square-outline.png": "b905d896d71bc85b43df499e7689d3ae",
"assets/assets/textures/colors.png": "d7f400f404eec84540a93770785ae2d3",
"assets/assets/textures/three_terrain/sand1.jpg": "4ef3e2483928f7cc514c73692f37d05a",
"assets/assets/textures/three_terrain/grass1.jpg": "724a9d840099ab991383bb8c075df168",
"assets/assets/textures/three_terrain/stone1.jpg": "ee302eaa67917d48f12ee127047ad893",
"assets/assets/textures/three_terrain/heightmap.png": "408c89b18350163ee9dc01ec3e3a141c",
"assets/assets/textures/three_terrain/snow1.jpg": "98b34a796c2c8d8ad10b12baa3764263",
"assets/assets/textures/three_terrain/sky1.jpg": "51d67cf2970f03a6de7d69d55398e4da",
"assets/assets/textures/uv_grid_opengl.jpg": "ea0adfcb01cfcb26fe36ac0005606444",
"assets/assets/textures/water/Water_1_M_Normal.jpg": "a33d50da063b016852d1d139cf6e73b1",
"assets/assets/textures/water/Water_1_M_Flow.jpg": "1fdb8d394dd0f76739a2830831747d22",
"assets/assets/textures/water/Water_2_M_Normal.jpg": "639428cf065384aae22d01b529011992",
"assets/assets/textures/hardwood2_diffuse.jpg": "94bed574871efc2888038b57b23805d1",
"assets/assets/textures/cube/Park2/negz.jpg": "101ece5be7592bfb4249a79e1968d3b6",
"assets/assets/textures/cube/Park2/negx.jpg": "6b2f292c33585296de8f4e638986bb79",
"assets/assets/textures/cube/Park2/negy.jpg": "9ed17cd7644cbc03321d4179aa06090d",
"assets/assets/textures/cube/Park2/readme.txt": "aaed0013d845535269df03a1d6ade4a9",
"assets/assets/textures/cube/Park2/posy.jpg": "01f7d2408087e4fc1fc03966616d35ef",
"assets/assets/textures/cube/Park2/posx.jpg": "d7f98688348b7540277ea8c6493f12a6",
"assets/assets/textures/cube/Park2/posz.jpg": "6579ac45179c999a22ca04f88c033e93",
"assets/assets/textures/cube/pisa/nx.png": "e94f696327b045cb939f494cc0a0d85a",
"assets/assets/textures/cube/pisa/ny.png": "70a8aa8f8b929d03fd2c2bbe7caabe8c",
"assets/assets/textures/cube/pisa/nz.png": "6af7bd6f734e12f2ccbb0c16d57a9795",
"assets/assets/textures/cube/pisa/pz.png": "47a01aa16f98a1d30e7c6a1c4734db33",
"assets/assets/textures/cube/pisa/px.png": "9210e854072e619e7a98b8a015e2eab7",
"assets/assets/textures/cube/pisa/py.png": "53f2fd65a58e8e993c57c9b8de962292",
"assets/assets/textures/758px-Canestra_di_frutta_(Caravaggio).jpg": "ded243e7192fa2754b87132984fbd936",
"assets/assets/textures/waterdudv.jpg": "3def38543f645790e6d836fcc6bdc02d",
"assets/assets/textures/square-outline-textured.png": "6f7897fbc8a9c08f656e19446b46f735",
"assets/assets/textures/disturb.jpg": "f1b4c29e355977cd1e12c0063c500406",
"assets/assets/textures/waternormals.jpg": "4418dde3f6abc21dc32506acf5f5b093",
"assets/assets/textures/sprite.png": "d30f6af129314958fefb4fbe7edbe00c",
"assets/assets/textures/crate.gif": "da499b8537ee3ce0ed8469c0a73ecc2c",
"assets/assets/textures/sintel.mp4": "36abd8180373525089df094e2f5a5cea",
"assets/assets/textures/lava/lavatile.jpg": "4a9f002bd808e95fe4c37814b4fea834",
"assets/assets/textures/lava/cloud.png": "b1bad13014f2b011193378243a34eef6",
"assets/assets/textures/noise.png": "7c756fce1f89f24b100bd4f08b36383d",
"assets/assets/textures/water.jpg": "bcfb9394f4141ab0c9cdaeaf62f1aadd",
"assets/assets/textures/terrain/grasslight-big-nm.jpg": "d9b46098a647b139e79b771b1db961a3",
"assets/assets/textures/terrain/grasslight-big.jpg": "801373c211724f955fb17e1e2b5ba453",
"assets/assets/textures/terrain/readme.txt": "ab72de6fc737288d22513546b0551d29",
"assets/assets/textures/planets/earth_atmos_4096.jpg": "5443d5269947693c26395afc95807810",
"assets/assets/textures/planets/earth_lights_2048.png": "7ccf9db799e9c713dff7dc3461dafa25",
"assets/assets/textures/planets/earth_clouds_1024.png": "63b2ef0cc6d1bbac112d9eb4612663ad",
"assets/assets/textures/planets/earth_atmos_2048.jpg": "e15eb8d2a32d001aa4e06884f6a566cd",
"assets/assets/textures/planets/earth_clouds_2048.png": "5616c53eb44e724672735031cd67613a",
"assets/assets/textures/planets/earth_specular_2048.jpg": "7dd1857a60a7a7bee6fb9e4b6c9fc9dd",
"assets/assets/textures/planets/earth_normal_2048.jpg": "d309331c72cff9557deae2f779d47f26",
"assets/assets/textures/planets/moon_1024.jpg": "2e7ade181b8d94636304008d6f23a516",
"assets/assets/textures/uv_grid_directx.jpg": "86c5fd733d18aeaf0ba91bf7f778c278",
"assets/assets/textures/sprite0.jpg": "a19a72e4b5d084b6e79789db5ec6a23d",
"assets/assets/textures/sprite0.png": "fbb77be9f02a7624181a10267b2b447e",
"assets/assets/textures/sprites/disc.png": "f1d753f1a8e6ebb30d283f17ca43a560",
"assets/assets/textures/sprites/spark1.png": "6fcfa7e6789e87957c0c7419c18fad9c",
"assets/assets/textures/sprites/ball.png": "d9b2f9599b4c7b18010ad937667c39d2",
"assets/assets/textures/sprites/circle.png": "af5735c195346d58bc2244da9d48678b",
"assets/assets/textures/sprites/snowflake7_alpha.png": "fc324da1add18a604b09e35a1c817cfd",
"assets/assets/textures/sprites/snowflake1.png": "99c51beabb59b5b026c814fe294c5966",
"assets/assets/textures/sprites/snowflake3.png": "2dbe07e000ba1b4fe4ec5b862294caaf",
"assets/assets/textures/sprites/snowflake2.png": "671fe112535f517acaca0b60430d62ef",
"assets/assets/textures/sprites/snowflake5.png": "90be2cc86bdf4bbbc07fe92e0aa650e6",
"assets/assets/textures/sprites/snowflake4.png": "b97b73a720a59d03da0c49c296eb338f",
"assets/assets/textures/land_ocean_ice_cloud_2048.jpg": "b07dffb39178b6c32ded56481356ffaa",
"assets/assets/textures/sprite1.png": "1a949586f4b0d119da0dbe0d25567e11",
"assets/assets/textures/sprite1.jpg": "e24dddfab1d3d608bf1ab6df01b790cb",
"assets/assets/textures/floors/FloorsCheckerboard_S_Normal.jpg": "da0bf6462749a20cf8b364d0083fbc85",
"assets/assets/textures/floors/FloorsCheckerboard_S_Diffuse.jpg": "d2d3ed8b358b151149a29e198959b340",
"assets/assets/textures/sprite2.png": "52b94f4ec699433ec83b9dca02becb5d",
"assets/assets/textures/lensflare/lensflare2.png": "317811aa9d29f9d99a816dd2ad4c044b",
"assets/assets/textures/lensflare/lensflare3.png": "20a2bd3c24508cc7d41a893ed208cab2",
"assets/assets/textures/lensflare/lensflare1.png": "512a9955235dfea402bd1496a92f7ecd",
"assets/assets/textures/lensflare/lensflare0.png": "28ecca635ec4470ba55983a1c966b437",
"assets/assets/textures/lensflare/hexangle.png": "1bc8fc22cb9fdbe842b471fd69c087d6",
"assets/assets/textures/lensflare/lensflare0_alpha.png": "614e5f0fe84fa925c545775ff0d6b8de",
"assets/assets/textures/lensflare/LICENSE.txt": "ac95af3dbc4b11d3502574f01a371d28",
"assets/assets/textures/equirectangular/royal_esplanade_1k.hdr": "375181a19c870eb048c0751a468396d4",
"assets/assets/textures/equirectangular/moonless_golf_2k.hdr.jpg": "369b223760954e29ad5e54bc3c555267",
"assets/assets/textures/equirectangular/venice_sunset_1k.hdr": "704548cc835be5bb43bbb280395869e7",
"assets/assets/textures/equirectangular/moonless_golf_1k.hdr": "da9edde9ad39465900a7935dc15ab8d7",
"assets/assets/textures/equirectangular/lobe.hdr": "900ebb0d22e0af2d466cc7f11a2c7ef4",
"assets/assets/textures/equirectangular/quarry_01_1k.hdr": "d4c4954484c7a713e283b22f71591f26",
"assets/assets/textures/equirectangular/pedestrian_overpass_1k.hdr": "b52d400303d1578413b7283eb1e64e6c",
"assets/assets/screenshots/misc_controls_fly.jpg": "cf74175a48eac3552e1476f2fc584703",
"assets/assets/screenshots/webgl_geometries.jpg": "00dd62430371a3b8c2508e264cdc9586",
"assets/assets/screenshots/webgl_geometry_terrain_raycast.jpg": "bf7a1136c1d03fc808a3ffa2d323f962",
"assets/assets/screenshots/webgl_shader_lava.jpg": "3e99f90ecd715ebd2ba1936e0a27c5c2",
"assets/assets/screenshots/webgl_loader_texture_basis.jpg": "8ea6d45ce146f3d37342b4004ad7221b",
"assets/assets/screenshots/webgl_loader_fbx_nurbs.jpg": "373d600bdd75cdbfdb72aeef14ccf331",
"assets/assets/screenshots/webgl_postprocessing_sobel.jpg": "408ff06d702cb36f025cbde5e167f731",
"assets/assets/screenshots/webgl_shadow_contact.jpg": "2304a71b165a23a324437e979741bf28",
"assets/assets/screenshots/webgl_loader_bvh.jpg": "6d8d687bb18f3558babbe9e2d2269e60",
"assets/assets/screenshots/webgl_animation_keyframes.jpg": "ae80b2a6ba92e2709c47547db2190ca2",
"assets/assets/screenshots/moving_physics.jpg": "98eb445e7c2082194127e5291dd80d1c",
"assets/assets/screenshots/webgl_instancing_dynamic_blocks.jpg": "1a5276854077e95e22a5cc3684cda677",
"assets/assets/screenshots/webgl_postprocessing_fxaa.jpg": "5a264a1052a722e06ff849de9b535120",
"assets/assets/screenshots/webgl_sprites.jpg": "8716336647fda528061ccdd0c2095b31",
"assets/assets/screenshots/webgl_helpers.jpg": "851b40ac56ac23fa480b9ad99b0bbcc8",
"assets/assets/screenshots/webgl_custom_attributes_lines.jpg": "8b9fc7bc9a304e48f4567f770f3216a5",
"assets/assets/screenshots/webgl_instancing_raycast.jpg": "2c74ffe695116baea2e4faf96cb8782f",
"assets/assets/screenshots/basic_physics.jpg": "94d89ff4b52998e73be7b1d20687c2b3",
"assets/assets/screenshots/webgl_postprocessing_taa.jpg": "bf7faa841a38101588a6a954a135175c",
"assets/assets/screenshots/webgl_modifier_subdivision.jpg": "161753e5798e3a3a84d801e5d626ed66",
"assets/assets/screenshots/webgl_loader_svg.jpg": "6e8ddefd1f6ae30a778bdc6e43987364",
"assets/assets/screenshots/webgl_shadowmap_pointlight.jpg": "eabfdecb6672e5361430f6f841175915",
"assets/assets/screenshots/misc_controls_transform.jpg": "43a3c73f4522ffd5e06346c7c290fe56",
"assets/assets/screenshots/webgl_gpgpu_protoplanet.jpg": "fe63d79f98637289d818e0dd1de7fc85",
"assets/assets/screenshots/webgl_instancing_morph.jpg": "f681b0b477ba9296c6364fb349e346d9",
"assets/assets/screenshots/misc_exporter_gltf.jpg": "4e60262905159a0fd7235f55714074f2",
"assets/assets/screenshots/webgl_ubo_arrays.jpg": "c544a2cada68c670f92ab89b88cc8df0",
"assets/assets/screenshots/three_terrain.jpg": "38a9d017760ecdc8170b5d5556aaf0ef",
"assets/assets/screenshots/webgl_materials_video.jpg": "435ef07011aba2c7d637a2452695901f",
"assets/assets/screenshots/webgl_volume_perlin.jpg": "72da540351bba6a3ade0c1862182cfbd",
"assets/assets/screenshots/misc_exporter_usdz.jpg": "e6e434a795587053f60e94f6b974e913",
"assets/assets/screenshots/webgl_loader_md2.jpg": "93c40e84c6cae40a3138bd70da0d6c32",
"assets/assets/screenshots/webgl_loader_fbx.jpg": "8af8a9d536e6fb3c518507ebeac25ea3",
"assets/assets/screenshots/webgl_materials_car.jpg": "84c7edfef8b093372a662203011a2b1f",
"assets/assets/screenshots/timing.jpg": "cae5fdf85b112723bfd3db543dd0f56d",
"assets/assets/screenshots/webgl_loader_stl.jpg": "29f717b5c68979a981b167bfcdee8971",
"assets/assets/screenshots/webgl_geometry_terrain.jpg": "3725fd3e5be4c9bbfff804ddf6ba78b4",
"assets/assets/screenshots/webgl_materials_modified.jpg": "bf10bf4132e3a0860c2e01241304c8e4",
"assets/assets/screenshots/misc_controls_orbit.jpg": "2ae581a4be9aefebf40bd0fa125650b4",
"assets/assets/screenshots/webgl_camera.jpg": "de1370376c86f31202173a90860166f9",
"assets/assets/screenshots/misc_controls_device_orientation.jpg": "488589ece8be1c940b66d905878128b8",
"assets/assets/screenshots/webgl_modifier_edgesplit.jpg": "1a487db3e30ab5ec29a0242a4bc997c2",
"assets/assets/screenshots/webgl_random_uv.jpg": "73405288dd321a953b212ec0a41f0e00",
"assets/assets/screenshots/webgl_loader_glb.jpg": "6c7e2f77dd36288fd892a4001aa260db",
"assets/assets/screenshots/webgl_projected_basic.jpg": "30f80616ad805b1beabd926d44c39268",
"assets/assets/screenshots/webgl_shadowmap_vsm.jpg": "c2581a5ae5fa1795990f7efc0270b837",
"assets/assets/screenshots/webgl_camera_array.jpg": "b1826f9bd6bc43fab6f3e62b46dc4242",
"assets/assets/screenshots/webgl_portal.jpg": "f3120856dd3f26348001229e3e120eae",
"assets/assets/screenshots/webgl_buffergeometry_instancing_billboards.jpg": "b0b0f58d07f43bca2f8ac612f0a1da7d",
"assets/assets/screenshots/games_fps.jpg": "efd2677e71d63fb7a62fc70085ecc6c1",
"assets/assets/screenshots/webgl_water.jpg": "8dd48e69c7ad0388e256bec1266ca088",
"assets/assets/screenshots/webgl_loader_ply.jpg": "0e29b672aa43e7921f6b0b4f16a35c33",
"assets/assets/screenshots/webxr_vr_rollercoaster.jpg": "e195f47238980b9319c2a62ee2ea928a",
"assets/assets/screenshots/webgl_loader_collada_skinning.jpg": "15d6992aa4e572e07ce635bfc134438c",
"assets/assets/screenshots/webgl_modifier_simplifier.jpg": "a22b54e384601ab8b600e77da222b4ed",
"assets/assets/screenshots/webgl_mirror.jpg": "45d15cf4d6c1e7c57be9a4e6b87fa210",
"assets/assets/screenshots/webgl_shaders_sky.jpg": "bae77d85246b76a140efe445c71d75a7",
"assets/assets/screenshots/webgl_interactive_voxelpainter.jpg": "c909078f3444e5895fe192a9a92b5fbd",
"assets/assets/screenshots/webgl_multi_views.jpg": "da3e29fa7e3a77769b223d62b6fb10a0",
"assets/assets/screenshots/webgl_multiple_scenes_comparison.jpg": "d9c7e3ffcbe213a8da54572be0e907f9",
"assets/assets/screenshots/webgl_lines_dashed.jpg": "c4e2f8880aefd2c8b3f501750fd923c9",
"assets/assets/screenshots/webgl_postprocessing_unreal_bloom_selective.jpg": "0c19e382042378a603c612e7e2cb1afc",
"assets/assets/screenshots/webgl_lines_fat_wireframe.jpg": "7902033b6f1121a9f6cf5405acfccb8a",
"assets/assets/screenshots/webgl_interactive_raycasting_points.jpg": "90c281eb4b5771410b0d6cc46b9abea9",
"assets/assets/screenshots/webgl_loader_gcode.jpg": "e3248139c05dfa26dbd424ac2d19828d",
"assets/assets/screenshots/misc_exporter_obj.jpg": "5656974f8113c77fcb40dabc032fa01c",
"assets/assets/screenshots/misc_controls_arcball.jpg": "dad403f0b88a1f24d14a9c8854566125",
"assets/assets/screenshots/misc_controls_map.jpg": "488589ece8be1c940b66d905878128b8",
"assets/assets/screenshots/webgpu_performance.jpg": "4a969503f1506863e1e3af994c5dd864",
"assets/assets/screenshots/webgl_loader_collada.jpg": "d3ede7e696fbc7ff64a57e194c434c36",
"assets/assets/screenshots/webgl_clipping_stencil.jpg": "13dde3f848bf1e788ef3b1e0edd90a54",
"assets/assets/screenshots/webgl_postprocessing_smaa.jpg": "4985e84108fad8534e21db66e7bc0878",
"assets/assets/screenshots/webgl_lightprobe_cube_camera.jpg": "d6abde765dd1d841a995ab85b36fbdba",
"assets/assets/screenshots/webgl_lensflares.jpg": "a9c1342ae7ea9a7dfd03c36daa9cf95f",
"assets/assets/screenshots/webgl_lod.jpg": "9c3ac4ef6d1b428785eff2f8ceb61957",
"assets/assets/screenshots/webgl_geometries_parametric.jpg": "24c7eaa8ca81acadae6ac52813c21b30",
"assets/assets/screenshots/webgl_materials_browser.jpg": "1fdeedadba88f73f29622ce45dc1ed74",
"assets/assets/screenshots/misc_controls_trackball.jpg": "7756cde5f13c42d0943ea3f614af85be",
"assets/assets/screenshots/webgl_lights_rectarealight.jpg": "6cb8e60a7bc818da82d8ab9ed0e7b3f1",
"assets/assets/screenshots/webgl_volume_cloud.jpg": "db2a0cde97951917ee5f922a0855fc02",
"assets/assets/screenshots/webgl_projected_3d_model.jpg": "f53575ca3c13a20d8fba939c187cd654",
"assets/assets/screenshots/webgl_materials_physical_transmission.jpg": "afedbdc7a27531d218dbba1f4d491051",
"assets/assets/screenshots/webgl_shader.jpg": "6327e451bcc7a51875acd95f67e5f53a",
"assets/assets/screenshots/webgl_morphtargets_face.jpg": "35ab6439759daaf612f96e6057a1f40d",
"assets/assets/screenshots/webgl_loader_pcd.jpg": "9d9ffec8be00f3da074a947c297c52cd",
"assets/assets/screenshots/webgl_points_sprites.jpg": "bcf0bad258b6212ab535f9e71691c5c1",
"assets/assets/screenshots/webgl_loader_collada_kinematics.jpg": "685d7265f1dc7253e67b2dc907034476",
"assets/assets/screenshots/webgl_clipping_advanced.jpg": "06fec3e9f4bcc19611b4fc1822b00140",
"assets/assets/screenshots/webgl_geometry_dynamic.jpg": "fe252aa75de9b92bf5ad46d323415cea",
"assets/assets/screenshots/webgl_geometry_text.jpg": "17327acf9321626f5e7d08c9ea77aaeb",
"assets/assets/screenshots/webgl_skinning_simple.jpg": "78512a6b4f54ec10eabecd0cf4fec739",
"assets/assets/screenshots/webgl_materials_video_webcam.jpg": "435ef07011aba2c7d637a2452695901f",
"assets/assets/screenshots/webgl_geometry_extrude_splines.jpg": "fd844bfddf8c7e1096896774b6c0db2e",
"assets/assets/screenshots/webgl_clipping.jpg": "db01a6fbf787622c4f8d6f5245a46241",
"assets/assets/screenshots/webgl_geometry_nurbs.jpg": "1afb63ea52bff5dbae14d4ad6a8ded75",
"assets/assets/screenshots/flutter_screenshot.jpg": "269365a2338e27e0095f42e346c7009e",
"assets/assets/screenshots/webgl_tonemapping.jpg": "f04838402fc471e3fada48ccbadf6223",
"assets/assets/screenshots/webgl_materials_physical_transmission_alpha.jpg": "b0cb24bde799ff3d4461b6be596fe14e",
"assets/assets/screenshots/webgl_instancing_scatter.jpg": "4da6dfaa2a3131e11fc826b455accb6a",
"assets/assets/screenshots/webgl_loader_xyz.jpg": "8e2f2618a3597b4afd7abf7818684935",
"assets/assets/screenshots/webgl_geometry_extrude_shapes.jpg": "dc45eccc1fcf0a83e18973b8b311a7fa",
"assets/assets/screenshots/webgl_loader_vox.jpg": "6fbdf7f0dabc739d28fa38cec77956d5",
"assets/assets/screenshots/webgl_loader_obj.jpg": "237ac174b0b5eeb222a1d85b4deb7d43",
"assets/assets/screenshots/webgl_lines_fat_raycasting.jpg": "9decfa06ecc6273ebc6571c8ae1f16cf",
"assets/assets/screenshots/sandbox.jpg": "4b5cbdd70ba62e12d122523f3b2744ec",
"assets/assets/screenshots/webgl_animation_cloth.jpg": "e1fbd6c039a7f295bfcd140ceec3fe0c",
"assets/assets/screenshots/webgl_lights_spotlight.jpg": "9f0b76172d628a6145c9bb1b71500d0d",
"assets/assets/screenshots/webgl_interactive_points.jpg": "00d2dbc2fac9752557a43ad2e9cfdb16",
"assets/assets/screenshots/webgl_morphtargets.jpg": "21db9fe6b3a536ebc6fbcdf54208ca6f",
"assets/assets/screenshots/webgl_geometry_csg.jpg": "ae5d9d00b7d6987a5b8579ecdae59f60",
"assets/assets/screenshots/webgl_shadowmap_csm.jpg": "a2a3a0c9db5fcffb5948dcd0a4d35f78",
"assets/assets/screenshots/webgl_shadowmap_viewer.jpg": "949a3530092f619cedfe4a4414dd86c8",
"assets/assets/screenshots/webgl_simple_gi.jpg": "d7284138edb532d3d0cc20e72a097a93",
"assets/assets/screenshots/orientation.jpg": "5471ec35112463518cbaec3afdf39cc9",
"assets/assets/screenshots/webgl_clipping_intersection.jpg": "7beafe1049ec9d671ecf8036a72088e3",
"assets/assets/screenshots/webgl_morphtargets_sphere.jpg": "d9e66e946f51b2d693b2663759888259",
"assets/assets/screenshots/multi_views.jpg": "7efb8abbeca3538df019ee27747331b6",
"assets/assets/screenshots/webgl_postprocessing_unreal_bloom.jpg": "772fa3b206e21783d86577f5125fd2b0",
"assets/assets/screenshots/compound2_physics.jpg": "022abb91cf5e6ac150f16b10eab418e3",
"assets/assets/screenshots/webgl_animation_skinning_morph.jpg": "ef659a89e9764d135611db6409411895",
"assets/assets/screenshots/webgl_shaders_ocean.jpg": "d25b5d320996175314981a630fe6deb3",
"assets/assets/screenshots/webgl_animation_skinning_additive_blending.jpg": "72d6b1dae234645bfe4b8e9164fa8294",
"assets/assets/screenshots/flutter_game.jpg": "05fefbc4661decefe2bc5db0aa45fc8e",
"assets/assets/screenshots/misc_exporter_ply.jpg": "03a74348ca664eefb87547b3ec287a95",
"assets/assets/screenshots/webgl2_multiple_rendertargets.jpg": "d56d34e933c4d4079c41b34d73154771",
"assets/assets/screenshots/webgl_geometry_spline_editor.jpg": "a38b243ece03c47360e745918afeb6fc",
"assets/assets/screenshots/compound_physics.jpg": "022abb91cf5e6ac150f16b10eab418e3",
"assets/assets/screenshots/webgl_buffergeometry_custom_attributes_particles.jpg": "b3f92a7f63594fcb5894ab636d8a0f73",
"assets/assets/screenshots/webgl_lines_fat.jpg": "a24b4af3cf92927fd320cb75ed47f380",
"assets/assets/screenshots/webgl_lines_colors.jpg": "4fcf972c037832a8983d1199498b17b6",
"assets/assets/screenshots/webgl_materials.jpg": "73133c87bc5c7a86b9e4bef25688422e",
"assets/assets/screenshots/webgl_lightprobe.jpg": "1b59fcac8dd7cef4266ff39029dca6e6",
"assets/assets/screenshots/webgl_water_flowmap.jpg": "43eac320fb0d8749e40760a0443b0c66",
"assets/assets/screenshots/misc_exporter_stl.jpg": "530d7cef7196b7a737453ef061bc35df",
"assets/assets/screenshots/webgl_geometry_convex.jpg": "7f09306cc76610b9922f95f84497949d",
"assets/assets/screenshots/collision_physics.jpg": "1acd7711dd8bb46043691f791c51ee75",
"assets/assets/screenshots/webgl_volume_instancing.jpg": "3f3acaf67d8c737352299fdd3297e44f",
"assets/assets/screenshots/webgl_modifier_tessellation.jpg": "e242a87568cdba187249cd7ce19a2291",
"assets/assets/screenshots/webgl_morphtargets_horse.jpg": "03ba3fbdb5c2f7ab45e91a42422f290c",
"assets/assets/screenshots/misc_controls_drag.jpg": "54c4c32547c0a66f2a1bea81fe587ca2",
"assets/assets/screenshots/boxselection.jpg": "3a5b2080fff7363bcc48eeb68b4fcf53",
"assets/assets/screenshots/webgl_interactive_lines.jpg": "18ff0f8256e3cde821a638acfe0c06d4",
"assets/assets/screenshots/webgl_materials_subsurface_scattering.jpg": "05f29bb9632a9e978494c0421d54b3ea",
"assets/assets/screenshots/webgl_decals.jpg": "f263b2720926a209f6458ef9c27ba575",
"assets/assets/screenshots/webgl_instancing_performance.jpg": "ae670a8468853ff756f739477785080c",
"assets/assets/screenshots/webgl_loader_gltf.jpg": "269365a2338e27e0095f42e346c7009e",
"assets/assets/screenshots/webgl_geometry_csg2.jpg": "74621aaa58062da0a4cb7284fda886fd",
"assets/assets/screenshots/marching_cubes.jpg": "6c4a743ffa9be3ac0cb5db4af81ce5c4",
"assets/assets/screenshots/misc_controls_pointerlock.jpg": "da8f8a7d22e7182ec1d02b3c08ecc0e2",
"assets/assets/screenshots/webgl_periodictable.jpg": "d835b0a3c4b94ff790680706ea842ca3",
"assets/assets/screenshots/webgl_animation_multiple.jpg": "0ee7867d592fe3818ba5899e7e2266d1",
"assets/assets/screenshots/webgl_refraction.jpg": "95b345151a0b23dfcea05b59739c512c",
"assets/assets/screenshots/webgl_animation_walk.jpg": "ba9147f622b67e3086ac2db2adba7d15",
"assets/assets/screenshots/webgl_animation_skinning_blending.jpg": "876d2f3013a3400ee4e4be234d917f61",
"assets/assets/screenshots/webgl_geometry_colors.jpg": "2479e6ab39c76b05763fca054d0628bf",
"assets/assets/screenshots/webgl_instancing_dynamic.jpg": "21c44f0e31362d9c5f03c2ef72f02563",
"assets/assets/screenshots/webgl_loader_usdz.jpg": "73b15102e619e2eeb599faeea7e3aa5d",
"assets/assets/screenshots/opengl_screenshot.jpg": "269365a2338e27e0095f42e346c7009e",
"assets/assets/screenshots/webgl_loader_obj_mtl.jpg": "16bdd7ed74814acc73fff3b0b838832d",
"assets/assets/screenshots/misc_animation_keys.jpg": "cf05fe48d7154137a06768d815b9850e",
"assets/assets/screenshots/webgl_geometry_shapes.jpg": "6b7c73a2adcaa9496c5dcc79aca95135",
"assets/assets/models/svg/hexagon.svg": "4eddac4f6e1c006980a8af121a10a6ab",
"assets/assets/models/svg/multiple-css-classes.svg": "e9d2881030b2616203392aff02672ac0",
"assets/assets/models/svg/tiger.svg": "be17ac47cc132f4dbb13e7b2633ea898",
"assets/assets/models/svg/energy.svg": "59e605ac6c9b373d5303f55a905306f5",
"assets/assets/models/svg/threejs.svg": "da6a5e2f456916bb016f70d1bd8436ee",
"assets/assets/models/svg/lineJoinsAndCaps.svg": "c3ca49a123f1bc4ec27aa9ca8a79484c",
"assets/assets/models/svg/zero-radius.svg": "3f1e45e8ec8a0263207c99ed0a271f1b",
"assets/assets/models/ply/ascii/dolphins.ply": "8095e122ad66bcdd6b97143fe0b6a44b",
"assets/assets/models/ply/ascii/dolphins_colored.ply": "e83c0a1e6c62811aa93221d1951ea4e0",
"assets/assets/models/ply/binary/dolphins_le.ply": "95d8665b1bc251d9d0bb3829eff24b79",
"assets/assets/models/ply/binary/Lucy100k.ply": "e7eb9b80ef902fc65c2f751fb41331ae",
"assets/assets/models/ply/binary/dolphins_be.ply": "1a9bc7ea78f62bca37fd5dfccf17d683",
"assets/assets/models/obj/stanford-bunny.obj": "2ed52a53cefa0438e1c2d0bc4ed3c960",
"assets/assets/models/obj/cerberus/Cerberus_M.jpg": "0d9f38010ba2322d0fba0a2a45bf17b2",
"assets/assets/models/obj/cerberus/Cerberus_N.jpg": "21262bb094a65add114aa514e8d21e1c",
"assets/assets/models/obj/cerberus/Cerberus.obj": "50f74f8eb41431a018fc154969e33c5c",
"assets/assets/models/obj/cerberus/Cerberus_A.jpg": "9f0eba376f21d6102e21f0971ed6d7fe",
"assets/assets/models/obj/cerberus/Cerberus_R.jpg": "8ebb776ba1dc85b10af7efe530ded95f",
"assets/assets/models/obj/cerberus/Cerberus_RM.jpg": "f8716281addafb734f5e60bd2a149182",
"assets/assets/models/obj/male02/01_-_Default1noCulling.dds": "24e4a946fa9d56474cca36e2b5493fc7",
"assets/assets/models/obj/male02/male021.obj": "cf5274057b092620a56af04b604f8f92",
"assets/assets/models/obj/male02/male02_dds.mtl": "7a5d46828b2ea3facaf5cdccf7e93de0",
"assets/assets/models/obj/male02/male02.mtl": "b4d34e3408d76351c58ba2e670a06194",
"assets/assets/models/obj/male02/orig_02_-_Defaul1noCulling.dds": "1be543407ebedf651a0a3dca353c882b",
"assets/assets/models/obj/male02/male-02-1noCulling.dds": "0f246da0478d233b3a382e855797b6fd",
"assets/assets/models/obj/male02/01_-_Default1noCulling.JPG": "bfd3c8b3c40709aabea8ae05b90f3411",
"assets/assets/models/obj/male02/readme.txt": "f5dcf333d006e0074b18f373e16cfdaf",
"assets/assets/models/obj/male02/orig_02_-_Defaul1noCulling.JPG": "8835a9c4b8023e8c206413ff8eb5cd26",
"assets/assets/models/obj/male02/male-02-1noCulling.JPG": "5d6c59c0e5da41d8c556135234d79221",
"assets/assets/models/obj/male02/male02.obj": "310586de426d900e1540d98f81ed2b81",
"assets/assets/models/md2/ratamahatta/w_rlauncher.md2": "8927f836833a2f00f316348cab753dc9",
"assets/assets/models/md2/ratamahatta/ratamahatta.md2": "8d1cbcac127dd01ce167fe45f43a7604",
"assets/assets/models/md2/ratamahatta/w_chaingun.md2": "921e9f27f90b113f1de47be0688bda4f",
"assets/assets/models/md2/ratamahatta/skins/w_blaster.png": "a6f38b600a8535bad8274c83661f2e02",
"assets/assets/models/md2/ratamahatta/skins/w_glauncher.png": "0bf19e2fb7684fe25b778163e4f26598",
"assets/assets/models/md2/ratamahatta/skins/w_hyperblaster.png": "ec9ac6fac23d91cec6a5a38abf4ddbcd",
"assets/assets/models/md2/ratamahatta/skins/w_chaingun.png": "7ca6a19d7a41944ffffe018efb065c25",
"assets/assets/models/md2/ratamahatta/skins/w_sshotgun.png": "e0b6dd9fb59630ddb1b43d874d8be29d",
"assets/assets/models/md2/ratamahatta/skins/gearwhore.png": "516afe5460479862e2e59f37df7c391a",
"assets/assets/models/md2/ratamahatta/skins/w_rlauncher.png": "9af1745e6ffde00722a93bc98b2255ca",
"assets/assets/models/md2/ratamahatta/skins/ratamahatta.png": "a868d4ac4ccced3d6ad322924f88889e",
"assets/assets/models/md2/ratamahatta/skins/weapon.png": "3bf49116cfed113d42f2033c1db6523c",
"assets/assets/models/md2/ratamahatta/skins/w_shotgun.png": "34800aa2c05279eea7853f1fdc8ddb28",
"assets/assets/models/md2/ratamahatta/skins/ctf_r.png": "9036e7fb4597e0ac88b96cb03694a986",
"assets/assets/models/md2/ratamahatta/skins/dead.png": "95c287c9c556644d490a27a7e9e73390",
"assets/assets/models/md2/ratamahatta/skins/ctf_b.png": "4522dfc91908c2a8c86dea00441db780",
"assets/assets/models/md2/ratamahatta/skins/w_railgun.png": "adfcdf0a58a5cc9be657d2e94845890e",
"assets/assets/models/md2/ratamahatta/skins/w_machinegun.png": "9042cfe62dfa2e0ebc352bcf2df191c4",
"assets/assets/models/md2/ratamahatta/skins/w_bfg.png": "868e6952c25263f73fa3e2f690f6b77f",
"assets/assets/models/md2/ratamahatta/w_sshotgun.md2": "8e0efd5d8c7fe1cd99d6cae81133eb7a",
"assets/assets/models/md2/ratamahatta/w_blaster.md2": "f827ce83af03182ae3e29a80819a506d",
"assets/assets/models/md2/ratamahatta/w_glauncher.md2": "f05fd2a4f04f71021c62f3196f3c889f",
"assets/assets/models/md2/ratamahatta/w_hyperblaster.md2": "33622be888fb208b45993c02cea8a02a",
"assets/assets/models/md2/ratamahatta/w_bfg.md2": "735bedf69f410c3862310b34335bf792",
"assets/assets/models/md2/ratamahatta/w_railgun.md2": "6a7b47db342ad60a4715835ade62ba31",
"assets/assets/models/md2/ratamahatta/w_machinegun.md2": "2ae796831775e65c45bc891c8743e1f8",
"assets/assets/models/md2/ratamahatta/weapon.md2": "68fc683a6d58f58eba540ac2db26fcc2",
"assets/assets/models/md2/ratamahatta/w_shotgun.md2": "e29ba7c31109cb5bf124680e161b6508",
"assets/assets/models/md2/ogro/skins/darkam.png": "2459927ac057492f12ac7c1258fc7dda",
"assets/assets/models/md2/ogro/skins/gordogh.png": "a0b61ae8fbb6dfa4a9765cf1aeee5615",
"assets/assets/models/md2/ogro/skins/freedom.png": "287a33629e4fa5a4305bb4f8e32a8884",
"assets/assets/models/md2/ogro/skins/khorne.png": "e80953b8cc5242cdf5f77f807bc5e516",
"assets/assets/models/md2/ogro/skins/gib.png": "d89d0e500ea212846d3e50770d2a2128",
"assets/assets/models/md2/ogro/skins/ogrobase.png": "5a8bd067d91de2b655f41622a41f40e2",
"assets/assets/models/md2/ogro/skins/weapon.jpg": "9f406e2f9c923aaab0ed6dd3bf80cae8",
"assets/assets/models/md2/ogro/skins/igdosh.png": "447522082d8cd36ed39e4c5381589fb7",
"assets/assets/models/md2/ogro/skins/ctf_r.png": "158a8e39de4bbb404623979f4e080a92",
"assets/assets/models/md2/ogro/skins/sharokh.png": "23ccfd4ff7ed7323ff63683c5e883965",
"assets/assets/models/md2/ogro/skins/nabogro.png": "509c81511b83292c6a68ab66b12001c6",
"assets/assets/models/md2/ogro/skins/arboshak.png": "5c3e848e85ed8af7d5ba05076aba4762",
"assets/assets/models/md2/ogro/skins/ctf_b.png": "998a645d79ffaa6f4e1832bbcc920071",
"assets/assets/models/md2/ogro/skins/grok.jpg": "cca26746e659b653391681a09957d8ee",
"assets/assets/models/md2/ogro/ogro.md2": "b06398af8e51cc14922199e366cf0e42",
"assets/assets/models/md2/ogro/Ogro.txt": "5083d329c308d9880a9209d1a32e2ae8",
"assets/assets/models/md2/ogro/weapon.md2": "ce92e2bf35c6c224675ae38c5fde5043",
"assets/assets/models/fbx/stanford-bunny.fbx": "9e1173a2339050c15e4605f2da8babc7",
"assets/assets/models/fbx/nurbs.fbx": "2dddd25b6748ea4c2dafc2662443e881",
"assets/assets/models/fbx/SambaDancing.fbx": "9a80489e046f0d3e164a6f0955a8df98",
"assets/assets/models/fbx/bunny_thickness.jpg": "07976de10799d4e445ac08371c7d222f",
"assets/assets/models/fbx/white.jpg": "374efe1a93cd762bceb5a3e998a098d6",
"assets/assets/models/xyz/helix_201.xyz": "6da4ea565af7440b3520e50e8bb276a7",
"assets/assets/models/collada/stormtrooper/Stormtrooper_D.jpg": "b275c6a9844237b204d1eaae833d080c",
"assets/assets/models/collada/stormtrooper/stormtrooper.dae": "80f6862f487dc7a5991b453259045aca",
"assets/assets/models/collada/abb_irb52_7_120.dae": "15b53128f4a04881638f21332d2c20fb",
"assets/assets/models/collada/elf/elf.dae": "4615028c9c86ad4244f6eaa85e824ac1",
"assets/assets/models/collada/elf/Face_tex_002_toObj.jpg": "3220e0abcac53b9bbc365ade52914cf8",
"assets/assets/models/collada/elf/Hair_tex_001.jpg": "750278d2b6e71a6965f1959dd90f3f2b",
"assets/assets/models/collada/elf/ce.jpg": "34c16132e09ae835238000f7545743c3",
"assets/assets/models/collada/elf/Body_tex_003.jpg": "f943682a8bc0f1a848ba16f4a81f2c8d",
"assets/assets/models/gltf/Horse.gltf": "12c160d79373c55e38ede83dee9ca3e5",
"assets/assets/models/gltf/DamagedHelmet/glTF/Default_normal.jpg": "48d9ff1bd7adf4abfa7fbe231cb016bd",
"assets/assets/models/gltf/DamagedHelmet/glTF/DamagedHelmet.gltf": "bbe003fceb4f61fa9583d303e696ee04",
"assets/assets/models/gltf/DamagedHelmet/glTF/Default_albedo.jpg": "76f93d96015a7dc91e39ac24ae8f62c1",
"assets/assets/models/gltf/DamagedHelmet/glTF/DamagedHelmet.bin": "5699fad9d84869a17865b85ec25f9fe5",
"assets/assets/models/gltf/DamagedHelmet/glTF/Default_metalRoughness.jpg": "294a81a28afbf24cc5ee6cd6aad44786",
"assets/assets/models/gltf/DamagedHelmet/glTF/Default_AO.jpg": "609356e5861cd5eee9a3af2b98bc8c30",
"assets/assets/models/gltf/DamagedHelmet/glTF/Default_emissive.jpg": "fa8c756ea48eac1b18f1e74c03b34436",
"assets/assets/models/gltf/ferrari/ferrari.gltf": "3f34ca121e41279e59d6b4266e3b73f3",
"assets/assets/models/gltf/ferrari/ferrari.bin": "b0dc60c47c24511825c55e88c33e2c44",
"assets/assets/models/gltf/ferrari/ferrari_ao.png": "68a5370615936c3a9f12afdb58b0d573",
"assets/assets/models/gltf/facecap.glb": "5e02e1ca482753f722aacbf08f4d60f4",
"assets/assets/models/gltf/Michelle.glb": "6735c9edb47dc756a225682220fa876c",
"assets/assets/models/gltf/Soldier/file2.jpg": "1491d8431ca6c3b18f31dc16d095a54b",
"assets/assets/models/gltf/Soldier/Soldier.bin": "5fe668723d4738d1e17f857ac09704bb",
"assets/assets/models/gltf/Soldier/vanguard_vanguard_diffuse_tga.jpg": "7df1892daa1a0007ea95ff9dd53adda8",
"assets/assets/models/gltf/Soldier/Soldier.gltf": "1304a98074e790d5dcc78068b31a969c",
"assets/assets/models/gltf/RobotExpressive/RobotExpressive.glb": "70610664823701a3341a6e3db0af2fa7",
"assets/assets/models/gltf/RobotExpressive/RobotExpressive.gltf": "b4c118d95e9fe6302891fce6fecc6a6d",
"assets/assets/models/gltf/RobotExpressive/README.md": "618dbef254938ad1de3e6bcf8c0750f6",
"assets/assets/models/gltf/RobotExpressive/RobotExpressive2.gltf": "f1d0d893640b1aaf8f5da74567e4f1fd",
"assets/assets/models/gltf/test/tokyo.gltf": "8fa505fb941de7db5568c852d99b8bf4",
"assets/assets/models/gltf/Parrot.gltf": "770845294750c038ea952d4c1a53687d",
"assets/assets/models/gltf/PrimaryIonDrive.glb": "28864343b68e4585081206f4db2e9c57",
"assets/assets/models/gltf/DragonAttenuation.glb": "704f73d920179213cc7e4cbfaf8699e9",
"assets/assets/models/gltf/Flower/Flower.glb": "1e4c0c0f38958b825d032f824aa46121",
"assets/assets/models/gltf/Flower/README.md": "076a78ce9d396f493092b27408c5164a",
"assets/assets/models/gltf/LeePerrySmith.gltf": "d07a7a2f1e669c065fa9d530e28fc6c8",
"assets/assets/models/gltf/flutter/ground.glb": "3c2fc9be4fe599a3f6c0f17f661abd0e",
"assets/assets/models/gltf/flutter/coin.glb": "093c68e7cdfc939606aa9df9f89758bf",
"assets/assets/models/gltf/flutter/sky_sphere.glb": "f2bd4c91196db2ab115c9ad9ed810222",
"assets/assets/models/gltf/flutter/flutter_logo.glb": "2c2af6d0c78ab9e62d814ce949a794d4",
"assets/assets/models/gltf/flutter/dash.glb": "18b547dff07c2e4c3da886b6e24b6684",
"assets/assets/models/gltf/Soldier.gltf": "f28f5e803b5fa500ed0a13ec273ec6a0",
"assets/assets/models/gltf/collision-world.glb": "2a1fe984a72270ec18c91e1b20ef2c33",
"assets/assets/models/gltf/BoomBox.glb": "bac5ec68e72a0b1b154f18652f78144f",
"assets/assets/models/gltf/ShaderBall2/ShaderBall2.bin": "551ad45f89965e334ca67180312c58ed",
"assets/assets/models/gltf/ShaderBall2/Image_0.jpg": "67aa9e6edbfdfad6afad5bdea1743cdb",
"assets/assets/models/gltf/ShaderBall2/ShaderBall2.gltf": "e51d9830215d27d9bec8489d0d773227",
"assets/assets/models/gltf/Xbot.gltf": "6d460ece6062aa71496d5488b8bb8c8c",
"assets/assets/models/gltf/AnimatedMorphSphere/glTF/AnimatedMorphSphere.bin": "89a37a235af1600ec85a6b40a0b67c31",
"assets/assets/models/gltf/AnimatedMorphSphere/glTF/AnimatedMorphSphere.gltf": "6522250402bd7cd581595b19173d356a",
"assets/assets/models/gltf/LeePerrySmith/Map-COL.jpg": "32f393329ab0f95a343adc46f8ccbd90",
"assets/assets/models/gltf/LeePerrySmith/Infinite-Level_02_Disp_NoSmoothUV-4096.jpg": "94f53d6187e9d35797d613a957f69e53",
"assets/assets/models/gltf/LeePerrySmith/LeePerrySmith_License.txt": "357c159bd32ede5bf0ab49756e47eab7",
"assets/assets/models/gltf/LeePerrySmith/LeePerrySmith.glb": "8a4938073ec6c1d0d622e2a97cf54e26",
"assets/assets/models/gltf/LeePerrySmith/Infinite-Level_02_Tangent_SmoothUV.jpg": "b6b6e4cfb4dbe19b449a03952b38f243",
"assets/assets/models/gltf/LeePerrySmith/Map-SPEC.jpg": "fa347493dcf46e4b2c4ac0c2ae70332a",
"assets/assets/models/gltf/SimpleSkinning.gltf": "2f05ada4c1527b99bcbda5c6a9df35b5",
"assets/assets/models/gltf/Dungon_Warkarma/Wall_Dark_White_metallicRoughness.webp": "d4c3476aeaaaf4e7c2f10c1d70a4a06a",
"assets/assets/models/gltf/Dungon_Warkarma/Tiles_metallicRoughness.webp": "9fef7d0f6a0fd54265f3eba11d98dca3",
"assets/assets/models/gltf/Dungon_Warkarma/Global_Wood_metallicRoughness.webp": "250660d00dd6c45bbc52695ee95bced1",
"assets/assets/models/gltf/Dungon_Warkarma/Skull_metallicRoughness.webp": "f8f0ce51131a9668cbd3e67c8c914f03",
"assets/assets/models/gltf/Dungon_Warkarma/Floor_01_metallicRoughness.webp": "02815216b5fcc1299948a7f8c191a767",
"assets/assets/models/gltf/Dungon_Warkarma/Weapon_Metal_metallicRoughness.webp": "cd7f969972742148e599372b3eb74691",
"assets/assets/models/gltf/Dungon_Warkarma/Floor_02_metallicRoughness.webp": "f54cea6284864270cb8e0270b5fced93",
"assets/assets/models/gltf/Dungon_Warkarma/dungon_warkarma.bin": "6422469d5c363771af64c26eae1d17d6",
"assets/assets/models/gltf/Dungon_Warkarma/Tile_Border_metallicRoughness.webp": "9690574d6e146c883a0a8201efcc156c",
"assets/assets/models/gltf/Dungon_Warkarma/Global_Black_metallicRoughness.webp": "532ba229458794413959987054821c9f",
"assets/assets/models/gltf/Dungon_Warkarma/Pillars_metallicRoughness.webp": "27273543d8ef26d7198264d212ca8acc",
"assets/assets/models/gltf/Dungon_Warkarma/Cloth_Red_metallicRoughness.webp": "d8a6c9cfd2d2bab47970cbd22f11bf47",
"assets/assets/models/gltf/Dungon_Warkarma/Coin_metallicRoughness.webp": "b77931be631cf22e6959ba2f7d2833f7",
"assets/assets/models/gltf/Dungon_Warkarma/Floor_Stone_metallicRoughness.webp": "c6caaa12f62f853e1ef3b6b1be2e5f8a",
"assets/assets/models/gltf/Dungon_Warkarma/Torch_Metal_metallicRoughness.webp": "2332df8867cbfecf93c5d66e49b9ca25",
"assets/assets/models/gltf/Dungon_Warkarma/dungon_warkarma.gltf": "7e17b14c76b1e158d0668d4f1bae1ee3",
"assets/assets/models/gltf/Dungon_Warkarma/Tile_Borders__0_metallicRoughness.webp": "2d6d9667b2c1bf0531eebbf09942bef4",
"assets/assets/models/gltf/Dungon_Warkarma/Stone_metallicRoughness.webp": "9e4b9ed24fb98122dbad2492b070806a",
"assets/assets/models/gltf/Dungon_Warkarma/Global_White_metallicRoughness.webp": "3952b4ba7bae86665c03c19cffdccb67",
"assets/assets/models/gltf/Dungon_Warkarma/Torch_Flame_metallicRoughness.webp": "7bfe232d208b45854b06467e1435af4b",
"assets/assets/models/gltf/Dungon_Warkarma/Wall_Dark_Blue_metallicRoughness.webp": "1292bd2c169a1baf3311139f4bb7d113",
"assets/assets/models/gltf/Dungon_Warkarma/Steps_metallicRoughness.webp": "2d6d9667b2c1bf0531eebbf09942bef4",
"assets/assets/models/gltf/Dungon_Warkarma/P_Steps_metallicRoughness.webp": "66af56b68af1ac3ffaa3de51de7a09b1",
"assets/assets/models/gltf/Dungon_Warkarma/Weapon_Wood_metallicRoughness.webp": "476f61306fdd7a975b833d4a76ce9218",
"assets/assets/models/gltf/Dungon_Warkarma/Cloth_Wood_metallicRoughness.webp": "9afd7ac82a3f987ffbba1c233af65453",
"assets/assets/models/gltf/Dungon_Warkarma/Torch_Wood_metallicRoughness.webp": "f1134892a0c6acb44524f29b14772cf0",
"assets/assets/models/gltf/Dungon_Warkarma/Global_Metal_metallicRoughness.webp": "7112f42381d4b963c96e507614243dd8",
"assets/assets/models/bvh/pirouette.bvh": "d385f473c405e3d5c6f80aef886c73e3",
"assets/assets/models/stl/ascii/pr2_head_pan.stl": "231e44c43bb688e29a9c4c5df4bf8049",
"assets/assets/models/stl/ascii/pr2_head_tilt.stl": "840fba537111ce43295a72ac4c1ff323",
"assets/assets/models/stl/ascii/slotted_disk.stl": "2d2a03f288ad36388090e12668aef4f6",
"assets/assets/models/stl/binary/colored.stl": "155ca9ba61d3a1cc3af1388e074cde9b",
"assets/assets/models/stl/binary/pr2_head_pan.stl": "f2606ef3f82bc33129228400e1551776",
"assets/assets/models/stl/binary/pr2_head_tilt.stl": "3b6e2a8913cafa831378e2c2b4ac0948",
"assets/assets/models/usdz/saeukkang.usdz": "e455ec76372fc33ae7e07dddbb49f29f",
"assets/assets/models/json/suzanne_buffergeometry.json": "cc368f5ceeb955f6337ee9bc0e2fa3f5",
"assets/assets/models/pcd/ascii/simple.pcd": "0895ca1a3280ce942e8328d608a6414f",
"assets/assets/models/pcd/binary/Zaghetto.pcd": "36329431ada97e36ef04f36e3f239e88",
"assets/assets/models/pcd/binary/Zaghetto_8bit.pcd": "5235d13f4cfccbb4a6012421833fb961",
"assets/assets/models/pcd/binary_compressed/pcl_logo.pcd": "2b1cd02822c774816ec7f3838a38a697",
"assets/assets/models/vox/menger.vox": "abc3916b090d32dbffff264313a8bd76",
"assets/assets/models/vox/monu10.vox": "63b4f3140ad13f8bc588548526516949",
"assets/assets/models/gcode/benchy.gcode": "d53c9ba54f1e104b9fab92383a7e08de",
"assets/assets/sounds/ping_pong.mp3": "a7cb42dbae6973734cfcdaa0755bc8a1",
"assets/assets/sounds/376737_Skullbeatz___Bad_Cat_Maste.mp3": "0e85ec7b75e01073037a934aa1a297b4",
"assets/assets/sounds/Project_Utopia.mp3": "56d3da5f4fa4b6979e4c09eb91f27308",
"assets/assets/sounds/358232_j_s_song.mp3": "3ac834b4bde0ff5861f146d6b7882144",
"assets/assets/sounds/readme.txt": "256bb6d25d76c358dc1ea55606e049bf",
"assets/assets/pingfang.ttf": "67ee533e4da77ffdef0fc1df1fa7935f",
"assets/assets/helvetiker_bold.typeface.json": "fa14b90d7bb6b54b02a5110787aef475",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
