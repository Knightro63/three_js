import 'package:three_js_math/three_js_math.dart';

class SpriteTexture{
  SpriteTexture({
    Vector2? offset,
    Vector2? repeat
  }){
    this.offset = offset ?? Vector2();
    this.repeat = repeat ?? Vector2();
  }

  late Vector2 offset;
  late Vector2 repeat;
}

class SpriteAnimation{
  SpriteAnimation({
    this.numberOfTiles = 0,
    this.startFrame = 0,
    this.repeat = -1,
    this.fps = 60,
    this.duration = -1,
    this.tilesHorizontal = -1,
    this.tilesVertical = -1,
    SpriteTexture? texture
  }){
    currentTile = startFrame;
    this.texture = texture ?? SpriteTexture();
  }

  int fps;
  int duration;
  int repeat;
  int startFrame;
  int numberOfTiles;
  int looped = 0;
  late int currentTile;
  late SpriteTexture texture;
  int tilesHorizontal;
  int tilesVertical;
}

class SpriteAnimator {
  List<SpriteAnimation> animations = [];

  // Add a new animation
  SpriteAnimation add(SpriteAnimation options) {
    options.texture.repeat.setValues(1 / options.tilesHorizontal, 1 / options.tilesVertical);
    final SpriteAnimation animation = options;
    animation.numberOfTiles = options.tilesHorizontal * options.tilesVertical;
    animation.currentTile = animation.startFrame;
    animation.looped = 0;

    animations.add(animation);

    return animation;
  }

  // Release this sprite from our tracking and upating
  void free(SpriteAnimation animation) {
    animations.removeAt(animations.indexOf(animation));
    //animation.onEnd && animation.onEnd();
  }

  // Update all sprites we know about
  void update(int delta) {
    int currentColumn, currentRow;
    List<SpriteAnimation> complete = [];

    for (int x = 0; x < animations.length;x++) {
      final animation = animations[x];
      animation.duration += delta;

      // Have we gone longer than the duration of this tile? Show the
      // next one
      if (animation.duration > 1 / animation.fps) {
        // Advance this animation to the next tile
        animation.currentTile =
            (animation.currentTile + 1) % animation.numberOfTiles;

        // Calcualte the new column and row
        currentColumn = animation.currentTile % animation.tilesHorizontal;
        currentRow = (animation.currentTile / animation.tilesHorizontal).floor();

        // Calculate the texture offset. The y was found through trial
        // and error and I have no idea why it works
        animation.texture.offset.x = currentColumn / animation.tilesHorizontal;
        animation.texture.offset.y = 1 -
            (1 / animation.tilesHorizontal) -
            (currentRow / animation.tilesVertical);

        animation.duration = 0;

        // If we're on the last frame (currentTile is 0 indexed), keep
        // track of this one for later
        if (animation.currentTile == animation.numberOfTiles - 1) {
          animation.looped++;
          complete.add(animation);
        }
      }
    }

    // Go over all completed animations. If we exceed our looping quota,
    // free it
    if (complete.isNotEmpty) {
      for (int x = 0; x < complete.length;x++) {
        final animation = complete[x];
        if (animation.looped >= animation.repeat) {
          free(animation);
        }
      }
    }
  }
}
